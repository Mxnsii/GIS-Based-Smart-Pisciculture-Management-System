import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/notification_service.dart';
class IotMonitoringScreen extends StatefulWidget {
  const IotMonitoringScreen({super.key});

  @override
  State<IotMonitoringScreen> createState() => _IotMonitoringScreenState();
}

class _IotMonitoringScreenState extends State<IotMonitoringScreen> {
  Map<String, String> _lastAlertedIssues = {"Tilapia": "", "Asian Seabass": ""};

  void _checkAndAlert(double currentRisk, BuildContext context, String species, List<String> issues) {
    String currentIssuesStr = issues.join(",");

    if (currentRisk >= 33.0 && _lastAlertedIssues[species] != currentIssuesStr) {
      _lastAlertedIssues[species] = currentIssuesStr;

      String issueText = issues.isNotEmpty ? issues.join(", ") : 'Parameters exceeded safety threshold';

      NotificationService.showNotification(
        id: species.hashCode,
        title: '⚠️ $species Alert',
        body: 'Critical Issue: $issueText',
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
                'Critical issues detected for $species:\n\n• ${issues.join("\n• ")}\n\nPlease check the water conditions immediately.',
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
    } else if (currentRisk < 33.0) {
      _lastAlertedIssues[species] = "";
    }
  }

  Map<String, dynamic> calculateRisk(String species, double temp, double ph, double turbidity) {
    double score = 0;
    List<String> issues = [];
    
    if (species == "Tilapia" || species == "Both") {
      if (temp < 24) { score += 33.3; issues.add("Low Temperature"); }
      else if (temp > 30) { score += 33.3; issues.add("High Temperature"); }
      
      if (ph < 6.5) { score += 33.3; issues.add("Low pH"); }
      else if (ph > 9.0) { score += 33.3; issues.add("High pH"); }
      
      if (turbidity > 25) { score += 33.3; issues.add("High Turbidity"); }
    } else if (species == "Asian Seabass" || species == "Seabass") {
      if (temp < 26) { score += 33.3; issues.add("Low Temperature"); }
      else if (temp > 32) { score += 33.3; issues.add("High Temperature"); }
      
      if (ph < 7.0) { score += 33.3; issues.add("Low pH"); }
      else if (ph > 8.5) { score += 33.3; issues.add("High pH"); }
      
      if (turbidity > 20) { score += 33.3; issues.add("High Turbidity"); }
    }

    String category = score >= 33.0 ? "High Risk" : "Safe";

    return {
      "percentage": score,
      "category": category,
      "issues": issues
    };
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
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text("No sensor data found"));
                }

                final Map<String, dynamic> values = snapshot.data!.data() as Map<String, dynamic>;

                final sensorData = {
                  "turbidity": double.tryParse(values['turbidity']?.toString() ?? '0') ?? 0.0,
                  "temperature": double.tryParse(values['temperature']?.toString() ?? '0') ?? 0.0,
                  "ph": double.tryParse((values['pH'] ?? values['ph'])?.toString() ?? '0') ?? 0.0,
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
    final List<String> issues = riskData["issues"] ?? [];

    _checkAndAlert(risk, context, species, issues);

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
                      'Species: $species ${species == "Tilapia" ? "(Aeromoniasis Risk)" : "(Bacterial Risk (Vibrio-type))"}', 
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
