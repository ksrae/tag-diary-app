

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:mobile/core/services/location_service.dart';
import 'package:mobile/features/diary/data/models/diary.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WeatherService {
  final Ref _ref;
  final Dio _dio = Dio();
  static const String _cachedWeatherKey = 'cached_weather';
  static const String _cachedWeatherTimeKey = 'cached_weather_time';

  WeatherService(this._ref);

  /// Get current weather. Uses saved location coordinates.
  /// Returns cached weather instantly if available, then caller can refresh.
  Future<Weather> getCurrentWeather() async {
    // 1. Try saved location
    final savedLocation = await _ref.read(savedLocationProvider.future);
    if (savedLocation != null) {
      return await _fetchWeatherByCoordinates(
        savedLocation.latitude,
        savedLocation.longitude,
      );
    }

    // 2. No saved location → return unknown
    return Weather(temp: 0, condition: 'unknown', icon: 'error');
  }

  /// Get cached weather from SharedPreferences (instant, no API call)
  Future<Weather?> getCachedWeather() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_cachedWeatherKey);
    if (json == null) return null;
    try {
      return Weather.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Cache weather result to SharedPreferences
  Future<void> _cacheWeather(Weather weather) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cachedWeatherKey, jsonEncode(weather.toJson()));
    await prefs.setString(
      _cachedWeatherTimeKey,
      DateTime.now().toIso8601String(),
    );
  }

  /// Fetch weather from Open-Meteo API using coordinates
  Future<Weather> _fetchWeatherByCoordinates(double lat, double lng) async {
    try {
      final response = await _dio.get(
        'https://api.open-meteo.com/v1/forecast',
        queryParameters: {
          'latitude': lat,
          'longitude': lng,
          'current_weather': true,
        },
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        final current = data['current_weather'];
        
        final weather = Weather(
          temp: (current['temperature'] as num).toDouble(),
          condition: _weatherCodeToCondition(current['weathercode'] as int),
          icon: 'gps',
        );
        // Cache the result
        await _cacheWeather(weather);
        return weather;
      }
    } catch (e) {
      // API error - try cache fallback
      final cached = await getCachedWeather();
      if (cached != null) return cached;
    }
    
    // Fallback
    return Weather(temp: 0, condition: 'unknown', icon: 'error');
  }

  /// Convert Open-Meteo weather code to condition string
  String _weatherCodeToCondition(int code) {
    if (code == 0) return 'sunny';
    if (code <= 3) return 'cloudy';
    if (code <= 48) return 'foggy';
    if (code <= 57) return 'drizzle';
    if (code <= 67) return 'rainy';
    if (code <= 77) return 'snowy';
    if (code <= 82) return 'rainy';
    if (code <= 86) return 'snowy';
    if (code >= 95) return 'stormy';
    return 'cloudy';
  }
}

final weatherServiceProvider = Provider<WeatherService>((ref) {
  return WeatherService(ref);
});

final currentWeatherProvider = FutureProvider<Weather>((ref) async {
  final service = ref.watch(weatherServiceProvider);
  // Watch saved location: when it changes, re-fetch weather
  ref.watch(savedLocationProvider);
  return service.getCurrentWeather();
});
