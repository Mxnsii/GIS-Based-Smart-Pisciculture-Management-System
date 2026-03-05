import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import '../services/notification_service.dart';
class IotMonitoringScreen extends StatefulWidget {
  const IotMonitoringScreen({super.key});

  @override
  State<IotMonitoringScreen> createState() => _IotMonitoringScreenState();
}

class _IotMonitoringScreenState extends State<IotMonitoringScreen> {
  Map<String, bool> _hasAlerted = {"Tilapia": false, "Asian Seabass": false};

  void _checkAndAlert(double currentRisk, BuildContext context, String species) {
    if (currentRisk >= 66.0 && !(_hasAlerted[species] ?? false)) {
      _hasAlerted[species] = true;

      NotificationService.showNotification(
        id: species.hashCode,
        title: '⚠️ HIGH RISK ALERT',
        body: 'System Parameters for $species have exceeded the safety threshold!',
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: const [
                  Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'HIGH RISK ALERT',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: Text(
                'System Parameters for $species have exceeded the safety threshold!\n\nPlease check the water conditions immediately.',
                style: const TextStyle(fontSize: 16),
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      });
    } else if (currentRisk < 66.0) {
      _hasAlerted[species] = false;
    }
  }

  Map<String, dynamic> calculateRisk(String species, double temp, double ph, double turbidity) {
    double score = 0;
    if (species == "Tilapia" || species == "Both") {
      if (temp > 30) score += 33.3;
      if (ph < 6.5 || ph > 9.0) score += 33.3;
      if (turbidity > 25) score += 33.3;
    } else if (species == "Asian Seabass" || species == "Seabass") {
      if (temp > 32) score += 33.3;
      if (ph < 7.0 || ph > 8.5) score += 33.3;
      if (turbidity > 20) score += 33.3;
    }

    String category = score > 34 ? "High Risk" : "Safe";

    return {
      "percentage": score,
      "category": category
    };
  }

  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref("sensors");

  DatabaseReference _getDbRef() {
    return _dbRef;
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
                  "turbidity": (values['turbidity'] ?? 0.0) as num,
                  "temperature": (values['temperature'] ?? 0.0) as num,
                  "ph": (values['ph'] ?? 0.0) as num,
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

    final double turbidityVal = (data['turbidity'] as num).toDouble();
    final double tempVal = (data['temperature'] as num).toDouble();
    final double phVal = (data['ph'] as num).toDouble();

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetric('Turbidity', turbidityVal.toStringAsFixed(1), Icons.blur_on),
                _buildMetric('Temperature', tempVal.toStringAsFixed(1), Icons.thermostat),
                _buildMetric('pH', phVal.toStringAsFixed(1), Icons.water_drop),
              ],
            ),

            const SizedBox(height: 20),

            _buildRiskProfile("Tilapia", tempVal, phVal, turbidityVal),
            const SizedBox(height: 12),
            _buildRiskProfile("Asian Seabass", tempVal, phVal, turbidityVal),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 28, color: Colors.blue),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildRiskProfile(
      String species,
      double tempVal,
      double phVal,
      double turbidityVal) {

    final riskData =
        calculateRisk(species, tempVal, phVal, turbidityVal);

    final double risk = riskData["percentage"];
    final String category = riskData["category"];

    _checkAndAlert(risk, context, species);

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
              Text(
                'Species: $species ${species == "Tilapia" ? "(Aeromoniasis Risk)" : "(Bacterial Risk (Vibrio-type))"}', 
                style: const TextStyle(fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.analytics, size: 16, color: Colors.blueGrey),
                  const SizedBox(width: 8),
                  const Text('Risk Index: ', style: TextStyle(color: Colors.black87)),
                  Text('${risk.toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                   const Icon(Icons.health_and_safety, size: 16, color: Colors.blueGrey),
                   const SizedBox(width: 8),
                   const Text('Status: ', style: TextStyle(color: Colors.black87)),
                   Text(category, style: TextStyle(fontWeight: FontWeight.bold, color: risk > 33.34 ? Colors.red : Colors.green)),
                ],
              ),
            ],
          ),
        ],
      ),
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
