import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;
import 'farm_details_screen.dart';
import '../widgets/custom_back_button.dart';
import '../services/gis_service.dart'; // Import the service
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import '../widgets/glass_card.dart';
import '../widgets/ocean_glass_card.dart';
import '../theme/app_theme.dart';

class GisMapView extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;
  final double initialZoom;
  final List<Map<String, dynamic>>? farms;
  final bool isAuthority;

  const GisMapView({
    super.key, 
    this.initialLat, 
    this.initialLng, 
    this.initialZoom = 12.0,
    this.farms,
    this.showBackButton = true,
    this.isAuthority = false,
  });

  final bool showBackButton;

  @override
  State<GisMapView> createState() => _GisMapViewState();
}

class _GisMapViewState extends State<GisMapView> {
  final MapController _mapController = MapController();
  final GisService _gisService = GisService();
  
  List<Polygon> _farmPolygons = [];
  LatLng? _hoveredLatLng;

  // Scale Mapping
  final Map<String, double> _scaleMapping = {
    '1: 500,000': 9.0,
    '1: 250,000': 10.5,
    '1: 100,000': 12.0,
    '1: 50,000': 13.0,
    '1: 25,000': 14.0,
    '1: 10,000': 16.0,
  };
  
  String _currentScale = '1: 100,000';

  bool _isSatellite = false; // Default to Street view
  bool _showHotspots = false; // Toggle to show complaint hotspots
  bool _showSafetyZones = true; 
  bool _showFishDensity = true; 

  @override
  void initState() {
    super.initState();
    _loadGisData();
  }

  Future<void> _loadGisData() async {
    final polygons = await _gisService.loadPolygons('assets/maps/farm_data.geojson');
    setState(() {
      _farmPolygons = polygons;
    });
  }

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

