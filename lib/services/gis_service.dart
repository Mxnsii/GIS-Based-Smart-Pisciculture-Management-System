import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class GisService {
  /// Loads a GeoJSON file from assets and converts features to Polygons.
  Future<List<Polygon>> loadPolygons(String assetPath) async {
    try {
      final jsonString = await rootBundle.loadString(assetPath);
      final Map<String, dynamic> data = json.decode(jsonString);
      
      final List<Polygon> polygons = [];
      
      if (data['type'] == 'FeatureCollection') {
        final List features = data['features'];
        for (var feature in features) {
          final geometry = feature['geometry'];
          final properties = feature['properties'] ?? {};
          
          if (geometry['type'] == 'Polygon') {
             // GeoJSON coordinates are [lng, lat]
            final List<dynamic> coords = geometry['coordinates'][0];
            final List<LatLng> points = coords.map((c) => LatLng(c[1], c[0])).toList();
            
            polygons.add(
              Polygon(
                points: points,
                color: _getColorForStatus(properties['status']).withOpacity(0.3),
                borderColor: _getColorForStatus(properties['status']),
                borderStrokeWidth: 2,
                label: properties['name'],
                labelStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                rotateLabel: true,
              ),
            );
          }
        }
      }
      return polygons;
    } catch (e) {
      debugPrint('Error loading GeoJSON: $e');
      return [];
    }
  }

  Color _getColorForStatus(String? status) {
    switch (status) {
      case 'Active': return Colors.green;
      case 'Pending Approval': return Colors.orange;
      case 'Inactive': return Colors.grey;
      case 'Rejected': return Colors.red;
      default: return Colors.blue;
    }
  }
}
