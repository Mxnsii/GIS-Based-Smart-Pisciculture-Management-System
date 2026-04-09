import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  // OpenMeteo APIs (No Key Required)
  static const String weatherBaseUrl = 'https://api.open-meteo.com/v1/forecast';
  static const String marineBaseUrl = 'https://marine-api.open-meteo.com/v1/marine';
  static const String geocodeBaseUrl = 'https://nominatim.openstreetmap.org/reverse';

  Future<Map<String, dynamic>> fetchWeatherData({required double lat, required double lng}) async {
    try {
      // 1. Fetch General Weather & Wind
      final weatherResponse = await http.get(
        Uri.parse('$weatherBaseUrl?latitude=$lat&longitude=$lng&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m&wind_speed_unit=kmh'),
      );

      // 2. Fetch Marine Data (Wave Height)
      final marineResponse = await http.get(
        Uri.parse('$marineBaseUrl?latitude=$lat&longitude=$lng&current=wave_height'),
      );

      // 3. Fetch Location Name (Reverse Geocoding)
      String locationName = 'Unknown Location';
      try {
        final geoResponse = await http.get(
          Uri.parse('$geocodeBaseUrl?lat=$lat&lon=$lng&format=json'),
          headers: {'User-Agent': 'AquaApp/1.0'}, // Required for Nominatim
        );
        if (geoResponse.statusCode == 200) {
          final geoData = json.decode(geoResponse.body);
          final address = geoData['address'];
          String primaryLocation = address['city'] ?? address['town'] ?? address['county'] ?? address['state'] ?? 'Coastal Zone';
          String state = address['state'] ?? '';
          
          if (state.isNotEmpty && !primaryLocation.contains(state)) {
            locationName = '$primaryLocation, $state';
          } else {
            locationName = primaryLocation;
          }
        }
      } catch (e) {
        locationName = 'GPS Zone';
      }

      if (weatherResponse.statusCode == 200) {
        final weatherData = json.decode(weatherResponse.body);
        final current = weatherData['current'];
        
        double waveHeight = 0.5; // Default fallback
        if (marineResponse.statusCode == 200) {
          final marineData = json.decode(marineResponse.body);
          waveHeight = marineData['current']['wave_height'] ?? 0.5;
        }

        return {
          'location': locationName,
          'temp': current['temperature_2m'],
          'humidity': current['relative_humidity_2m'],
          'wind_speed': current['wind_speed_10m'],
          'wave_height': waveHeight,
          'condition': _mapWmoCodeToCondition(current['weather_code']),
          'weather_code': current['weather_code'],
        };
      } else {
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      throw Exception('Failed to fetch weather: $e');
    }
  }

  String _mapWmoCodeToCondition(int code) {
    if (code == 0) return 'Clear';
    if (code >= 1 && code <= 3) return 'Partly Cloudy';
    if (code >= 45 && code <= 48) return 'Fog';
    if (code >= 51 && code <= 55) return 'Drizzle';
    if (code >= 61 && code <= 67) return 'Rain';
    if (code >= 80 && code <= 82) return 'Showers';
    if (code >= 95 && code <= 99) return 'Thunderstorm';
    return 'Clear';
  }
}