    if (closestScale != _currentScale && minDiff < 1.0) {
       setState(() {
        _currentScale = closestScale;
      });
    }
  }

  // Mock Data (Synchronized with Farm Registry)
  final List<Map<String, dynamic>> _defaultFarms = [
    {
      "id": "FRM-2024-001",
      "name": "Goa Smart Prawn Farm",
      "owner": "Rajesh Sharma",
      "contact": "+91 98765 43210",
      "email": "rajesh.sharma@example.com",
      "address": "Plot 42, Coastal Road, Calangute",
      "district": "North Goa",
      "taluka": "Bardez",
      "village": "Calangute",
      "totalArea": "2.5 ha",
      "pondCount": 4,
      "regDate": "2023-01-15",
      "license": "LIC-2023-001",
      "status": "Active",
      "lat": 15.5406,
      "lng": 73.7562,
      "geofenceRadius": "500m",
      "soilType": "Clay Loam",
      "landCategory": "Coastal",
      "floodZone": "Moderate Risk",
      "waterSource": "Estuary & Borewell",
      "elevation": "4m",
      "ph": 7.8,
      "temp": 28.5,
      "turbidity": "12 NTU",
      "do": "6.5 mg/L",
      "salinity": "15 ppt",
      "lastUpdate": "10 mins ago",
      "riskStatus": "Normal",
      "alarmCount": 0,
       "species": "Vannamei Shrimp",
      "quantity": "50,000",
      "stockDate": "2023-11-01",
      "harvestDate": "2024-03-15",
      "feedType": "Growel Feeds - Starter",
      "feedSupplier": "Goa Feeds Ltd",
      "growthStage": "Growth Phase",
      "diseaseHistory": "None",
      "diseaseAlerts": "None",
      "floodAlertHistory": "Oct 2023 - Minor",
      "pollutionScore": "Low (12/100)",
      "insuranceClaims": "None",
      "scheme": "PMMSY - Biofloc Support",
      "subsidyStatus": "Approved - 40%",
      "insuranceDetails": "Oriental Insurance - Valid till Dec 2024",
      "revenueEst": "₹ 12,00,000",
      "lossHistory": "Nil",
      "docs": {
        "License": "Verified",
        "Land Ownership": "Verified",
        "Pollution Cert": "Verified",
        "Bank Details": "Verified",
        "ID Proof": "Verified"
      },
      "productivity": "4.2 tons/ha",
      "mortalityRate": "5%",
      "sustainabilityScore": "85/100",
      "inspector": "Dr. V. Naik",
      "inspectionDate": "2023-12-10",
      "remarks": "Excellent adherence to biosecurity protocols.",
      "approvalTime": "2023-12-12 10:00 AM",
    },
    {
      "id": "FRM-2024-002",
      "name": "Khazan Traditional Farm",
      "owner": "Sandeep Naik",
      "contact": "+91 91234 56789",
      "email": "s.naik@example.com",
      "address": "H.No 12, Riverside, Divar Island",
      "district": "North Goa",
      "taluka": "Tiswadi",
      "village": "Divar",
      "totalArea": "5.0 ha",
      "pondCount": 1,
      "regDate": "2024-02-01",
      "license": "Pending",
      "status": "Pending Approval",
      "lat": 15.51,
      "lng": 73.91,
      "geofenceRadius": "1000m",
      "soilType": "Saline Alluvial",
      "landCategory": "Khazan Land",
      "floodZone": "High Risk",
      "waterSource": "River Mandovi",
      "elevation": "1m",
      "ph": 7.2,
      "temp": 29.1,
      "turbidity": "45 NTU (High)",
      "do": "5.1 mg/L",
      "salinity": "22 ppt",
      "lastUpdate": "1 hour ago",
      "riskStatus": "Warning",
      "alarmCount": 2,
      "species": "Local Mullet & Pearl Spot",
      "quantity": "Natural Stocking",
      "stockDate": "N/A",
      "harvestDate": "April 2024",
      "feedType": "Natural Algae",
      "feedSupplier": "N/A",
      "growthStage": "Maturation",
      "diseaseHistory": "Minor Gill Rot in 2022",
      "diseaseAlerts": "Watch for fungal infection",
      "floodAlertHistory": "High Tide Breach - Aug 2023",
      "pollutionScore": "Moderate (45/100)",
      "insuranceClaims": "Claim #4421 - Pending",
      "scheme": "State Khazan Revival",
      "subsidyStatus": "Application Submitted",
      "insuranceDetails": "Not yet insured",
      "revenueEst": "₹ 5,00,000",
      "lossHistory": "₹ 50,000 (Monsoon 2023)",
      "docs": {
        "License": "In Process",
        "Land Ownership": "Verified",
        "Pollution Cert": "Pending",
        "Bank Details": "Verified",
        "ID Proof": "Verified"
      },
      "productivity": "1.5 tons/ha",
      "mortalityRate": "Unknown",
      "sustainabilityScore": "92/100",
      "inspector": "Pending Assignment",
      "inspectionDate": "Scheduled: 2024-02-25",
      "remarks": "Waiting for site visit.",
      "approvalTime": "N/A",
    },
    {
      "id": "FRM-2023-089",
      "name": "Mandovi Cage Culture",
      "owner": "Anthony Fernandes",
      "contact": "+91 98221 55555",
      "email": "a.fernandes@example.com",
      "address": "Jetty Road, Panjim",
      "district": "North Goa",
      "taluka": "Tiswadi",
      "village": "Panjim",
      "totalArea": "10 Cages",
      "pondCount": 10,
      "regDate": "2023-05-10",
      "license": "LIC-CAGE-003",
      "status": "Inactive",
      "lat": 15.5000,
      "lng": 73.8300,
      "geofenceRadius": "200m",
      "soilType": "River Bed",
      "landCategory": "Estuarine",
      "floodZone": "Moderate",
      "waterSource": "River Mandovi",
      "elevation": "0m",
      "ph": "N/A",
      "temp": "N/A",
      "turbidity": "N/A", 
      "do": "N/A",
      "salinity": "N/A",
      "lastUpdate": "Offline (30 days)",
      "riskStatus": "Critical", 
      "alarmCount": 0,
      "species": "Asian Seabass",
      "quantity": "0",
      "stockDate": "Harvested Dec 2023",
      "harvestDate": "N/A",
      "feedType": "Floating Pellets",
      "feedSupplier": "Cargill",
      "growthStage": "Fallow",
      "diseaseHistory": "None",
      "diseaseAlerts": "None",
      "floodAlertHistory": "None",
      "pollutionScore": "High (Traffic)",
      "insuranceClaims": "None",
      "scheme": "Blue Revolution",
      "subsidyStatus": "Received",
      "insuranceDetails": "Expired Jan 2024",
      "revenueEst": "₹ 0",
      "lossHistory": "Nil",
      "docs": {
        "License": "Expired",
        "NOC": "Valid",
      },
      "productivity": "Total 5 tons (2023)",
      "mortalityRate": "2%",
      "sustainabilityScore": "70/100",
      "inspector": "Dr. V. Naik",
      "inspectionDate": "2023-11-20",
      "remarks": "Operations temporarily suspended.",
      "approvalTime": "2023-05-15",
    },
    {
      "id": "FRM-2024-005",
      "name": "Zuari Biofloc Unit",
      "owner": "Preeti Singh",
      "contact": "+91 77777 88888",
      "email": "p.singh@example.com",
      "address": "Ind. Estate, Cortalim",
      "district": "South Goa",
      "taluka": "Mormugao",
      "village": "Cortalim",
      "totalArea": "0.5 ha",
      "pondCount": 6,
      "regDate": "2024-01-10",
      "license": "Rejected",
      "status": "Rejected",
      "lat": 15.4000,
      "lng": 73.9500,
      "geofenceRadius": "100m",
      "soilType": "Laterite",
      "landCategory": "Industrial",
      "floodZone": "Low",
      "waterSource": "Municipal Supply",
      "elevation": "15m",
      "ph": "-",
      "temp": "-",
      "turbidity": "-",
      "do": "-",
      "salinity": "-",
      "lastUpdate": "Never",
      "riskStatus": "Unknown",
      "alarmCount": 0,
      "species": "Tilapia",
      "quantity": "0",
      "stockDate": "N/A",
      "harvestDate": "N/A",
      "feedType": "N/A",
      "feedSupplier": "N/A",
      "growthStage": "N/A",
      "diseaseHistory": "N/A",
      "diseaseAlerts": "N/A",
      "floodAlertHistory": "N/A",
      "pollutionScore": "High (Ind. Waste)",
      "insuranceClaims": "N/A",
      "scheme": "PMMSY",
      "subsidyStatus": "Rejected",
      "insuranceDetails": "N/A",
      "revenueEst": "0",
      "lossHistory": "N/A",
      "docs": {
        "License": "Rejected",
        "Land Doc": "Disputed",
      },
      "productivity": "N/A",
      "mortalityRate": "N/A",
      "sustainabilityScore": "20/100",
      "inspector": "Official #42",
      "inspectionDate": "2024-01-20",
      "remarks": "Land use mismatch. Industrial zone not improved for aquaculture.",
      "approvalTime": "N/A",
      "rejectionReason": "Land Use Violation",
    },
  ];

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Active':
        return const Color(0xFF10B981); // Emerald
      case 'Pending Approval':
        return const Color(0xFFF59E0B); // Amber
      case 'Inactive':
        return const Color(0xFF64748B); // Slate
      case 'Rejected':
        return const Color(0xFFEF4444); // Red
      default:
        return const Color(0xFF3B82F6); // Blue
    }
  }
  
  void _onHover(PointerEvent details) {
    final point = math.Point(details.localPosition.dx, details.localPosition.dy);
    final latLng = _mapController.camera.pointToLatLng(point);
    
    setState(() {
      _hoveredLatLng = latLng;
    });
  }

  Widget _buildMarkerLayer(List<Map<String, dynamic>> farmsToShow) {
    return MarkerLayer(
      markers: farmsToShow.map((farm) {
        double lat = 15.0;
        double lng = 73.0;
        if (farm['lat'] != null) {
          lat = farm['lat'] is String ? double.tryParse(farm['lat']) ?? 15.0 : farm['lat'].toDouble();
        }
        if (farm['lng'] != null) {
          lng = farm['lng'] is String ? double.tryParse(farm['lng']) ?? 73.0 : farm['lng'].toDouble();
        }

        final Color statusColor = _getStatusColor(farm['status'] ?? 'Unknown');

        return Marker(
          point: LatLng(lat, lng),
          width: 80,
          height: 80,
          child: GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => Dialog(
                  backgroundColor: Colors.transparent,
                  child: OceanGlassCard(
                    borderRadius: 20,
                    margin: EdgeInsets.zero,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                farm['name'] ?? 'Unknown Farm',
                                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 16),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: statusColor.withOpacity(0.4), width: 1),
                              ),
                              child: Text(
                                farm['status'] ?? 'Unknown',
                                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(height: 1, color: AppColors.divider),
                        const SizedBox(height: 16),
                        _buildDialogDetailRow('Owner', farm['owner'] ?? 'Unknown'),
                        _buildDialogDetailRow('License', farm['license'] ?? 'N/A'),
                        _buildDialogDetailRow('Coordinates', '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}'),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Close', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 12),
                            if ((farm['status'] ?? '') != 'Inactive')
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context); // Close dialog
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => FarmDetailsScreen(farmData: farm, isAuthority: widget.isAuthority),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                ),
                                child: const Text('View Full Details', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            child: Tooltip(
              message: '${farm['name']}\nLat: $lat, Lng: $lng',
              textStyle: const TextStyle(color: Colors.white, fontSize: 11),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: PulsingRadarMarker(
                color: statusColor,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.location_on,
                      color: statusColor,
                      size: 38,
                    ),
                    const Positioned(
                      top: 5,
                      child: Icon(
                        Icons.agriculture,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDialogDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(value, style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final LatLng center = (widget.initialLat != null && widget.initialLng != null)
        ? LatLng(widget.initialLat!, widget.initialLng!)
        : const LatLng(15.4989, 73.8278);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'GIS Map View',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 80,
        leading: widget.showBackButton && Navigator.canPop(context) 
          ? CustomBackButton(
              onPressed: () => Navigator.pop(context),
            )
          : null,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.black.withOpacity(0.08),
            height: 1.0,
          ),
        ),
      ),
      body: Stack(
        children: [
          MouseRegion(
            onHover: _onHover,
            cursor: SystemMouseCursors.basic,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: widget.initialZoom,
                onPositionChanged: (position, hasGesture) {
                  _updateScaleFromZoom(position.zoom ?? widget.initialZoom);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: _isSatellite 
                      ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                      : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.agriconnect.app',
                ),
                if (_isSatellite)
                  TileLayer(
                    urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/Reference/World_Boundaries_and_Places/MapServer/tile/{z}/{y}/{x}',
                    userAgentPackageName: 'com.agriconnect.app',
                    backgroundColor: Colors.transparent,
                  ),
                PolygonLayer(
                  polygons: _farmPolygons,
                ),
                if (widget.farms != null)
                  _buildMarkerLayer(widget.farms!),
                if (widget.farms == null)
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('farms').snapshots(),
                    builder: (context, snapshot) {
                      List<Map<String, dynamic>> combinedFarms = List.from(_defaultFarms);
                      
                      if (snapshot.hasData) {
                        for (var doc in snapshot.data!.docs) {
                          final data = doc.data() as Map<String, dynamic>;
                          if (data['name'] == null || data['name'].toString().trim().isEmpty || data['name'] == 'Unknown Farm') {
                            continue;
                          }
                          combinedFarms.add(data);
                        }
                      }
                      
                      return _buildMarkerLayer(combinedFarms);
                    },
                  ),
                
                // Hotspot Cluster Layer
                if (_showHotspots)
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('complaints')
                        .where('status', isEqualTo: 'Action Taken')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();
                      
                      Map<String, List<Marker>> groupedMarkers = {};

                      Map<String, Map<String, dynamic>> activityStyles = {
                        'Fishing in Banned Area (CRZ / Protected Zone)': {'tag': 'CRZ', 'color': Colors.red},
                        'Fishing During Ban Season': {'tag': 'BS', 'color': Colors.orange},
                        'Using Illegal Small Nets': {'tag': 'SN', 'color': Colors.deepPurple},
                        'Suspicious Night Fishing': {'tag': 'NF', 'color': Colors.indigo},
                        'Dumping Trash or Oil': {'tag': 'DT/O', 'color': Colors.brown},
                        'Other': {'tag': 'OTH', 'color': Colors.teal},
                      };

                      for (var doc in snapshot.data!.docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        if (data['location'] != null && data['location'] is GeoPoint) {
                          final point = data['location'] as GeoPoint;
                          
                          String activity = (data['activityType'] ?? 'Other').toString();
                          final style = activityStyles[activity] ?? activityStyles['Other']!;
                          final Color groupColor = style['color'];
                          final String labelTag = style['tag'];
                          bool isAIHotspot = false; 
                          
                          if (data['aiAnalysis'] != null) {
                            isAIHotspot = data['aiAnalysis']['isHotspot'] == true;
                          }
                          
                          final marker = Marker(
                            point: LatLng(point.latitude, point.longitude),
                            width: 60,
                            height: 60,
                            child: GestureDetector(
                              onTap: () {
                                 showDialog(
                                   context: context,
                                   builder: (context) => Dialog(
                                     backgroundColor: Colors.transparent,
                                     child: OceanGlassCard(
                                        borderRadius: 20,
                                        margin: EdgeInsets.zero,
                                        padding: const EdgeInsets.all(24),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(Icons.crisis_alert, color: AppColors.danger, size: 20),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Incident Report', 
                                                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 16),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 16),
                                            Container(height: 1, color: AppColors.divider),
                                            const SizedBox(height: 16),
                                            _buildDialogDetailRow('Activity', data['activityType'] ?? 'Other'),
                                            _buildDialogDetailRow('Vessel', data['vesselType'] ?? 'Unknown'),
                                            if (data['aiAnalysis'] != null)
                                               _buildDialogDetailRow('AI Priority', '${data['aiAnalysis']['priority']}'),
                                            const SizedBox(height: 24),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context), 
                                                  child: Text('Close', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                                                ),
                                                const SizedBox(width: 12),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                    _showDetailedComplaint(context, data);
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: AppColors.primary,
                                                    foregroundColor: Colors.white,
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                                  ),
                                                  child: const Text('View Full Details', style: TextStyle(fontWeight: FontWeight.bold)),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                   ),
                                 );
                              },
                              child: PulsingRadarMarker(
                                color: groupColor,
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: groupColor.withOpacity(0.9),
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: [
                                      BoxShadow(color: groupColor.withOpacity(0.5), blurRadius: 10, spreadRadius: 2),
                                      if (isAIHotspot) BoxShadow(color: Colors.red.withOpacity(0.8), blurRadius: 15, spreadRadius: 4),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      labelTag,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          );
                          
                          groupedMarkers.putIfAbsent(activity, () => []).add(marker);
                        }
                      }

                      List<Widget> categoricalClusterLayers = [];

                      groupedMarkers.forEach((activityName, markers) {
                        final style = activityStyles[activityName] ?? activityStyles['Other']!;
                        final Color groupColor = style['color'];
                        final String labelTag = style['tag'];

                        categoricalClusterLayers.add(
                          MarkerClusterLayerWidget(
                            options: MarkerClusterLayerOptions(
                              maxClusterRadius: 160,
                              size: const Size(60, 60),
                              polygonOptions: PolygonOptions(
                                borderColor: groupColor,
                                color: groupColor.withOpacity(0.2),
                                borderStrokeWidth: 2,
                              ),
                              markers: markers,
                              builder: (context, clusterMarkers) {
                                return Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: groupColor.withOpacity(0.9),
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: [
                                      BoxShadow(color: groupColor.withOpacity(0.8), blurRadius: 15, spreadRadius: 5),
                                      BoxShadow(color: groupColor.withOpacity(0.4), blurRadius: 30, spreadRadius: 15),
                                      BoxShadow(color: groupColor.withOpacity(0.2), blurRadius: 45, spreadRadius: 25),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        clusterMarkers.length.toString(),
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      Text(
                                        labelTag,
                                        style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 0.5),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          )
                        );
                      });

                        return Stack(
                          clipBehavior: Clip.none,
                          fit: StackFit.loose,
                          children: categoricalClusterLayers,
                        );
                      },
                  ),

                if (_showSafetyZones)
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: const LatLng(15.42, 73.78), // Mormugao Harbour (Safe Entry)
                        color: Colors.green.withOpacity(0.12),
                        borderStrokeWidth: 1.5,
                        borderColor: Colors.green,
                        useRadiusInMeter: true,
                        radius: 5000,
                      ),
                    ],
                  ),
                
                if (_showFishDensity)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: const LatLng(15.6147, 73.6117), // Chapora PFZ
                        width: 50,
                        height: 50,
                        child: _buildFishMarker('Silver Pomfret (INCOIS)', 'PFZ Depth: 21-26m'),
                      ),
                      Marker(
                        point: const LatLng(15.1947, 73.8386), // Majorde PFZ
                        width: 50,
                        height: 50,
                        child: _buildFishMarker('Kingfish Shoal (INCOIS)', 'PFZ Depth: 16-21m'),
                      ),
                      Marker(
                        point: const LatLng(15.0703, 73.8594), // Cutbona PFZ
                        width: 50,
                        height: 50,
                        child: _buildFishMarker('High Density Zone (INCOIS)', 'PFZ Depth: 18-23m'),
                      ),
                    ],
                  ),

                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution(
                      _isSatellite ? 'Esri World Imagery' : 'OpenStreetMap contributors',
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Unified Premium Sidebar HUD
          Positioned(
            top: 20,
            right: 16,
            child: GlassCard(
              borderRadius: 20,
              blur: 15,
              backgroundColor: Colors.white.withOpacity(0.85),
              borderColor: Colors.grey.withOpacity(0.2),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSidebarToggle(
                    icon: _isSatellite ? Icons.map_outlined : Icons.satellite_alt,
                    label: 'Map Type',
                    isActive: _isSatellite,
                    activeColor: const Color(0xFF06B6D4),
                    onTap: () => setState(() => _isSatellite = !_isSatellite),
                  ),
                  const SizedBox(height: 14),
                  _buildSidebarToggle(
                    icon: Icons.crisis_alert,
                    label: 'Incident Hotspots',
                    isActive: _showHotspots,
                    activeColor: const Color(0xFFEF4444),
                    onTap: () => setState(() => _showHotspots = !_showHotspots),
                  ),
                  const SizedBox(height: 14),
                  _buildSidebarToggle(
                    icon: Icons.security,
                    label: 'Maritime Safety',
                    isActive: _showSafetyZones,
                    activeColor: const Color(0xFF10B981),
                    onTap: () => setState(() => _showSafetyZones = !_showSafetyZones),
                  ),
                  const SizedBox(height: 14),
                  _buildSidebarToggle(
                    icon: Icons.sailing,
                    label: 'Fish Density',
                    isActive: _showFishDensity,
                    activeColor: const Color(0xFF3B82F6),
                    onTap: () => setState(() => _showFishDensity = !_showFishDensity),
                  ),
                ],
              ),
            ),
          ),

          // Coordinate Overlay at Bottom
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: GlassCard(
              borderRadius: 16,
              blur: 12,
              backgroundColor: Colors.white.withOpacity(0.85),
              borderColor: Colors.grey.withOpacity(0.2),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.my_location, size: 16, color: Color(0xFF06B6D4)),
                      const SizedBox(width: 8),
                      Text(
                        _hoveredLatLng != null 
                            ? '${_hoveredLatLng!.latitude.toStringAsFixed(5)}, ${_hoveredLatLng!.longitude.toStringAsFixed(5)}'
                            : 'Generic Zone',
                        style: const TextStyle(
                          fontFamily: 'monospace', 
                          fontWeight: FontWeight.bold, 
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Scale: ', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.black.withOpacity(0.08)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _currentScale,
                            isDense: true,
                            dropdownColor: Colors.white,
                            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 12),
                            icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF06B6D4), size: 18),
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
                        ),
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

  Widget _buildSidebarToggle({
    required IconData icon,
    required String label,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: label,
      textStyle: const TextStyle(color: Colors.white, fontSize: 11),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isActive ? activeColor.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? activeColor.withOpacity(0.3) : Colors.transparent,
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: isActive ? activeColor : const Color(0xFF94A3B8),
            size: 22,
          ),
        ),
      ),
    );
  }

  void _showDetailedComplaint(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) {
        DateTime? date = data['timestamp'] != null ? (data['timestamp'] as Timestamp).toDate() : null;
        String status = data['status'] ?? 'Pending';
        Color statusColor = status == 'Action Taken' ? const Color(0xFF10B981) : (status == 'Dismissed' ? const Color(0xFFEF4444) : const Color(0xFFF59E0B));
        
        return Dialog(
          backgroundColor: Colors.transparent,
          child: OceanGlassCard(
            borderRadius: 20,
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(Icons.description, color: AppColors.primary, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Incident Report Details', 
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(height: 1, color: AppColors.divider),
                  const SizedBox(height: 16),
                  _buildDialogDetailRow('Activity', data['activityType'] ?? 'N/A'),
                  _buildDialogDetailRow('Vessel', data['vesselType'] ?? 'N/A'),
                  _buildDialogDetailRow('Description', data['description'] ?? 'N/A'),
                  _buildDialogDetailRow('Date', date != null ? "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}" : 'Unknown'),
                  Divider(color: AppColors.divider, height: 24),
                  _buildDialogDetailRow('Reporter', data['reporterName'] ?? 'Anonymous'),
                  if (data['isAnonymous'] == true) 
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text('(Submitted Anonymously)', style: TextStyle(fontStyle: FontStyle.italic, color: AppColors.textSecondary, fontSize: 11)),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text('Status: ', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 13)),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: statusColor),
                        ),
                        child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                    ],
                  ),
                  if (data['proofOfAction'] != null && data['proofOfAction'].toString().isNotEmpty) ...[
                    Divider(color: AppColors.divider, height: 24),
                    Text('Proof of Action / Remarks:', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.success, fontSize: 13)),
                    const SizedBox(height: 8),
                    Text(data['proofOfAction'], style: TextStyle(color: AppColors.textPrimary, fontSize: 12, height: 1.4)),
                  ],
                  if (data['acknowledgementMessage'] != null && data['acknowledgementMessage'].toString().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text('Official Feedback:', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.info, fontSize: 13)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(10),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.cardLight, 
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(data['acknowledgementMessage'], style: TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.4)),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Back to Map', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFishMarker(String species, String density) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: OceanGlassCard(
              borderRadius: 20,
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('🐟', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 10),
                      Text('Fish Concentration', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(height: 1, color: AppColors.divider),
                  const SizedBox(height: 16),
                  _buildDialogDetailRow('Species', species),
                  _buildDialogDetailRow('Availability', 'High 📈'),
                  _buildDialogDetailRow('Real-time Insight', density),
                  Divider(color: AppColors.divider, height: 24),
                  Text(
                    'Market Prospect: PREMIUM (Goa Direct)', 
                    style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
      child: PulsingRadarMarker(
        color: const Color(0xFF06B6D4),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.9),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF06B6D4), width: 1.5),
            boxShadow: [BoxShadow(color: const Color(0xFF06B6D4).withOpacity(0.3), blurRadius: 8)],
          ),
          child: const Center(child: Text('🐠', style: TextStyle(fontSize: 18))),
        ),
      ),
    );
  }
}

// Stateful expanding pulse rings widget for coordinates
class PulsingRadarMarker extends StatefulWidget {
  final Color color;
  final Widget child;
  const PulsingRadarMarker({super.key, required this.color, required this.child});

  @override
  State<PulsingRadarMarker> createState() => _PulsingRadarMarkerState();
}

class _PulsingRadarMarkerState extends State<PulsingRadarMarker> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 50 * _controller.value,
                  height: 50 * _controller.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.color.withOpacity(1.0 - _controller.value),
                      width: 1.5,
                    ),
                    color: widget.color.withOpacity(0.12 * (1.0 - _controller.value)),
                  ),
                ),
                Container(
                  width: 80 * _controller.value,
                  height: 80 * _controller.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.color.withOpacity((1.0 - _controller.value) * 0.4),
                      width: 1.0,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        widget.child,
      ],
    );
  }
}
