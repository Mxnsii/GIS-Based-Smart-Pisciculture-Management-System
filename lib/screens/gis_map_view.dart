import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class GisMapView extends StatefulWidget {
  const GisMapView({super.key});

  @override
  State<GisMapView> createState() => _GisMapViewState();
}

class _GisMapViewState extends State<GisMapView> {
  // Mock Data provided by the user
  final List<Map<String, dynamic>> mockFarms = [
    {
      "id": 1,
      "name": "Goa Prawn Farm 1 (Mock)",
      "lat": 15.4989,
      "lng": 73.8278,
      "status": "Active",
      "owner": "R. Sharma"
    },
    {
      "id": 2,
      "name": "Khazan Farm (Mock)",
      "lat": 15.5050,
      "lng": 73.8200,
      "status": "Pending Approval",
      "owner": "S. Naik"
    },
    {
      "id": 3,
      "name": "Sea Cage Site 3 (Mock)",
      "lat": 15.4500,
      "lng": 73.7800,
      "status": "Inactive",
      "owner": "A. Fernandes"
    },
    {
      "id": 4,
      "name": "New Venture Biofloc",
      "lat": 15.4750,
      "lng": 73.8000,
      "status": "Pending Approval",
      "owner": "P. Singh"
    },
  ];

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Active':
        return Colors.green;
      case 'Pending Approval':
        return Colors.orange;
      case 'Inactive':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: const LatLng(15.4989, 73.8278), // Centered on Goa Farm 1
        initialZoom: 12.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.agriconnect.app',
        ),
        MarkerLayer(
          markers: mockFarms.map((farm) {
            return Marker(
              point: LatLng(farm['lat'], farm['lng']),
              width: 80,
              height: 80,
              child: GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(farm['name']),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Owner: ${farm['owner']}'),
                          const SizedBox(height: 8),
                          Text('Status: ${farm['status']}'),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
                child: Icon(
                  Icons.location_on,
                  color: _getStatusColor(farm['status']),
                  size: 40,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
