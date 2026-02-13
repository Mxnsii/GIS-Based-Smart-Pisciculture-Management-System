import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class IotMonitoringScreen extends StatelessWidget {
  const IotMonitoringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'IoT Real-time Monitoring',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('water_parameters')
                  .snapshots(),
              builder: (context, snapshot) {

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No sensor data found"));
                }

                var doc = snapshot.data!.docs.first;

                final sensorData = {
                  "farm": "Farm 1",
                  "sector": "Sector A - Pond 1",
                  "turbidity": doc['turbidity'],
                  "temp": doc['temperature'],
                  "ph": doc['pH'],
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

  Widget _buildSensorCard(Map<String, dynamic> data) {
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
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
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
              mainAxisAlignment:
                  MainAxisAlignment.spaceAround,
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
                  tempVal.toStringAsFixed(1),
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
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12),
        ),
      ],
    );
  }
}
