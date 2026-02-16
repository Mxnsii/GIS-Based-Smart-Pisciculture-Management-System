import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;

class GisMapView extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;
  final double initialZoom;

  const GisMapView({
    super.key, 
    this.initialLat, 
    this.initialLng, 
    this.initialZoom = 12.0
  });

  @override
  State<GisMapView> createState() => _GisMapViewState();
}

class _GisMapViewState extends State<GisMapView> {
  // Map Controller to convert screen points to LatLng
  final MapController _mapController = MapController();
  
  // State to track current hover coordinates
  LatLng? _hoveredLatLng;

  // Scale Mapping (Approximation for Web Mercator at ~15 deg Lat)
  final Map<String, double> _scaleMapping = {
    '1: 500,000': 9.0,
    '1: 250,000': 10.5,
    '1: 100,000': 12.0,
    '1: 50,000': 13.0,
    '1: 25,000': 14.0,
    '1: 10,000': 16.0,
  };
  
  String _currentScale = '1: 100,000'; // Default close to zoom 12

  // Update dropdown selection based on current zoom
  void _updateScaleFromZoom(double zoom) {
    String closestScale = _currentScale;
    double minDiff = double.infinity;

    _scaleMapping.forEach((scale, targetZoom) {
      final diff = (targetZoom - zoom).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closestScale = scale;
      }
    });

    if (closestScale != _currentScale && minDiff < 1.0) { // Only update if significantly close
       setState(() {
        _currentScale = closestScale;
      });
    }
  }

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
  
  void _onHover(PointerEvent details) {
    // Get the local position of the mouse relative to the map
    final point = math.Point(details.localPosition.dx, details.localPosition.dy);
    
    // Convert to LatLng
    final latLng = _mapController.camera.pointToLatLng(point);
    
    setState(() {
      _hoveredLatLng = latLng;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine center: use passed arguments if available, otherwise default
    final LatLng center = (widget.initialLat != null && widget.initialLng != null)
        ? LatLng(widget.initialLat!, widget.initialLng!)
        : const LatLng(15.4989, 73.8278);

    return Scaffold(
      appBar: AppBar(
        title: const Text('GIS Map View'),
        // Only show back button if pushed (which happens when selecting coordinates)
        leadingWidth: 80, // Allow more width for text
        leading: Navigator.canPop(context) 
          ? TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'BACK',
                style: TextStyle(
                  color: Colors.green, // Ensure visibility
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null, // Default logic when used in BottomNavBar
      ),
      body: Stack(
        children: [
          MouseRegion(
            onHover: _onHover,
            // Use transparent cursor or default to allow map interaction
            cursor: SystemMouseCursors.basic,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: widget.initialZoom,
                onPositionChanged: (position, hasGesture) {
                  // Update the dropdown if the user zooms via gestures
                  _updateScaleFromZoom(position.zoom ?? widget.initialZoom);
                },
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
                                  const SizedBox(height: 8),
                                  Text('Lat: ${farm['lat']}, Lng: ${farm['lng']}', style: const TextStyle(fontWeight: FontWeight.w500)),
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
                        child: Tooltip(
                          message: '${farm['name']}\nLat: ${farm['lat']}, Lng: ${farm['lng']}',
                          child: Icon(
                            Icons.location_on,
                            color: _getStatusColor(farm['status']),
                            size: 40,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          
          // Coordinate Overlay at Bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.white.withOpacity(0.9),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Co-ordinates: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _hoveredLatLng != null 
                        ? '${_hoveredLatLng!.latitude.toStringAsFixed(5)}, ${_hoveredLatLng!.longitude.toStringAsFixed(5)}'
                        : 'Hover over map',
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                  const SizedBox(width: 24),
                  // Dynamic Scale Dropdown
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Scale: ', style: TextStyle(color: Colors.black)),
                      DropdownButton<String>(
                        value: _currentScale,
                        isDense: true,
                        underline: Container(), // Remove default underline
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                        items: _scaleMapping.keys.map((String scale) {
                          return DropdownMenuItem<String>(
                            value: scale,
                            child: Text(scale),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _currentScale = newValue;
                            });
                            final targetZoom = _scaleMapping[newValue]!;
                            _mapController.move(_mapController.camera.center, targetZoom);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
