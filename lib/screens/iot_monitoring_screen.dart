import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;
import '../services/notification_service.dart';
import '../services/ml_prediction_service.dart';
import '../widgets/weather_widget.dart';
import '../services/ai_species_service.dart';
import '../services/weather_service.dart';
import 'package:geolocator/geolocator.dart';
import 'fish_directory_screen.dart';

class IotMonitoringScreen extends StatefulWidget {
  const IotMonitoringScreen({super.key});

  @override
  State<IotMonitoringScreen> createState() => _IotMonitoringScreenState();
}

class _IotMonitoringScreenState extends State<IotMonitoringScreen> {
  Map<String, String> _lastAlertedIssues = {"Tilapia": "", "Asian Seabass": ""};

  void _checkAndAlert(bool isDangerous, BuildContext context, String species, String disease) {
    if (isDangerous && _lastAlertedIssues[species] != disease) {
      _lastAlertedIssues[species] = disease;

      NotificationService.showNotification(
        id: species.hashCode,
        title: '⚠️ AI Alert: $species',
        body: 'Disease Predicted: $disease',
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: const [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'AI RISK PREDICTION',
                      style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: Text(
                'The ML model has predicted a high risk of disease for $species based on current water parameters:\n\n• Predicted: $disease\n\nPlease check the water conditions immediately.',
                style: const TextStyle(fontSize: 16),
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Acknowledge'),
                ),
              ],
            );
          },
        );
      });
    } else if (!isDangerous) {
      _lastAlertedIssues[species] = "";
    }
  }



  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'IoT Real-time Monitoring',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('water_parameters').doc('2pBQE1SbutGXrRT6NjjA').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(),
                  ));
                }

                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text("No sensor data found"));
                }

                final Map<String, dynamic> values =
                    snapshot.data!.data() as Map<String, dynamic>;

                final sensorData = {
                  "turbidity": double.tryParse(values['turbidity']?.toString() ?? '0') ?? 0.0,
                  "temperature": double.tryParse(values['temperature']?.toString() ?? '0') ?? 0.0,
                  "ph": double.tryParse((values['pH'] ?? values['ph'])?.toString() ?? '0') ?? 0.0,
                };

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildSensorCard(sensorData),
                      const SizedBox(height: 24),
                      _buildRecommendationSection(sensorData['temperature'] as double),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationSection(double currentTemp) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchAiRecommendations(),
      initialData: AISpeciesService.getFallbackRecommendations(currentTemp),
      builder: (context, snapshot) {
        final List<Map<String, dynamic>> recommendations = snapshot.data ?? [];
        final bool isSyncing = snapshot.connectionState == ConnectionState.waiting;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🐟 Best Species for Today',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    if (!isSyncing)
                       Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.green.shade100),
                        ),
                        child: Text(
                          'LIVE AI VERIFIED',
                          style: TextStyle(color: Colors.green.shade700, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                        ),
                      ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const FishDirectoryScreen()),
                    );
                  },
                  child: const Text('View All', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: recommendations.length,
                separatorBuilder: (context, index) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final item = recommendations[index];
                  return _buildSpeciesCard(
                    name: item['name'],
                    sub: item['sub'],
                    price: item['price'],
                    rating: item['rating'],
                    trend: item['trend'],
                    icon: item['icon'],
                    trendIcon: _getTrendIcon(item['trendIcon']),
                    bestTime: item['bestTime'],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }


  IconData _getTrendIcon(String? trend) {
    switch (trend?.toLowerCase()) {
      case 'up': return Icons.trending_up;
      case 'down': return Icons.trending_down;
      default: return Icons.trending_flat;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchAiRecommendations() async {
    try {
      final weatherService = WeatherService();
      
      // Default to Panjim coords
      double lat = 15.4909;
      double lng = 73.8278;
      
      try {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 2),
        );
        lat = pos.latitude;
        lng = pos.longitude;
      } catch (_) {}

      final weather = await weatherService.fetchWeatherData(lat: lat, lng: lng);
      
      return await AISpeciesService.getLiveRecommendations(
        temp: (weather['temp'] as num).toDouble(),
        waveHeight: (weather['wave_height'] as num).toDouble(),
        windSpeed: (weather['wind_speed'] as num).toDouble(),
        condition: weather['condition'],
        location: weather['location'],
      );
    } catch (e) {
      debugPrint('Error fetching AI recommendations: $e');
      rethrow;
    }
  }

  Widget _buildSpeciesCard({
    required String name,
    required String sub,
    required String price,
    required int rating,
    required String trend,
    required String icon,
    required IconData trendIcon,
    required String bestTime,
  }) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(icon, style: const TextStyle(fontSize: 24)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                child: Text(price, style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(sub, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
          const SizedBox(height: 12),
          Row(
            children: List.generate(5, (i) => Icon(Icons.star, size: 12, color: i < rating ? Colors.orange : Colors.grey.shade300)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(trendIcon, size: 14, color: Colors.blueGrey),
              const SizedBox(width: 4),
              Expanded(child: Text(trend, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.access_time, size: 14, color: Colors.orange),
              const SizedBox(width: 4),
              Text('Time: $bestTime', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSensorCard(Map<String, dynamic> data) {

    final double turbidityVal = data['turbidity'];
    final double tempVal = data['temperature'];
    final double phVal = data['ph'];

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
  
              Wrap(
                alignment: WrapAlignment.spaceEvenly,
                spacing: 12,
                runSpacing: 16,
                children: [
                  SpeedometerGauge(
                    title: 'Turbidity',
                    value: turbidityVal,
                    min: 0,
                    max: 40,
                    unit: ' NTU',
                    gradientColors: const [Colors.red, Colors.green, Colors.green, Colors.yellow, Colors.orange, Colors.red],
                    gradientStops: const [0.0, 0.49, 0.5, 0.75, 0.8125, 1.0],
                  ),
                  SpeedometerGauge(
                    title: 'Temp',
                    value: tempVal,
                    min: 15,
                    max: 45,
                    unit: '°C',
                    gradientColors: const [Colors.red, Colors.red, Colors.red, Colors.yellow, Colors.green, Colors.green, Colors.yellow, Colors.red],
                    gradientStops: const [0.0, 0.49, 0.5, 0.6, 0.65, 0.78, 0.83, 1.0],
                  ),
                  SpeedometerGauge(
                    title: 'pH',
                    value: phVal,
                    min: 0,
                    max: 14,
                    unit: '',
                    gradientColors: const [Colors.red, Colors.red, Colors.red, Colors.yellow, Colors.green, Colors.green, Colors.yellow, Colors.red],
                    gradientStops: const [0.0, 0.49, 0.5, 0.675, 0.73, 0.82, 0.875, 1.0],
                  ),
                ],
              ),
  
              const SizedBox(height: 20),
  
              _buildRiskProfile("Tilapia", tempVal, phVal, turbidityVal),
              const SizedBox(height: 12),
              _buildRiskProfile("Asian Seabass", tempVal, phVal, turbidityVal),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRiskProfile(
      String species,
      double tempVal,
      double phVal,
      double turbidityVal) {

    return FutureBuilder<String>(
      future: MlPredictionService.getPrediction(
        species: species == "Asian Seabass" ? "Seabass" : species,
        temperature: tempVal,
        ph: phVal,
        turbidity: turbidityVal,
        dissolvedOxygen: 6.0, // Default safe DO since IoT doesn't track it
      ),
      builder: (context, snapshot) {
        bool isWaiting = snapshot.connectionState == ConnectionState.waiting;
        String status = "AI Analyzing...";
        Color statusColor = Colors.grey;
        bool isDangerous = false;

        if (snapshot.hasError) {
          status = "ML Server Offline";
          statusColor = Colors.orange;
        } else if (snapshot.hasData) {
          status = snapshot.data!;
          if (status.toLowerCase().contains("healthy") || status.toLowerCase().contains("safe") || status.trim().isEmpty) {
            status = "Healthy";
            statusColor = Colors.green;
          } else {
            statusColor = Colors.red;
            isDangerous = true;
          }
        }

        // Trigger alert only when not waiting
        if (!isWaiting && snapshot.hasData) {
          _checkAndAlert(isDangerous, context, species, status);
        }

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blueGrey.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Species: $species', 
                          style: const TextStyle(fontWeight: FontWeight.bold)
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.info_outline, color: Colors.blue),
                        tooltip: 'Show Safe Ranges',
                        onPressed: () => _showSafeRangeInfo(context, species),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.psychology, size: 16, color: Colors.purple),
                      const SizedBox(width: 8),
                      const Text('ML Prediction: ', style: TextStyle(color: Colors.black87)),
                      if (isWaiting)
                        const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))
                      else
                        Text(status, style: TextStyle(fontWeight: FontWeight.bold, color: statusColor)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                       const Icon(Icons.health_and_safety, size: 16, color: Colors.blueGrey),
                       const SizedBox(width: 8),
                       const Text('Status: ', style: TextStyle(color: Colors.black87)),
                       Text(isDangerous ? "High Risk" : (isWaiting ? "Computing" : "Safe"), style: TextStyle(fontWeight: FontWeight.bold, color: isDangerous ? Colors.red : (isWaiting ? Colors.grey : Colors.green))),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }


  void _showSafeRangeInfo(BuildContext context, String species) {
    String title = species == "Tilapia" ? "TILAPIA" : "Asian seabass";
    String tempRange = species == "Tilapia" ? "24–30°C" : "26–32°C";
    String phRange = species == "Tilapia" ? "6.5 – 9" : "7 – 8.5";
    String turbRange = species == "Tilapia" ? "< 25 NTU" : "< 20 NTU";

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(child: Text('SAFE RANGE\n$title', style: const TextStyle(fontSize: 16))),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(1),
                  1: FlexColumnWidth(1),
                },
                children: [
                  TableRow(
                    children: [
                      Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Text('Parameter', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                      Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Text('Safe Zone', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                    ]
                  ),
                  TableRow(
                    children: [
                      const Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: Text('Temperature')),
                      Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Text(tempRange, style: const TextStyle(fontWeight: FontWeight.bold))),
                    ]
                  ),
                  TableRow(
                    children: [
                      const Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: Text('pH')),
                      Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Text(phRange, style: const TextStyle(fontWeight: FontWeight.bold))),
                    ]
                  ),
                  TableRow(
                    children: [
                      const Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: Text('Turbidity')),
                      Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Text(turbRange, style: const TextStyle(fontWeight: FontWeight.bold))),
                    ]
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

class SpeedometerGauge extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final String title;
  final String unit;
  final List<Color> gradientColors;
  final List<double> gradientStops;

  const SpeedometerGauge({
    Key? key,
    required this.value,
    required this.min,
    required this.max,
    required this.title,
    required this.unit,
    required this.gradientColors,
    required this.gradientStops,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 76,
          height: 50,
          child: CustomPaint(
            painter: _SpeedometerPainter(
              value: value,
              min: min,
              max: max,
              gradientColors: gradientColors,
              gradientStops: gradientStops,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${value.toStringAsFixed(1)}$unit',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        Text(
          title,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
        ),
      ],
    );
  }
}

class _SpeedometerPainter extends CustomPainter {
  final double value;
  final double min;
  final double max;
  final List<Color> gradientColors;
  final List<double> gradientStops;

  _SpeedometerPainter({
    required this.value,
    required this.min,
    required this.max,
    required this.gradientColors,
    required this.gradientStops,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Offset center = Offset(size.width / 2, size.height);
    double radius = size.width / 2;
    Rect rect = Rect.fromCircle(center: center, radius: radius);

    Paint gradientPaint = Paint()
      ..shader = SweepGradient(
        startAngle: 0.0,
        endAngle: 2 * math.pi,
        colors: gradientColors,
        stops: gradientStops,
      ).createShader(rect)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Background track (so we see the full semi-circle clearly)
    Paint bgTrackPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, math.pi, math.pi, false, bgTrackPaint);

    // Draw full gauge gradient arc over the background
    canvas.drawArc(rect, math.pi, math.pi, false, gradientPaint);

    // Draw needle
    double clampedValue = value.clamp(min, max);
    double sweepAngle = math.pi * ((clampedValue - min) / (max - min));
    double needleAngle = math.pi + sweepAngle;
    
    Paint needlePaint = Paint()
      ..color = Colors.blueGrey.shade900
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    Offset needleTip = Offset(
      center.dx + (radius - 5) * math.cos(needleAngle),
      center.dy + (radius - 5) * math.sin(needleAngle),
    );

    canvas.drawLine(center, needleTip, needlePaint);

    // Draw center pivot
    Paint pivotPaint = Paint()..color = Colors.blueGrey.shade900;
    canvas.drawCircle(center, 5, pivotPaint);
    Paint innerPivotPaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, 2, innerPivotPaint);
  }

  @override
  bool shouldRepaint(covariant _SpeedometerPainter oldDelegate) {
    return oldDelegate.value != value;
  }
}
