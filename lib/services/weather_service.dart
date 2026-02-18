import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  // OpenMeteo API (No Key Required)
  static const String baseUrl = 'https://api.open-meteo.com/v1/forecast';

  Future<Map<String, dynamic>> fetchWeather(String city) async {
    // Note: City argument is currently unused as we default to Panjim coordinates for MVP
    // Panjim Coordinates: 15.4909° N, 73.8278° E
    const double lat = 15.4909;
    const double lng = 73.8278;
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?latitude=$lat&longitude=$lng&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m&wind_speed_unit=kmh'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final current = data['current'];
        
        // Map OpenMeteo response to OpenWeatherMap structure used by Widget
        return {
          'name': 'Panjim, Goa',
          'main': {
            'temp': current['temperature_2m'],
            'humidity': current['relative_humidity_2m'],
          },
          'wind': {
            'speed': current['wind_speed_10m'],
          },
          'weather': [
            {
              'main': _mapWmoCodeToCondition(current['weather_code']),
            }
          ]
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
    if (code >= 1 && code <= 3) return 'Clouds';
    if (code >= 45 && code <= 48) return 'Fog';
    if (code >= 51 && code <= 55) return 'Drizzle';
    if (code >= 61 && code <= 67) return 'Rain';
    if (code >= 80 && code <= 82) return 'Showers';
    if (code >= 95 && code <= 99) return 'Thunderstorm';
    return 'Clear';
  }
}
