import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:convert';

// Conditional imports for web/mobile platforms
import '../src/webview_controller_stub.dart' if (dart.library.html) '../src/webview_controller_web.dart';
import '../src/html_bridge_stub.dart' if (dart.library.html) '../src/html_bridge_web.dart';
import '../widgets/custom_back_button.dart';

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
        ),
      )
      ..loadFlutterAsset('assets/maps/index.html');
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

    _pushMapUpdate();
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
    final lat = _toDouble(source['lat']);
    final lng = _toDouble(source['lng']);
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
      final farms = widget.farms != null && widget.farms!.isNotEmpty
          ? widget.farms!
              .map((farm) => _normalizeFarm(farm))
              .whereType<Map<String, dynamic>>()
              .toList()
          : (await FirebaseFirestore.instance.collection('farms').get()).docs
              .map((doc) => _normalizeFarm(doc.data(), id: doc.id))
              .whereType<Map<String, dynamic>>()
              .toList();

      final complaints = (await FirebaseFirestore.instance.collection('complaints').get()).docs
          .map((doc) => _normalizeComplaint(doc.data(), id: doc.id))
          .whereType<Map<String, dynamic>>()
          .toList();

      final payload = jsonEncode({'farms': farms, 'complaints': complaints});
      _latestPayload = payload;
      _flushLatestPayload();
    } catch (e) {
      debugPrint('Error loading map data: $e');
    }
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
              
              // Process farms with clustering
              if(data.farms && Array.isArray(data.farms)) {
                data.farms.forEach(function(f) {
                  if(f.lat == null || f.lng == null) return;
                  var color = (f.status === 'Active') ? '#22C55E' : 
                             (f.status === 'Pending Approval') ? '#F59E0B' : 
                             (f.status === 'Rejected') ? '#EF4444' : '#9CA3AF';
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
                             '<button onclick="window.location.href=\\'app://farm/' + (f.id || '') + '\\'"; style="margin-top: 8px; padding: 4px 8px; background-color: ' + color + '; color: white; border: none; border-radius: 4px; cursor: pointer;">VIEW DETAILS</button>' +
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
                  
                  // Add to cluster
                  var cm = L.circleMarker([c.lat, c.lng], {
                    radius: 6,
                    color: '#A21CAF',
                    fillColor: '#A21CAF',
                    fillOpacity: 0.85,
                    weight: 2
                  });
                  
                  var popup = '<div style="font-size: 12px; max-width: 200px;">' +
                             '<b style="color: #A21CAF;">Activity: ' + (c.activityType || 'Unknown') + '</b><br/>' + 
                             (c.description || 'No description') + '<br/>' +
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
