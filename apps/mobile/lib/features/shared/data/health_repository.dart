
import 'dart:io';
import 'package:health/health.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/shared/data/models/health_info.dart';




class HealthRepository {
  final Health _health = Health();

  Future<HealthInfo> getTodayHealth() async {
    try {
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
