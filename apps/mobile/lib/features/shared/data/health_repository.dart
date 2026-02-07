
import 'dart:io';
import 'package:health/health.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/shared/data/models/health_info.dart';




class HealthRepository {
  final Health _health = Health();

  Future<HealthInfo> getTodayHealth() async {
    if (Platform.isIOS) {
      // Basic check for simulator or permissions
    }

    try {
      final types = [
        HealthDataType.STEPS,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.EXERCISE_TIME,
      ];

      final requested = await _health.requestAuthorization(types);
      if (!requested) return HealthInfo();

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
        } else if (data.type == HealthDataType.EXERCISE_TIME) {
           minutes += (data.value as num).toInt();
        } else if (data.type == HealthDataType.ACTIVE_ENERGY_BURNED) {
           calories += (data.value as num).toDouble();
        }
      }

      // If exercise time is 0 but we have steps, estimate? No, keep raw.
      
      return HealthInfo(
        steps: steps,
        activeMinutes: minutes,
        calories: calories,
      );

    } catch (e) {
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
