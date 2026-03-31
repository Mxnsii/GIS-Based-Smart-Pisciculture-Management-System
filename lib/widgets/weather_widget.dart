import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:ui';
import '../services/weather_service.dart';

class WeatherWidget extends StatefulWidget {
  const WeatherWidget({super.key});

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> with SingleTickerProviderStateMixin {
  late Future<Map<String, dynamic>> _weatherFuture;
  final WeatherService _weatherService = WeatherService();
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _weatherFuture = _initWeather();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _initWeather() async {
    try {
      // Direct Sensing Attempt
      Position position = await _determinePosition();
      return _weatherService.fetchWeatherData(
        lat: position.latitude, 
        lng: position.longitude,
      );
    } catch (e) {
      // Explicitly mark as sensing failure but fetch Panjim as a secondary background fallback
      final fallback = await _weatherService.fetchWeatherData(lat: 15.4909, lng: 73.8278);
      return {
        ...fallback,
        'location': 'ENABLE GPS FOR LIVE UPDATES',
        'isGPSDenied': true,
      };
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('Location services disabled.');

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return Future.error('Permission denied.');
    }
    
    if (permission == LocationPermission.deniedForever) return Future.error('Permissions permanently denied.');

    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _weatherFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show skeleton/placeholder instead of loading screen
          return _buildPremiumWeatherCard({
            'location': 'Sensing Location...',
            'temp': 0,
            'condition': 'Loading',
            'humidity': 0,
            'wind_speed': 0,
            'wave_height': 0,
            'isLoading': true,
          });
        } else if (snapshot.hasError) {
          return _buildErrorView();
        } else if (snapshot.hasData) {
          final data = snapshot.data!;
          return _buildPremiumWeatherCard(data);
        }
        return _buildErrorView();
      },
    );
  }

  Widget _buildErrorView() {
    return _buildPremiumWeatherCard({
      'location': "Panjim, Goa (Offline)",
      'temp': 28,
      'condition': "Sunny",
      'humidity': 65,
      'wind_speed': 12.5,
      'wave_height': 0.8,
      'isError': true,
    });
  }

  Widget _buildPremiumWeatherCard(Map<String, dynamic> data) {
    final bool isError = data['isError'] ?? false;
    final bool isLoading = data['isLoading'] ?? false;
    final int temp = (data['temp'] as num).round();
    final int humidity = data['humidity'];
    final double windSpeed = (data['wind_speed'] as num).toDouble();
    final double waveHeight = (data['wave_height'] as num).toDouble();
    final String condition = data['condition'];
    final String location = data['location'];

    // Industry Risk Score Logic
    final double riskScore = (windSpeed * 0.6) + (waveHeight * 20);
    
    Color riskColor;
    String riskStatus;
    String advisory;
    IconData riskIcon;

    if (isLoading) {
      riskColor = Colors.white24;
      riskStatus = 'ACQUIRING GPS...';
      advisory = '🛰️ DIRECT SENSING ACTIVATED';
      riskIcon = Icons.gps_fixed;
    } else if (riskScore > 50) {
      riskColor = Colors.redAccent;
      riskStatus = 'DANGER';
      advisory = '❌ AVOID FISHING - High Sea Risk';
      riskIcon = Icons.gavel_rounded;
    } else if (riskScore >= 25) {
      riskColor = Colors.orangeAccent;
      riskStatus = 'MODERATE';
      advisory = '⚠️ PROCEED WITH CAUTION';
      riskIcon = Icons.warning_rounded;
    } else {
      riskColor = Colors.greenAccent;
      riskStatus = 'SAFE';
      advisory = '✅ IDEAL FOR FISHING';
      riskIcon = Icons.check_circle_rounded;
    }

    return Container(
      // Remove fixed height to fix overflow
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Background Gradient
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isError || isLoading 
                    ? [Colors.blue.shade900, Colors.blue.shade700]
                    : [Colors.blue.shade800, Colors.blue.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min, // Allow content to determine size
                children: [
                  // TOP ROW: Location & Metrics
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(isLoading ? Icons.gps_fixed : Icons.location_on, color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    location.toUpperCase(),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 0.5),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
                              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(_getWeatherIcon(condition), color: Colors.yellowAccent, size: 48),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isLoading ? '--' : '$temp°C',
                                      style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      isLoading ? 'SENSING...' : condition.toUpperCase(),
                                      style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Right Hand Stats
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                           IconButton(
                             icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
                             onPressed: () {
                               setState(() {
                                 _weatherFuture = _initWeather();
                               });
                             },
                             tooltip: 'Re-sense Location',
                           ),
                           _buildMiniStat(Icons.water_drop, isLoading ? '--' : '$humidity%', 'HUMIDITY'),
                           const SizedBox(height: 12),
                           _buildMiniStat(Icons.air, isLoading ? '--' : '${windSpeed.toStringAsFixed(1)} km/h', 'WIND'),
                           const SizedBox(height: 12),
                           _buildMiniStat(Icons.waves, isLoading ? '--' : '${waveHeight.toStringAsFixed(1)} m', 'WAVES'),
                        ],
                       ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // BOTTOM SECTION: Risk Score & Advisory
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'MARITIME RISK INDEX',
                            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                          ),
                          Flexible(
                            child: Text(
                              advisory,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Stack(
                        children: [
                          Container(
                            height: 6,
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(3)),
                          ),
                          FractionallySizedBox(
                            widthFactor: isLoading ? 0.3 : (riskScore / 100).clamp(0.0, 1.0),
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: riskColor,
                                borderRadius: BorderRadius.circular(3),
                                boxShadow: [
                                  if (!isLoading) BoxShadow(color: riskColor.withOpacity(0.5), blurRadius: 4, spreadRadius: 1)
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white70, size: 12),
            const SizedBox(width: 4),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 8, fontWeight: FontWeight.w900)),
      ],
    );
  }

  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear': return Icons.wb_sunny;
      case 'partly cloudy': return Icons.wb_cloudy;
      case 'clouds': return Icons.cloud;
      case 'rain': return Icons.beach_access;
      case 'thunderstorm': return Icons.thunderstorm;
      default: return Icons.wb_cloudy_outlined;
    }
  }
}
