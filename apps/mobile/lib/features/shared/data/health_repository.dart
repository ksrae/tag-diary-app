
import 'dart:io';
import 'package:health/health.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/features/shared/data/models/health_info.dart';




class HealthRepository {
  final Health _health = Health();
  bool _isInitialized = false;
  static const String _permissionRequestedKey = 'health_permission_requested';

  /// Initialize health permissions on app startup (only requests once)
  Future<void> initWithPermission() async {
    if (_isInitialized) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // FEATURE CHECK: Only proceed if feature is ENABLED by user
      if (prefs.getBool('feature_health_enabled') != true) {
        _isInitialized = true;
        return;
      }
      
      final alreadyRequested = prefs.getBool(_permissionRequestedKey) ?? false;
      
      final types = Platform.isIOS
          ? [
              HealthDataType.STEPS,
              HealthDataType.ACTIVE_ENERGY_BURNED,
              HealthDataType.EXERCISE_TIME,
            ]
          : [
              HealthDataType.STEPS,
              HealthDataType.ACTIVE_ENERGY_BURNED,
              HealthDataType.MOVE_MINUTES,
            ];

      // Check if we already have permission
      final hasPermissions = await _health.hasPermissions(types);
      
      // Only request permission if we haven't asked before AND don't have permission
      if (hasPermissions != true && !alreadyRequested) {
        await _health.requestAuthorization(types);
        // Mark that we've requested permission (don't ask again on next launch)
        await prefs.setBool(_permissionRequestedKey, true);
      }
    } catch (e) {
      // Ignore errors during init
    }
    
    _isInitialized = true;
  }

  Future<HealthInfo> getTodayHealth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // FEATURE CHECK: Only proceed if feature is ENABLED by user
      if (prefs.getBool('feature_health_enabled') != true) {
        return HealthInfo();
      }

      // Platform-specific data types
      final types = Platform.isIOS
          ? [
              HealthDataType.STEPS,
              HealthDataType.ACTIVE_ENERGY_BURNED,
              HealthDataType.EXERCISE_TIME,
            ]
          : [
              HealthDataType.STEPS,
              HealthDataType.ACTIVE_ENERGY_BURNED,
              // Android doesn't support EXERCISE_TIME, use MOVE_MINUTES instead
              HealthDataType.MOVE_MINUTES,
            ];

      // Check if we have permission WITHOUT requesting (no login popup)
      final hasPermissions = await _health.hasPermissions(types);
      
      // If not authorized, return empty - user can tap to open health app manually
      if (hasPermissions != true) {
        return HealthInfo();
      }

      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);

      final healthData = await _health.getHealthDataFromTypes(
        types: types,
        startTime: midnight,
        endTime: now,
      );

      int steps = 0;
      int minutes = 0;
      double calories = 0.0;

      for (var data in healthData) {
        if (data.type == HealthDataType.STEPS) {
          steps += (data.value as num).toInt();
        } else if (data.type == HealthDataType.EXERCISE_TIME ||
                   data.type == HealthDataType.MOVE_MINUTES) {
          minutes += (data.value as num).toInt();
        } else if (data.type == HealthDataType.ACTIVE_ENERGY_BURNED) {
          calories += (data.value as num).toDouble();
        }
      }

      return HealthInfo(
        steps: steps,
        activeMinutes: minutes,
        calories: calories,
      );
    } catch (e) {
      // Return empty health info on any error to prevent app crash
      return HealthInfo();
    }
  }
}

final healthRepositoryProvider = Provider<HealthRepository>((ref) {
  return HealthRepository();
});

final todayHealthProvider = FutureProvider<HealthInfo>((ref) async {
  return ref.read(healthRepositoryProvider).getTodayHealth();
});
