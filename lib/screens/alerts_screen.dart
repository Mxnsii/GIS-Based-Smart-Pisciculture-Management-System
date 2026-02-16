import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum AlertSeverity { critical, warning, info }

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'System Alerts & Reports',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('water_parameters')
                  .snapshots(),
              builder: (context, snapshot) {

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text("No sensor data found"),
                  );
                }

                var doc = snapshot.data!.docs.first;

                double temp =
                    (doc['temperature'] as num).toDouble();
                double ph =
                    (doc['pH'] as num).toDouble();
                double turbidity =
                    (doc['turbidity'] as num).toDouble();

                List<Widget> alerts = [];

                if (ph < 6.5) {
                  alerts.add(_buildAlertCard(
                    title: "Low pH Level",
                    description: "pH is below safe range (6.5). Current: $ph",
                    severity: AlertSeverity.critical,
                    type: "IoT Monitor",
                    time: "Just now",
                    recommendations: [
                      "Add Agricultural Lime (Calcium carbonate)",
                      "Use Dolomite",
                      "Partial water exchange",
                    ],
                  ));
                } else if (ph > 8.5) {
                  alerts.add(_buildAlertCard(
                    title: "High pH Level",
                    description: "pH is above safe range (8.5). Current: $ph",
                    severity: AlertSeverity.critical,
                    type: "IoT Monitor",
                    time: "Just now",
                    recommendations: [
                      "Partial water change",
                      "Add organic matter (cow dung compost in traditional farming)",
                      "Reduce excessive algae growth",
                      "Use aerators",
                    ],
                  ));
                }

                if (temp < 20) {
                  alerts.add(_buildAlertCard(
                    title: "Low Temperature",
                    description: "Temperature is too low (< 20°C). Current: $temp°C",
                    severity: AlertSeverity.warning,
                    type: "IoT Monitor",
                    time: "Just now",
                    recommendations: [
                      "Cover pond with plastic sheets (temporary greenhouse)",
                      "Increase water depth",
                      "Reduce feeding",
                      "Use aerators",
                    ],
                  ));
                } else if (temp > 30) {
                  alerts.add(_buildAlertCard(
                    title: "High Temperature",
                    description: "Temperature exceeded 30°C. Current: $temp°C",
                    severity: AlertSeverity.warning,
                    type: "IoT Monitor",
                    time: "Just now",
                    recommendations: [
                      "Install aerators",
                      "Add shade nets",
                      "Add fresh water",
                      "Maintain proper water depth",
                    ],
                  ));
                }

                if (turbidity < 2) {
                  alerts.add(_buildAlertCard(
                    title: "Low Turbidity",
                    description: "Turbidity is very low (< 2 NTU). Current: $turbidity",
                    severity: AlertSeverity.warning,
                    type: "IoT Monitor",
                    time: "Just now",
                    recommendations: [
                      "Add organic fertilizers (cow dung / compost)",
                      "Promote plankton growth",
                    ],
                  ));
                } else if (turbidity > 5) {
                  alerts.add(_buildAlertCard(
                    title: "High Turbidity",
                    description: "Turbidity above safe limit (5 NTU). Current: $turbidity",
                    severity: AlertSeverity.critical,
                    type: "IoT Monitor",
                    time: "Just now",
                    recommendations: [
                      "Add Alum (Aluminium sulfate)",
                      "Let particles settle (sedimentation)",
                      "Reduce runoff entering pond",
                      "Control excess feeding",
                    ],
                  ));
                }

                if (alerts.isEmpty) {
                  return const Center(
                    child: Text(
                      "All parameters within safe range ✅",
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: alerts.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return alerts[index];
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard({
    required String title,
    required String description,
    required AlertSeverity severity,
    required String type,
    required String time,
    required List<String> recommendations,
  }) {
    Color color;
    IconData icon;

    switch (severity) {
      case AlertSeverity.critical:
        color = Colors.red;
        icon = Icons.warning_amber_rounded;
        break;
      case AlertSeverity.warning:
        color = Colors.orange;
        icon = Icons.error_outline;
        break;
      case AlertSeverity.info:
        color = Colors.blue;
        icon = Icons.info_outline;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      time,
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  type,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Builder(
                      builder: (context) {
                        return OutlinedButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Row(
                                  children: [
                                    Icon(Icons.lightbulb_outline, color: color),
                                    const SizedBox(width: 8),
                                    const Text('Recommendations'),
                                  ],
                                ),
                                content: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: recommendations
                                        .map((rec) => Padding(
                                              padding: const EdgeInsets.only(bottom: 8.0),
                                              child: Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text("• ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                                  Expanded(child: Text(rec)),
                                                ],
                                              ),
                                            ))
                                        .toList(),
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Close'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: color),
                                    onPressed: () {
                                      // Implementation for acknowledge action (e.g. mark as read)
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Alert acknowledged')),
                                      );
                                    },
                                    child: const Text('Done', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          child: const Text('Acknowledge'),
                        );
                      }
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
