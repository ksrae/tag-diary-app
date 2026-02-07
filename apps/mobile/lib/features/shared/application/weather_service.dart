
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/services/location_service.dart';
import 'package:mobile/features/diary/data/models/diary.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WeatherService {
  final Ref _ref;

  WeatherService(this._ref);

  Future<Weather> getCurrentWeather() async {
    // 1. Try GPS Location
    final location = await _ref.read(currentLocationProvider.future);
    
    if (location != null) {
      // Mock API call for coordinates
      // In real app: call WeatherRepository.getWeather(lat, lng)
      return Weather(
        temp: 18.5, 
        condition: 'sunny',
        icon: 'gps', // data source marker
      );
    }

    // 2. Try User Region
    final prefs = await SharedPreferences.getInstance();
    final region = prefs.getString('weather_region');

    if (region != null && region.isNotEmpty) {
      return _mockWeatherForRegion(region);
    }

    // 3. Default to Seoul
    return _mockWeatherForRegion('Seoul');
  }

  Weather _mockWeatherForRegion(String region) {
    double temp = 15;
    final r = region.toLowerCase();
    
    if (r.contains('seoul')) temp = 10;
    else if (r.contains('tokyo')) temp = 12;
    else if (r.contains('london')) temp = 8;
    else if (r.contains('new york')) temp = 5;
    
    return Weather(
      temp: temp,
      condition: 'cloudy',
      icon: 'city',
    );
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
  if (region != null && region.isNotEmpty) {
    return region;
  }
  
  // Check if using GPS
  final location = await ref.read(currentLocationProvider.future);
  if (location != null) {
    return 'GPS';
  }
  
  return 'Seoul';
});

