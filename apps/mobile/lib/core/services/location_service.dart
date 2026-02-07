
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';



class LocationService {
  Position? _currentPosition;
  bool _isInitialized = false;

  Position? get currentPosition => _currentPosition;

  Future<void> init() async {
    if (_isInitialized) return;
    
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.whileInUse || 
        permission == LocationPermission.always) {
      try {
        _currentPosition = await Geolocator.getCurrentPosition(
          timeLimit: const Duration(seconds: 5),
        );
      } catch (e) {
        // Limit fetching or handle error silently
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
