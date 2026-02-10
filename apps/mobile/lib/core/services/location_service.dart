
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';



class LocationService {
  Position? _currentPosition;
  String? _currentCity;
  bool _isInitialized = false;

  Position? get currentPosition => _currentPosition;
  String? get currentCity => _currentCity;

  static const String _permissionRequestedKey = 'location_permission_requested';

  Future<void> init() async {
    if (_isInitialized) return;
    
    final prefs = await SharedPreferences.getInstance();
    
    // FEATURE CHECK: Only proceed if feature is ENABLED by user
    if (prefs.getBool('feature_location_enabled') != true) {
      _isInitialized = true;
      return;
    }
    
    final alreadyRequested = prefs.getBool(_permissionRequestedKey) ?? false;
    
    var permission = await Geolocator.checkPermission();
    
    // Only request permission if we haven't asked before AND permission is denied
    if (permission == LocationPermission.denied && !alreadyRequested) {
      permission = await Geolocator.requestPermission();
      // Mark that we've requested permission (don't ask again on next launch)
      await prefs.setBool(_permissionRequestedKey, true);
    }
    
    // If permanently denied or still denied, skip
    if (permission == LocationPermission.deniedForever || 
        permission == LocationPermission.denied) {
      _isInitialized = true;
      return;
    }
    
    // If permission granted, get current position with LOW accuracy (city-level only)
    if (permission == LocationPermission.whileInUse || 
        permission == LocationPermission.always) {
      try {
        _currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low, // City-level, no precise location popup
          timeLimit: const Duration(seconds: 5),
        );
        
        // Get city name via reverse geocoding and save to weather_region
        if (_currentPosition != null) {
          try {
            final placemarks = await placemarkFromCoordinates(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
            );
            if (placemarks.isNotEmpty) {
              final place = placemarks.first;
              // Get city name (locality > subAdministrativeArea > administrativeArea)
              _currentCity = place.locality ?? 
                             place.subAdministrativeArea ?? 
                             place.administrativeArea ?? 
                             '현재 위치';
              // Save city name to weather_region
              await prefs.setString('weather_region', _currentCity!);
            }
          } catch (e) {
            // Geocoding failed, use default
            _currentCity = '현재 위치';
            await prefs.setString('weather_region', _currentCity!);
          }
        }
      } catch (e) {
        // Timeout or error - continue silently
      }
    }
    _isInitialized = true;
  }

  Future<bool> requestPermission() async {
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.whileInUse || 
        permission == LocationPermission.always) {
      await init(); // Try fetching
      return true;
    }
    return false;
  }
}

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final currentLocationProvider = FutureProvider<Position?>((ref) async {
  final service = ref.read(locationServiceProvider);
  if (service.currentPosition == null) {
    await service.init();
  }
  return service.currentPosition;
});
