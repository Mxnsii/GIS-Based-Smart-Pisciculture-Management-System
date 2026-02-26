import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class IotMonitoringScreen extends StatefulWidget {
  const IotMonitoringScreen({super.key});

  @override
  State<IotMonitoringScreen> createState() => _IotMonitoringScreenState();
}

class _IotMonitoringScreenState extends State<IotMonitoringScreen> {

  final DatabaseReference _dbRef =
      FirebaseDatabase.instance.ref("sensors");

  DatabaseReference _getDbRef() {
    return _dbRef;
  }

  bool _alertShown = false;

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
            child: StreamBuilder<DatabaseEvent>(
              stream: _getDbRef().onValue,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                if (!snapshot.hasData ||
                    snapshot.data!.snapshot.value == null) {
                  return const Center(child: Text("No sensor data found"));
                }

                final Map<dynamic, dynamic> values =
                    snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

                final sensorData = {
                  "farm": "Farm 1",
                  "sector": "Sector A - Pond 1",
                  "turbidity": (values['turbidity'] ?? 0.0) as num,
                  "temperature": (values['temperature'] ?? 0.0) as num,
                  "ph": (values['ph'] ?? 0.0) as num,
                  "status": "Online"
                };

                return _buildSensorCard(sensorData);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorCard(Map<String, dynamic> data) {
    final bool isOffline = data['status'] == 'Offline';

    final double turbidityVal =
        (data['turbidity'] as num).toDouble();
    final double tempVal =
        (data['temperature'] as num).toDouble();
    final double phVal =
        (data['ph'] as num).toDouble();

    bool turbidityWarning = turbidityVal > 5.0;
    bool tempWarning = tempVal > 30.0;
    bool phWarning = phVal < 6.5 || phVal > 8.5;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [

            /// SENSOR METRICS ROW
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetric(
                  'Turbidity',
                  turbidityVal.toStringAsFixed(1),
                  Icons.blur_on,
                  turbidityWarning ? Colors.red : Colors.blue,
                ),
                _buildMetric(
                  'Temperature',
                  tempVal.toStringAsFixed(1),
                  Icons.thermostat,
                  tempWarning ? Colors.orange : Colors.blue,
                ),
                _buildMetric(
                  'pH',
                  phVal.toStringAsFixed(1),
                  Icons.water_drop,
                  phWarning ? Colors.red : Colors.green,
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// RISK PROFILES
            _buildRiskProfile("Tilapia", tempVal, phVal, turbidityVal),
            const SizedBox(height: 12),
            _buildRiskProfile("Asian Seabass", tempVal, phVal, turbidityVal),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(
      String label,
      String value,
      IconData icon,
      Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color),
        ),
        Text(label,
            style:
                TextStyle(color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildRiskProfile(
      String species,
      double tempVal,
      double phVal,
      double turbidityVal) {

    Map<String, dynamic> riskData =
        calculateRisk(species, tempVal, phVal, turbidityVal);

    double risk = riskData["percentage"];
    String category = riskData["category"];

    _checkAndAlert(risk);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Species: $species",
              style:
                  const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text("Risk Index: ${risk.toStringAsFixed(0)}%"),
          Text("Status: $category",
              style: TextStyle(
                  color:
                      risk > 33 ? Colors.red : Colors.green,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Map<String, dynamic> calculateRisk(
      String species,
      double temp,
      double ph,
      double turbidity) {

    double score = 0;

    if (temp > 30) score += 30;
    if (ph < 6.5 || ph > 8.5) score += 40;
    if (turbidity > 5) score += 30;

    String category = score > 33 ? "High Risk" : "Safe";

    return {
      "percentage": score,
      "category": category
    };
  }

  void _checkAndAlert(double risk) {
    if (risk > 50 && !_alertShown) {
      _alertShown = true;
      Future.delayed(Duration.zero, () {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("⚠ High Risk Alert"),
            content:
                const Text("Water parameters are unsafe!"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _alertShown = false;
                },
                child: const Text("OK"),
              )
            ],
          ),
        );
      });
    }
  }
}