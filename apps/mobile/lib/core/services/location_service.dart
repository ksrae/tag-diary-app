import 'dart:convert';
import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Saved location data stored in SharedPreferences
class SavedLocation {
  final String city;
  final double latitude;
  final double longitude;

  const SavedLocation({
    required this.city,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() => {
    'city': city,
    'latitude': latitude,
    'longitude': longitude,
  };

  factory SavedLocation.fromJson(Map<String, dynamic> json) => SavedLocation(
    city: json['city'] as String,
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
  );
}

class LocationService {
  static const String _savedLocationKey = 'saved_location';
  final Dio _dio = Dio();

  /// Get saved location from SharedPreferences (instant, no GPS)
  Future<SavedLocation?> getSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_savedLocationKey);
    if (json == null) return null;
    try {
      return SavedLocation.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Save location to SharedPreferences
  Future<void> saveLocation(SavedLocation location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_savedLocationKey, jsonEncode(location.toJson()));
  }

  /// Reverse geocode coordinates to a city name using Open-Meteo Geocoding API.
  /// This is more reliable than the native geocoding package which often fails
  /// to return locality on certain devices/regions.
  Future<String> reverseGeocode(double latitude, double longitude) async {
    try {
      // Use Open-Meteo geocoding search with nearby coordinates
      // Open-Meteo doesn't have a true reverse geocoding endpoint,
      // so we use the Nominatim API (OpenStreetMap) for reverse geocoding.
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'lat': latitude,
          'lon': longitude,
          'format': 'json',
          'accept-language': 'ko',
          'zoom': 10, // city level
        },
        options: Options(
          headers: {
            'User-Agent': 'TagDiaryApp/1.0',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final address = data['address'] as Map<String, dynamic>?;

        if (address != null) {
          // Try city → town → county → state in order of specificity
          final city = address['city'] as String? ??
              address['town'] as String? ??
              address['village'] as String? ??
              address['county'] as String? ??
              address['state'] as String?;

          developer.log(
            'Nominatim reverse geocode - address: $address, resolved city: $city',
            name: 'LocationService',
          );

          if (city != null && city.isNotEmpty) {
            return city;
          }
        }

        // Fallback: use display_name's first part
        final displayName = data['display_name'] as String?;
        if (displayName != null && displayName.isNotEmpty) {
          final firstPart = displayName.split(',').first.trim();
          if (firstPart.isNotEmpty) return firstPart;
        }
      }
    } catch (e) {
      developer.log('Reverse geocoding failed: $e', name: 'LocationService');
    }
    return '';
  }

  /// Update location from GPS. Only call when user explicitly taps "현재 위치" button.
  /// Returns the saved location on success, null on failure.
  Future<SavedLocation?> updateLocationFromGPS() async {
    // Check / request permission
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      return null;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 5),
      );

      // Use Nominatim (OpenStreetMap) reverse geocoding for reliable city names
      String city = await reverseGeocode(position.latitude, position.longitude);
      if (city.isEmpty) {
        city = '현재 위치';
      }

      developer.log(
        'GPS position: ${position.latitude}, ${position.longitude} → city: $city',
        name: 'LocationService',
      );

      final saved = SavedLocation(
        city: city,
        latitude: position.latitude,
        longitude: position.longitude,
      );
      await saveLocation(saved);
      return saved;
    } catch (e) {
      developer.log('GPS location failed: $e', name: 'LocationService');
      return null;
    }
  }

  /// Save a manually selected location (from geocoding search)
  Future<SavedLocation> saveManualLocation(String city, double lat, double lng) async {
    final saved = SavedLocation(city: city, latitude: lat, longitude: lng);
    await saveLocation(saved);
    return saved;
  }

  /// Clear saved location
  Future<void> clearLocation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_savedLocationKey);
  }
}

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

/// Instantly loads saved location from SharedPreferences (no GPS call)
final savedLocationProvider = FutureProvider<SavedLocation?>((ref) async {
  final service = ref.read(locationServiceProvider);
  return service.getSavedLocation();
});
