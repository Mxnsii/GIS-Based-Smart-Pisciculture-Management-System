import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/weather_service.dart';

class WeatherWidget extends StatefulWidget {
  const WeatherWidget({super.key});

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  late Future<Map<String, dynamic>> _weatherFuture;
  final WeatherService _weatherService = WeatherService();

  @override
  void initState() {
    super.initState();
    _weatherFuture = _weatherService.fetchWeather('Panjim, Goa');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _weatherFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingValues();
        } else if (snapshot.hasError) {
          return _buildErrorView();
        } else if (snapshot.hasData) {
          final data = snapshot.data!;
          final temp = (data['main']['temp'] as num).round();
          final humidity = data['main']['humidity'];
          final windSpeed = data['wind']['speed'];
          final condition = data['weather'][0]['main'];
          final location = data['name'];

          return _buildWeatherCard(
            location: location,
            temperature: temp,
            condition: condition,
            humidity: humidity,
            windSpeed: windSpeed.toDouble(),
          );
        }
        return _buildErrorView();
      },
    );
  }

  Widget _buildLoadingValues() {
    return Container(
      height: 120, // Match Approx Height
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade300,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  Widget _buildErrorView() {
    // Fallback to mock data if error (to keep UI looking good during dev without API key)
    return _buildWeatherCard(
      location: "Panjim, Goa (Offline)",
      temperature: 28,
      condition: "Sunny",
      humidity: 65,
      windSpeed: 12.5,
      isError: true,
    );
  }

  Widget _buildWeatherCard({
    required String location,
    required int temperature,
    required String condition,
    required int humidity,
    required double windSpeed,
    bool isError = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isError 
            ? [Colors.grey.shade400, Colors.grey.shade600] 
            : [Colors.blue.shade400, Colors.blue.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Location & Date
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    location,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('EEE, MMM d').format(DateTime.now()),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
            ],
          ),

          // Center: Temperature & Icon
          Row(
            children: [
              Icon(_getWeatherIcon(condition), color: Colors.yellow, size: 40),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$temperature°C',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    condition,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Right: Details (Humidity/Wind)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildDetailItem(Icons.water_drop, '$humidity%', 'Humidity'),
              const SizedBox(height: 4),
              _buildDetailItem(Icons.air, '${windSpeed}km/h', 'Wind'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 14),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
  
  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clouds':
      case 'rain':
      case 'drizzle':
      case 'thunderstorm':
        return Icons.cloud;
      case 'clear':
        return Icons.wb_sunny;
      default:
        return Icons.wb_cloudy_outlined;
    }
  }
}
