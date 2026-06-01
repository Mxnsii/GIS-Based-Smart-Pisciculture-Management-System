import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:convert';

// Conditional imports for web/mobile platforms
import '../src/webview_controller_web.dart' if (dart.library.html) '../src/webview_controller_stub.dart';
import '../src/html_bridge_stub.dart' if (dart.library.html) '../src/html_bridge_web.dart';
import '../widgets/custom_back_button.dart';
import 'farm_details_screen.dart';

class GisMapView extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;
  final double initialZoom;
  final List<Map<String, dynamic>>? farms;
  final bool isAuthority;
  final bool showBackButton;

  const GisMapView({
    super.key,
    this.initialLat,
    this.initialLng,
    this.initialZoom = 12.0,
    this.farms,
    this.showBackButton = true,
    this.isAuthority = false,
  });

  @override
  State<GisMapView> createState() => _GisMapViewState();
}

class _GisMapViewState extends State<GisMapView> {
  WebViewController? _webViewController;
  bool _isMapLoaded = false;
  StreamSubscription<QuerySnapshot>? _farmsSubscription;
  StreamSubscription<QuerySnapshot>? _complaintsSubscription;
  String? _latestPayload;
  bool _hasStartedSync = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _initializeWebViewController();
    } else {
      // On web, start syncing once the iframe view is inserted.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startRealtimeMapSync();
      });
    }
  }

  @override
  void dispose() {
    _farmsSubscription?.cancel();
    _complaintsSubscription?.cancel();
    super.dispose();
  }

  void _initializeWebViewController() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            debugPrint('GIS Map: Page started loading: $url');
          },
          onPageFinished: (String url) {
            debugPrint('GIS Map: Page finished loading');
            setState(() {
              _isMapLoaded = true;
            });
            _startRealtimeMapSync();
            _flushLatestPayload();
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('GIS Map: Web resource error: ${error.description}');
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('https://app.farm/')) {
              final id = request.url.replaceFirst('https://app.farm/', '');
              _openFarmDetails(id);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadFlutterAsset('assets/maps/index.html');
  }

  void _openFarmDetails(String id) {
    // 1. Fallback to local mock farms first
    final mockFarm = _mockFarms.firstWhere(
      (f) => f['id'] == id,
      orElse: () => <String, dynamic>{}
    );
    if (mockFarm.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => FarmDetailsScreen(farmData: mockFarm, isAuthority: widget.isAuthority))
      );
      return;
    }

    // 2. Query Firestore
    FirebaseFirestore.instance.collection('farms').doc(id).get().then((doc) {
      if (doc.exists && mounted) {
        final farmData = Map<String, dynamic>.from(doc.data() ?? {});
        farmData['id'] = doc.id;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => FarmDetailsScreen(farmData: farmData, isAuthority: widget.isAuthority))
        );
      }
    });
  }

  void _startRealtimeMapSync() {
    if (_hasStartedSync) {
      return;
    }
    _hasStartedSync = true;

    if (widget.farms == null || widget.farms!.isEmpty) {
      _farmsSubscription = FirebaseFirestore.instance.collection('farms').snapshots().listen((_) {
        _pushMapUpdate();
      });
    }

    _complaintsSubscription = FirebaseFirestore.instance.collection('complaints').snapshots().listen((_) {
      _pushMapUpdate();
    });

    if (kIsWeb) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        _pushMapUpdate();
      });
    } else {
      _pushMapUpdate();
    }
  }

  double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  Map<String, dynamic>? _normalizeFarm(Map<String, dynamic> source, {String? id}) {
    double? lat = _toDouble(source['lat']) ?? _toDouble(source['latitude']);
    double? lng = _toDouble(source['lng']) ?? _toDouble(source['longitude']);

    final location = source['location'];
    if ((lat == null || lng == null) && location is GeoPoint) {
      lat = location.latitude;
      lng = location.longitude;
    }

    // Try finding latitude/longitude in nested map location if any
    if ((lat == null || lng == null) && location is Map) {
      lat = _toDouble(location['lat']) ?? _toDouble(location['latitude']);
      lng = _toDouble(location['lng']) ?? _toDouble(location['longitude']);
    }

    if (lat == null || lng == null) {
      return null;
    }

    final farm = Map<String, dynamic>.from(source);
    if (id != null) {
      farm['id'] = id;
    }
    farm['lat'] = lat;
    farm['lng'] = lng;
    return farm;
  }

  Map<String, dynamic>? _normalizeComplaint(Map<String, dynamic> source, {String? id}) {
    double? lat = _toDouble(source['lat']);
    double? lng = _toDouble(source['lng']);

    final location = source['location'];
    if ((lat == null || lng == null) && location is GeoPoint) {
      lat = location.latitude;
      lng = location.longitude;
    }

    if (lat == null || lng == null) {
      return null;
    }

    final complaint = Map<String, dynamic>.from(source);
    if (id != null) {
      complaint['id'] = id;
    }
    complaint['lat'] = lat;
    complaint['lng'] = lng;
    return complaint;
  }

  Future<void> _pushMapUpdate() async {
    try {
      List<Map<String, dynamic>> farms = [];
      if (widget.farms != null && widget.farms!.isNotEmpty) {
        farms = widget.farms!
            .map((farm) => _normalizeFarm(farm))
            .whereType<Map<String, dynamic>>()
            .toList();
      } else {
        // Query from Firestore
        final firestoreFarms = (await FirebaseFirestore.instance.collection('farms').get()).docs
            .map((doc) => _normalizeFarm(doc.data(), id: doc.id))
            .whereType<Map<String, dynamic>>()
            .toList();
            
        // Combine Firestore farms with mock farms, avoiding duplicates
        final combined = List<Map<String, dynamic>>.from(_mockFarms);
        for (var f in firestoreFarms) {
          if (!combined.any((m) => m['id'] == f['id'])) {
            combined.insert(0, f);
          }
        }
        farms = combined.map((farm) => _normalizeFarm(farm)).whereType<Map<String, dynamic>>().toList();
      }

      final complaints = (await FirebaseFirestore.instance.collection('complaints').get()).docs
          .map((doc) => _normalizeComplaint(doc.data(), id: doc.id))
          .whereType<Map<String, dynamic>>()
          .toList();

      final sanitizedFarms = farms.map((f) => _sanitizeMapForJson(f)).toList();
      final sanitizedComplaints = complaints.map((c) => _sanitizeMapForJson(c)).toList();

      final payload = jsonEncode({
        'farms': sanitizedFarms, 
        'complaints': sanitizedComplaints,
        if (widget.initialLat != null) 'initialLat': widget.initialLat,
        if (widget.initialLng != null) 'initialLng': widget.initialLng,
        'initialZoom': widget.initialZoom,
      });
      _latestPayload = payload;
      _flushLatestPayload();
    } catch (e) {
      debugPrint('Error loading map data: $e');
    }
  }

  Map<String, dynamic> _sanitizeMapForJson(Map<String, dynamic> source) {
    final sanitized = <String, dynamic>{};
    source.forEach((key, value) {
      if (value == null) {
        sanitized[key] = null;
        return;
      }

      bool handled = false;
      try {
        final date = (value as dynamic).toDate();
        if (date != null) {
          if (date is DateTime) {
            sanitized[key] = date.toIso8601String();
            handled = true;
          } else {
            sanitized[key] = DateTime.parse(date.toString()).toIso8601String();
            handled = true;
          }
        }
      } catch (_) {}

      if (handled) return;

      try {
        final double? latitude = _toDouble((value as dynamic).latitude);
        final double? longitude = _toDouble((value as dynamic).longitude);
        if (latitude != null && longitude != null) {
          sanitized[key] = {
            'latitude': latitude,
            'longitude': longitude,
          };
          handled = true;
        }
      } catch (_) {}

      if (handled) return;

      if (value is GeoPoint) {
        sanitized[key] = {
          'latitude': value.latitude,
          'longitude': value.longitude,
        };
      } else if (value is Timestamp) {
        sanitized[key] = value.toDate().toIso8601String();
      } else if (value is DateTime) {
        sanitized[key] = value.toIso8601String();
      } else if (value is Map) {
        sanitized[key] = _sanitizeMapForJson(Map<String, dynamic>.from(value));
      } else if (value is List) {
        sanitized[key] = value.map((item) {
          if (item == null) return null;

          try {
            final date = (item as dynamic).toDate();
            if (date != null) {
              if (date is DateTime) {
                return date.toIso8601String();
              } else {
                return DateTime.parse(date.toString()).toIso8601String();
              }
            }
          } catch (_) {}

          try {
            final double? lat = _toDouble((item as dynamic).latitude);
            final double? lng = _toDouble((item as dynamic).longitude);
            if (lat != null && lng != null) {
              return {'latitude': lat, 'longitude': lng};
            }
          } catch (_) {}

          if (item is GeoPoint) {
            return {'latitude': item.latitude, 'longitude': item.longitude};
          } else if (item is Timestamp) {
            return item.toDate().toIso8601String();
          } else if (item is DateTime) {
            return item.toIso8601String();
          } else if (item is Map) {
            return _sanitizeMapForJson(Map<String, dynamic>.from(item));
          }
          return item;
        }).toList();
      } else {
        sanitized[key] = value;
      }
    });
    return sanitized;
  }

  void _flushLatestPayload() {
    final payload = _latestPayload;
    if (payload == null) {
      return;
    }

    if (kIsWeb) {
      postMessageToIframe(payload);
      return;
    }

    if (_webViewController == null || !_isMapLoaded) {
      return;
    }

    final escapedPayload = payload.replaceAll('\\', '\\\\').replaceAll('"', '\\"');
    final js = '''
          (function() {
            try {
              if(!window.farmClusterGroup || !window.complaintHeatLayer || !window.complaintMarkerGroup) {
                console.warn('GIS layers are not ready yet.');
                return;
              }

              window.farmClusterGroup.clearLayers();
              window.complaintMarkerGroup.clearLayers();
              window.complaintHeatLayer.clearLayers();
              
              var data = JSON.parse("$escapedPayload");
              
              // Center and zoom map if specified
              if (data.initialLat != null && data.initialLng != null) {
                map.setView([data.initialLat, data.initialLng], data.initialZoom || 16);
              }
              
              // Process farms with clustering
              if(data.farms && Array.isArray(data.farms)) {
                data.farms.forEach(function(f) {
                  if(f.lat == null || f.lng == null) return;
                   var color = (f.status === 'Active') ? '#22C55E' : 
                              (f.status === 'Pending Approval' || f.status === 'Pending') ? '#F59E0B' : 
                              (f.status === 'Rejected') ? '#EF4444' : 
                              (f.status === 'Inactive') ? '#9CA3AF' : '#9CA3AF';
                  var m = L.circleMarker([f.lat, f.lng], {
                    radius: 7,
                    color: color,
                    fillColor: color,
                    fillOpacity: 0.9,
                    weight: 2
                  });
                  
                  var popup = '<div style="font-size: 12px; max-width: 200px;">' +
                             '<strong style="color: ' + color + ';">' + (f.name || 'Farm') + '</strong><br/>' + 
                             '<small>Owner: ' + (f.owner || '') + '</small><br/>' +
                             '<small>Status: ' + (f.status || '') + '</small><br/>' +
                             '<small><b>Coordinates:</b> (' + f.lat.toFixed(5) + ', ' + f.lng.toFixed(5) + ')</small><br/>' +
                             '<button onclick="window.location.href=\\'https://app.farm/' + (f.id || '') + '\\'" style="margin-top: 8px; padding: 4px 8px; background-color: ' + color + '; color: white; border: none; border-radius: 4px; cursor: pointer;">VIEW DETAILS</button>' +
                             '</div>';
                  m.bindPopup(popup);
                  window.farmClusterGroup.addLayer(m);
                });
              }
              
              // Process complaints with heatmap + clustering
              if(data.complaints && Array.isArray(data.complaints)) {
                var complaintHeatData = [];
                data.complaints.forEach(function(c) {
                  if(c.lat == null || c.lng == null) return;
                  
                  // Add to heatmap
                  complaintHeatData.push([c.lat, c.lng, 0.8]);
                  
                  // Add to cluster with premium glowing single icon
                  var cm = L.marker([c.lat, c.lng], {
                    icon: L.divIcon({
                      html: '<div style="background-color: #E11D48; color: white; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 11px; font-weight: 800; border: 2px solid white; box-shadow: 0 0 10px rgba(225, 29, 72, 0.8), 0 0 15px rgba(225, 29, 72, 0.5); width: 22px; height: 22px; animation: pulse 2.5s infinite alternate;">🚨</div>',
                      iconSize: [22, 22],
                      className: 'custom-complaint-single-marker'
                    })
                  });
                  
                  var imgTag = '';
                  if (c.imageUrl) {
                    imgTag = '<div style="margin-top: 8px; margin-bottom: 8px; border-radius: 4px; overflow: hidden; border: 1px solid #E2E8F0;">' +
                             '<img src="' + c.imageUrl + '" style="width: 100%; max-height: 120px; object-fit: cover; display: block;" alt="Complaint Evidence"/>' +
                             '</div>';
                  }
                  
                  var popup = '<div style="font-size: 12px; max-width: 200px;">' +
                             '<b style="color: #E11D48;">Activity: ' + (c.activityType || 'Unknown') + '</b><br/>' + 
                             (c.description || 'No description') + '<br/>' +
                             imgTag +
                             '<small><i>Location: (' + c.lat.toFixed(4) + ', ' + c.lng.toFixed(4) + ')</i></small>' +
                             '</div>';
                  cm.bindPopup(popup);
                  window.complaintMarkerGroup.addLayer(cm);
                });
                
                // Add heatmap visualization
                if(complaintHeatData.length > 0) {
                  var heatLayer = L.heatLayer(complaintHeatData, {
                    radius: 25,
                    blur: 15,
                    maxZoom: 13,
                    gradient: {
                      0.0: '#0000FF',
                      0.4: '#00FF00',
                      0.6: '#FFFF00',
                      1.0: '#FF0000'
                    }
                  }).addTo(window.complaintHeatLayer);
                }
              }
            } catch (e) {
              console.error('Error injecting markers:', e);
            }
          })();
        ''';

          _webViewController!.runJavaScript(js);
  }

  @override
  Widget build(BuildContext context) {
    // On web, use iframe fallback
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('GIS Map - Aquaculture Management'),
          backgroundColor: Colors.blueGrey.shade900,
          leading: widget.showBackButton ? CustomBackButton(onPressed: () => Navigator.pop(context)) : null,
          elevation: 0,
        ),
        body: const GisMapWebViewWidget(),
      );
    }

    // On mobile/desktop, use WebView
    if (_webViewController == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('GIS Map - Aquaculture Management'),
          backgroundColor: Colors.blueGrey.shade900,
          leading: widget.showBackButton ? CustomBackButton(onPressed: () => Navigator.pop(context)) : null,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('GIS Map - Aquaculture Management'),
        backgroundColor: Colors.blueGrey.shade900,
        leading: widget.showBackButton ? CustomBackButton(onPressed: () => Navigator.pop(context)) : null,
        actions: [
          if (!_isMapLoaded)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
        elevation: 0,
      ),
      body: WebViewWidget(controller: _webViewController!),
      floatingActionButton: _isMapLoaded
          ? FloatingActionButton(
              onPressed: () {
                _webViewController!.reload();
              },
              backgroundColor: Colors.blueGrey.shade900,
              child: const Icon(Icons.refresh),
            )
          : null,
    );
  }
}

// Web/iframe fallback widget
class GisMapWebViewWidget extends StatelessWidget {
  const GisMapWebViewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: 'gis-map-leaflet-iframe');
  }
}

// Static mock farms fallback database
final List<Map<String, dynamic>> _mockFarms = const [
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
    "revenueEst": "₹ 12,0,000",
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
      "Land Ownership": "Disputed",
      "Pollution Cert": "Pending",
      "Bank Details": "Verified",
      "ID Proof": "Verified"
    },
    "productivity": "N/A",
    "mortalityRate": "N/A",
    "sustainabilityScore": "20/100",
    "inspector": "Official #42",
    "inspectionDate": "2024-01-20",
    "remarks": "Land use mismatch. Industrial zone not improved for aquaculture.",
    "approvalTime": "N/A",
    "rejectionReason": "Land Use Violation",
  }
];
