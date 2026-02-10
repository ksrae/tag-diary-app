

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:mobile/core/services/location_service.dart';
import 'package:mobile/features/diary/data/models/diary.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WeatherService {
  final Ref _ref;
  final Dio _dio = Dio();

  WeatherService(this._ref);

  Future<Weather> getCurrentWeather() async {
    // 1. Try GPS Location
    final location = await _ref.read(currentLocationProvider.future);
    
    if (location != null) {
      return await _fetchWeatherByCoordinates(location.latitude, location.longitude);
    }

    // 2. Try User Region
    final prefs = await SharedPreferences.getInstance();
    final region = prefs.getString('weather_region');

    if (region != null && region.isNotEmpty) {
      return await _fetchWeatherByCity(region);
    }

    // 3. Default to Seoul
    return await _fetchWeatherByCity('Seoul');
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
        
        return Weather(
          temp: (current['temperature'] as num).toDouble(),
          condition: _weatherCodeToCondition(current['weathercode'] as int),
          icon: 'gps',
        );
      }
    } catch (e) {
      // API error - return fallback
    }
    
    // Fallback
    return Weather(temp: 0, condition: 'unknown', icon: 'error');
  }

  /// Fetch weather by city name (geocode first, then get weather)
  Future<Weather> _fetchWeatherByCity(String city) async {
    try {
      // First, geocode the city name
      final geocodeResponse = await _dio.get(
        'https://geocoding-api.open-meteo.com/v1/search',
        queryParameters: {
          'name': city,
          'count': 1,
          'language': 'ko',
        },
      );
      
      if (geocodeResponse.statusCode == 200 && geocodeResponse.data['results'] != null) {
        final results = geocodeResponse.data['results'] as List;
        if (results.isNotEmpty) {
          final lat = results[0]['latitude'];
          final lng = results[0]['longitude'];
          return await _fetchWeatherByCoordinates(lat, lng);
        }
      }
    } catch (e) {
      // Geocoding error
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
  // Watch location to auto-refresh weather when location changes
  ref.watch(currentLocationProvider); 
  return service.getCurrentWeather();
});

/// Provider for current weather region name
final weatherRegionProvider = FutureProvider<String>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final region = prefs.getString('weather_region');
  
  // Return saved region, or default to Seoul if not set
  if (region != null && region.isNotEmpty) {
    return region;
  }
  
  return 'Seoul';
});
