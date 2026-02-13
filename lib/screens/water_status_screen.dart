import 'package:flutter/material.dart';

import '../data/mock_water_data.dart';
import '../services/warning_service.dart';

class WaterStatusScreen extends StatelessWidget {
  const WaterStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Status'),
      ),
      body: ListView.builder(
        itemCount: mockWaterData.length,
        itemBuilder: (context, index) {
          final data = mockWaterData[index];
          final status = WarningService.evaluate(data);

          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              title: Text(data.locationType),
              subtitle: Text(
                'Temp: ${data.temperature}°C | pH: ${data.ph}',
              ),
              trailing: Text(
                status.name.toUpperCase(),
                style: TextStyle(
                  color: status == WaterStatus.safe
                      ? Colors.green
                      : status == WaterStatus.warning
                          ? Colors.orange
                          : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
