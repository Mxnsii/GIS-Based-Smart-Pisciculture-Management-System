import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';

class IotMonitoringScreen extends StatefulWidget {
  const IotMonitoringScreen({super.key});

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

                if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                  return const Center(child: Text("No sensor data found"));
                }

                // Extracting data from Realtime Database
                final Map<dynamic, dynamic> values = 
                    snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

                // IMPORTANT: These keys must match what your ESP32 sends
                final sensorData = {
                  "farm": "Farm 1",
                  "sector": "Sector A - Pond 1",
                  "turbidity": values['turbidity'] ?? 0.0,
                  "temperature": values['temperature'] ?? 0.0, 
                  "ph": values['ph'] ?? 0.0,
                  "status": "Online"
                };

                return GridView.builder(
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 400,
                    childAspectRatio: 1.4,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                  ),
                  itemCount: 1,
                  itemBuilder: (context, index) {
                    return _buildSensorCard(sensorData);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorCard(Map<String, dynamic> data, BuildContext context) {
    final bool isOffline = data['status'] == 'Offline';

    final double turbidityVal =
        (data['turbidity'] as num).toDouble();
    final double tempVal =
        (data['temp'] as num).toDouble();
    final double phVal =
        (data['ph'] as num).toDouble();

    // Threshold logic
    bool turbidityWarning = turbidityVal > 5.0;
    bool tempWarning = tempVal > 30.0;
    bool phWarning = phVal < 6.5 || phVal > 8.5;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['farm'],
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        data['sector'],
                        style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOffline
                        ? Colors.red.shade50
                        : Colors.green.shade50,
                    borderRadius:
                        BorderRadius.circular(12),
                    border: Border.all(
                        color: isOffline
                            ? Colors.red
                            : Colors.green),
                  ),
                  child: Text(
                    data['status'],
                    style: TextStyle(
                      color: isOffline
                          ? Colors.red
                          : Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetric(
                  'Turbidity (NTU)', 
                  turbidityVal.toStringAsFixed(1), 
                  Icons.blur_on,
                  isOffline
                      ? Colors.grey
                      : turbidityWarning
                          ? Colors.red
                          : Colors.blue,
                ),
                _buildMetric(
                  'Temp (°C)', 
                  temperatureVal.toStringAsFixed(1), 
                  Icons.thermostat,
                  isOffline
                      ? Colors.grey
                      : tempWarning
                          ? Colors.orange
                          : Colors.blue,
                ),
                _buildMetric(
                  'pH', 
                  phVal.toStringAsFixed(1), 
                  Icons.water_drop,
                  isOffline
                      ? Colors.grey
                      : phWarning
                          ? Colors.red
                          : Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 20),
            // RISK INJECTIONS
            const Divider(),
            const SizedBox(height: 12),
            _buildRiskProfile("Tilapia", tempVal, phVal, turbidityVal, context),
            const SizedBox(height: 12),
            _buildRiskProfile("Asian Seabass", tempVal, phVal, turbidityVal, context),
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
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)
        ),
        Text(
          label, 
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12)
        ),
      ],
    );
  }

  Widget _buildRiskProfile(String species, double tempVal, double phVal, double turbidityVal, BuildContext context) {
    // Evaluate Risk using logic pattern
    var riskData = calculateRisk(species, tempVal, phVal, turbidityVal);
    double currentRisk = riskData["percentage"];
    String category = riskData["category"];
    
    // Check for alerts automatically
    _checkAndAlert(currentRisk, context, species);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(8)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Species: $species', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.analytics, size: 16, color: Colors.blueGrey),
              const SizedBox(width: 8),
              const Text('Risk Index: ', style: TextStyle(color: Colors.black87)),
              Text('${currentRisk.toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
               const Icon(Icons.health_and_safety, size: 16, color: Colors.blueGrey),
               const SizedBox(width: 8),
               const Text('Status: ', style: TextStyle(color: Colors.black87)),
               Text(category, style: TextStyle(fontWeight: FontWeight.bold, color: currentRisk > 33.34 ? Colors.red : Colors.green)),
            ],
          ),
        ],
      ),
    );
  }
}