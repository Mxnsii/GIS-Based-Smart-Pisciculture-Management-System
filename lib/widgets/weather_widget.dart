import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:ui';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/weather_service.dart';
import 'location_picker_dialog.dart';
import 'package:latlong2/latlong.dart';

class WeatherWidget extends StatefulWidget {
  const WeatherWidget({super.key});

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _weatherData;
  bool _isSensing = true;
  String _sensingMessage = "Sensing Location...";
  final WeatherService _weatherService = WeatherService();
  late AnimationController _pulseController;
  StreamSubscription<Position>? _positionStream;

  static const String _cacheKey = 'cached_weather_data';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _initRealTimeSensing();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _initRealTimeSensing() async {
    // 1. Instant Load from Cache
    await _loadFromCache();

    // 2. Clear previous location to force a fresh sense if cache is old
    if (mounted) setState(() => _isSensing = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _sensingMessage = "Please Enable GPS";
          _isSensing = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _sensingMessage = "GPS Permission Denied";
            _isSensing = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _sensingMessage = "Enable GPS in Settings";
          _isSensing = false;
        });
        return;
      }

      // Listen for accuracy improvements (Real-Time Auto Fetch)
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 500, 
      );

      _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
        (Position position) {
          _handleNewPosition(position);
        },
        onError: (e) {
          debugPrint("Location Stream Error: $e");
        }
      );

      // Trigger an immediate high-accuracy fetch
      Position initialPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 15),
      );
      _handleNewPosition(initialPosition);

    } catch (e) {
      debugPrint("Sensing Init Error: $e");
      if (_weatherData == null) {
        setState(() {
          _sensingMessage = "Waiting for Satellite...";
          _isSensing = false;
        });
      }
    }
  }

  bool _isWithinIndia(Position position) {
    // Guard against Romania (45, 25) or IP-based offshore errors
    return position.latitude >= 8.0 && position.latitude <= 38.0 && 
           position.longitude >= 68.0 && position.longitude <= 98.0;
  }

  Future<void> _handleNewPosition(Position position) async {
    // ACCURACY GUARD
    if (kIsWeb && position.accuracy > 5000) {
      debugPrint("Ignoring low accuracy IP-location (${position.accuracy}m)");
      return;
    }

    if (!_isWithinIndia(position)) {
      debugPrint("Ignoring offshore location (${position.latitude}, ${position.longitude})");
      if (mounted) {
        setState(() {
          _sensingMessage = "Signal Weak (Checking Region)";
        });
      }
      return; 
    }

    // Refresh weather if moved > 500m
    if (_weatherData != null) {
      double distance = Geolocator.distanceBetween(
        _weatherData!['lat'], 
        _weatherData!['lng'], 
        position.latitude, 
        position.longitude
      );
      if (distance < 500) return;
    }

    if (mounted) setState(() => _isSensing = true);
    await _fetchAndUpdate(position.latitude, position.longitude);
    if (mounted) setState(() => _isSensing = false);
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cachedString = prefs.getString(_cacheKey);
      if (cachedString != null) {
        final Map<String, dynamic> cachedData = json.decode(cachedString);
        if (mounted) {
          setState(() {
            _weatherData = cachedData;
            _isSensing = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Cache load failed: $e");
    }
  }

  Future<void> _fetchAndUpdate(double lat, double lng) async {
    try {
      final data = await _weatherService.fetchWeatherData(lat: lat, lng: lng);
      final finalData = {
        ...data,
        'lat': lat,
        'lng': lng,
      };

      if (mounted) {
        setState(() {
          _weatherData = finalData;
        });
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, json.encode(finalData));
    } catch (e) {
      debugPrint("Weather fetch failed: $e");
    }
  }

  Future<void> _openManualLocationPicker() async {
    final LatLng? currentLatLng = _weatherData != null 
      ? LatLng(_weatherData!['lat'], _weatherData!['lng'])
      : null;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => LocationPickerDialog(initialPosition: currentLatLng),
    );

    if (result != null && mounted) {
      if (mounted) setState(() => _isSensing = true);
      await _fetchAndUpdate(result['lat'], result['lng']);
      if (mounted) setState(() => _isSensing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_weatherData == null || (_isSensing && _weatherData!['location'] == "Sensing Location...")) {
      return _buildPremiumWeatherCard({
        'location': _sensingMessage,
        'temp': 0,
        'condition': 'Loading',
        'humidity': 0,
        'wind_speed': 0,
        'wave_height': 0,
        'isLoading': true,
      });
    }

    return _buildPremiumWeatherCard(_weatherData!);
  }

  Widget _buildPremiumWeatherCard(Map<String, dynamic> data) {
    final bool isLoading = data['isLoading'] ?? false;
    final int temp = (data['temp'] as num).round();
    final int humidity = data['humidity'];
    final double windSpeed = (data['wind_speed'] as num).toDouble();
    final double waveHeight = (data['wave_height'] as num).toDouble();
    final String condition = data['condition'];
    final String location = data['location'];

    return Container(
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
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isLoading 
                    ? [Colors.blue.shade900, Colors.blue.shade700]
                    : [Colors.blue.shade800, Colors.blue.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: _openManualLocationPicker,
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Row(
                                  children: [
                                    if (isLoading || _isSensing)
                                      FadeTransition(
                                        opacity: _pulseController,
                                        child: const Icon(Icons.gps_fixed, color: Colors.white, size: 20),
                                      )
                                    else
                                      const Icon(Icons.location_on, color: Colors.white, size: 20),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        location.toUpperCase(),
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 0.5),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const Icon(Icons.edit_location_alt, color: Colors.white70, size: 14),
                                  ],
                                ),
                              ),
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
                                      isLoading ? 'LOCATING...' : condition.toUpperCase(),
                                      style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                           IconButton(
                             icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
                             onPressed: _initRealTimeSensing,
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
