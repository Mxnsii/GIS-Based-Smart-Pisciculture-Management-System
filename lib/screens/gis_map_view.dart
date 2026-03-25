import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;
import 'farm_details_screen.dart';
import '../widgets/custom_back_button.dart';
import '../services/gis_service.dart'; // Import the service
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';

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

  // Mock Data (Synchronized with Farm Registry) - [Keep existing _defaultFarms list]
  final List<Map<String, dynamic>> _defaultFarms = [
    // ... [Keep existing farms data as is] ...
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
      "riskStatus": "Critical", // Offline
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
        return Colors.green;
      case 'Pending Approval':
        return Colors.orange;
      case 'Inactive':
        return Colors.grey;
      case 'Rejected':
        return Colors.red;
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

  Widget _buildMarkerLayer(List<Map<String, dynamic>> farmsToShow) {
    return MarkerLayer(
      markers: farmsToShow.map((farm) {
        // Handle parsing logic defensively since Firebase might send strings
        double lat = 15.0;
        double lng = 73.0;
        if (farm['lat'] != null) {
          lat = farm['lat'] is String ? double.tryParse(farm['lat']) ?? 15.0 : farm['lat'].toDouble();
        }
        if (farm['lng'] != null) {
          lng = farm['lng'] is String ? double.tryParse(farm['lng']) ?? 73.0 : farm['lng'].toDouble();
        }

        return Marker(
          point: LatLng(lat, lng),
          width: 80,
          height: 80,
          child: GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(farm['name'] ?? 'Unknown Farm'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Owner: ${farm['owner'] ?? 'Unknown'}'),
                      const SizedBox(height: 8),
                      Text('Status: ${farm['status'] ?? 'Unknown'}'),
                      const SizedBox(height: 8),
                      Text('Lat: $lat, Lng: $lng', style: const TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
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
                        child: const Text('VIEW MORE DETAILS'),
                      ),
                  ],
                ),
              );
            },
            child: Tooltip(
              message: '${farm['name']}\nLat: $lat, Lng: $lng',
              child: Icon(
                Icons.location_on,
                color: _getStatusColor(farm['status'] ?? 'Unknown'),
                size: 40,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine center: use passed arguments if available, otherwise default
    final LatLng center = (widget.initialLat != null && widget.initialLng != null)
        ? LatLng(widget.initialLat!, widget.initialLng!)
        : const LatLng(15.4989, 73.8278);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('GIS Map View'),
        // Only show back button if pushed (which happens when selecting coordinates)
        leadingWidth: 80, // Allow more width for text
        leading: widget.showBackButton && Navigator.canPop(context) 
          ? CustomBackButton(
              onPressed: () => Navigator.pop(context),
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
                  urlTemplate: _isSatellite 
                      ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                      : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.agriconnect.app',
                ),
                // Hybrid Labels Overlay (Only for Satellite)
                if (_isSatellite)
                  TileLayer(
                    urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/Reference/World_Boundaries_and_Places/MapServer/tile/{z}/{y}/{x}',
                    userAgentPackageName: 'com.agriconnect.app',
                    backgroundColor: Colors.transparent, // Ensure transparency
                  ),
                // NEW: Polygon Layer for QGIS Import
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
                    stream: FirebaseFirestore.instance.collection('complaints').snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();
                      
                      // 1. Group similar suspicious activities
                      Map<String, List<Marker>> groupedMarkers = {};

                      for (var doc in snapshot.data!.docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        if (data['location'] != null && data['location'] is GeoPoint) {
                          final point = data['location'] as GeoPoint;
                          
                          // Extract attributes
                          String rawActivity = (data['activityType'] ?? '').toString().toLowerCase();
                          String activity = 'Unknown';
                          bool isAIHotspot = false; 
                          
                          if (data['aiAnalysis'] != null) {
                            if (data['aiAnalysis']['category'] != null && data['aiAnalysis']['isMock'] != true) {
                              activity = data['aiAnalysis']['category'].toString();
                            }
                            isAIHotspot = data['aiAnalysis']['isHotspot'] == true;
                          }
                          
                          if (activity == 'Unknown') {
                            if (rawActivity.contains('fishing') || rawActivity.contains('net') || rawActivity.contains('trawl') || rawActivity.contains('dynamite')) {
                              activity = 'Suspicious Fishing Activity';
                            } else if (rawActivity.contains('trash') || rawActivity.contains('oil') || rawActivity.contains('dump') || rawActivity.contains('wastewater')) {
                              activity = 'Pollution / Environmental Hazard';
                            } else {
                              activity = data['activityType'] ?? 'Other Incident';
                            }
                          }
                          
                          final marker = Marker(
                            point: LatLng(point.latitude, point.longitude),
                            width: 50,
                            height: 50,
                            child: GestureDetector(
                              onTap: () {
                                 showDialog(
                                   context: context,
                                   builder: (context) => AlertDialog(
                                      title: const Text('Incident Report', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text.rich(
                                            TextSpan(
                                              children: [
                                                const TextSpan(text: 'Activity: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                                TextSpan(text: '${data['activityType']}'),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text.rich(
                                            TextSpan(
                                              children: [
                                                const TextSpan(text: 'Vessel: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                                TextSpan(text: '${data['vesselType']}'),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          if (data['aiAnalysis'] != null)
                                             Text('Priority: ${data['aiAnalysis']['priority']}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                        ]
                                      ),
                                      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))]
                                   )
                                 );
                              },
                              child: Icon(Icons.warning, color: isAIHotspot ? Colors.red : Colors.orange, size: 30),
                            )
                          );
                          
                          groupedMarkers.putIfAbsent(activity, () => []).add(marker);
                        }
                      }

                      // 2. Build clustered hotspots per Activity Group based on spatial proximity
                      List<Widget> categoricalClusterLayers = [];
                      
                      List<Color> palette = [Colors.red, Colors.deepPurple, Colors.blue, Colors.orange, Colors.teal];
                      int colorIndex = 0;

                      groupedMarkers.forEach((activityName, markers) {
                        final Color groupColor = palette[colorIndex % palette.length];
                        colorIndex++;

                        // Get first letters for the icon (e.g. 'Suspicious Fishing' -> 'SF')
                        String labelTag = activityName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join('').toUpperCase();

                        categoricalClusterLayers.add(
                          MarkerClusterLayerWidget(
                            options: MarkerClusterLayerOptions(
                              maxClusterRadius: 160, // Increased radius to club more localized activities into unified hotspots
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
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                                      ),
                                      Text(
                                        labelTag,
                                        style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          )
                        );
                      });

                        // Return the UI Clusters
                        return Stack(
                          clipBehavior: Clip.none,
                          fit: StackFit.loose,
                          children: categoricalClusterLayers,
                        );
                      },
                  ),

                 // Attribution
                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution(
                      _isSatellite ? 'Esri World Imagery' : 'OpenStreetMap contributors',
                      onTap: () {}, // No-op
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Layer Switcher
          Positioned(
            top: 20,
            right: 20,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  setState(() {
                    _isSatellite = !_isSatellite;
                  });
                },
                child: Container(
                  width: 65,
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isSatellite ? Icons.map_outlined : Icons.satellite_alt,
                        color: Colors.blue.shade900,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isSatellite ? 'Street' : 'Satellite',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Hotspots Toggle Switcher
          Positioned(
            top: 90,
            right: 20,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  setState(() {
                    _showHotspots = !_showHotspots;
                  });
                },
                child: Container(
                  width: 65,
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.crisis_alert,
                        color: _showHotspots ? Colors.red : Colors.grey,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Hotspots',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _showHotspots ? Colors.red : Colors.grey.shade800),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Coordinate Overlay at Bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              color: Colors.white.withOpacity(0.9),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                        const Icon(Icons.my_location, size: 16, color: Colors.blueGrey),
                        const SizedBox(width: 8),
                         Text(
                            _hoveredLatLng != null 
                                ? '${_hoveredLatLng!.latitude.toStringAsFixed(5)}, ${_hoveredLatLng!.longitude.toStringAsFixed(5)}'
                                : 'Generic Zone', // More "GIS" like
                            style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                    ],
                  ),
                 
                  // Dynamic Scale Dropdown
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Scale: ', style: TextStyle(color: Colors.black, fontSize: 13)),
                      const SizedBox(width: 4),
                      DropdownButton<String>(
                        value: _currentScale,
                        isDense: true,
                        underline: Container(), // Remove default underline
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
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
