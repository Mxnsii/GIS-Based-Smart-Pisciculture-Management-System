import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

// Conditional import for posting messages to iframe on web
import '../src/html_bridge_stub.dart' if (dart.library.html) '../src/html_bridge_web.dart';
import '../widgets/custom_back_button.dart';
import 'gis_map_web_view_web.dart' if (dart.library.html) 'gis_map_web_view_web.dart';

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
  late WebViewController _webViewController;
  bool _isMapLoaded = false;

  @override
  void initState() {
    super.initState();
    _initializeWebViewController();
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
            // Load farm and complaint data from Firestore then send to map
            _loadAndSendMapData();
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('GIS Map: Web resource error: ${error.description}');
          },
        ),
      )
      ..loadFlutterAsset('assets/maps/index.html');
  }

  Future<void> _loadAndSendMapData() async {
    try {
      // Fetch farms
      final farmsSnapshot = await FirebaseFirestore.instance.collection('farms').get();
      final farms = farmsSnapshot.docs.map((d) {
        final data = Map<String, dynamic>.from(d.data());
        data['id'] = d.id;
        // Ensure numeric lat/lng
        data['lat'] = (data['lat'] is String) ? double.tryParse(data['lat']) ?? 0.0 : (data['lat'] ?? 0.0);
        data['lng'] = (data['lng'] is String) ? double.tryParse(data['lng']) ?? 0.0 : (data['lng'] ?? 0.0);
        return data;
      }).toList();

      // Fetch complaints (hotspots)
      final compSnapshot = await FirebaseFirestore.instance.collection('complaints').get();
      final complaints = compSnapshot.docs.map((d) {
        final data = Map<String, dynamic>.from(d.data());
        data['id'] = d.id;
        data['lat'] = (data['lat'] is String) ? double.tryParse(data['lat']) ?? 0.0 : (data['lat'] ?? 0.0);
        data['lng'] = (data['lng'] is String) ? double.tryParse(data['lng']) ?? 0.0 : (data['lng'] ?? 0.0);
        return data;
      }).toList();

      final payload = jsonEncode({'farms': farms, 'complaints': complaints});

      if (kIsWeb) {
        // Post message to iframe
        postMessageToIframe(payload);
      } else {
        // Inject JS to add markers into the Leaflet map inside WebView
        final js = "(function(){
          try{var data = JSON.parse('" + payload.replaceAll("'", "\\'") + "');
          if(!window.flutterMarkersLayer){ window.flutterMarkersLayer = L.layerGroup().addTo(map); }
          window.flutterMarkersLayer.clearLayers();
          data.farms.forEach(function(f){
            if(!f.lat || !f.lng) return;
            var color = (f.status === 'Active')? 'green' : (f.status === 'Pending Approval'? 'orange' : (f.status === 'Rejected'? 'red' : 'gray'));
            var m = L.circleMarker([f.lat, f.lng], {radius:7, color: color, fillColor: color, fillOpacity:0.9}).addTo(window.flutterMarkersLayer);
            var popup = '<div><strong>' + (f.name||'') + '</strong><br/>' + (f.owner||'') + '<br/><small>' + (f.status||'') + '</small><br/><button onclick="window.location.href=\'app://farm/' + (f.id||'') + '\'">VIEW MORE DETAILS</button></div>';
            m.bindPopup(popup);
          });
          // complaints as red small markers
          if(!window.flutterComplaintsLayer){ window.flutterComplaintsLayer = L.layerGroup().addTo(map); }
          window.flutterComplaintsLayer.clearLayers();
          data.complaints.forEach(function(c){ if(!c.lat||!c.lng) return; var cm = L.circleMarker([c.lat,c.lng],{radius:6, color:'purple', fillColor:'purple', fillOpacity:0.8}).addTo(window.flutterComplaintsLayer); cm.bindPopup('<b>Activity:</b> '+(c.activityType||'') + '<br/>' + (c.description||'')); });
          }catch(e){console.error(e);}
        })();";

        await _webViewController.runJavaScript(js);
      }
    } catch (e) {
      debugPrint('Error loading map data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // On web, use iframe fallback
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('GIS Map - Aquaculture Management'),
          backgroundColor: Colors.blueGrey.shade900,
          leading: widget.showBackButton ? const CustomBackButton() : null,
          elevation: 0,
        ),
        body: const GisMapWebViewWidget(),
      );
    }

    // On mobile/desktop, use WebView
    return Scaffold(
      appBar: AppBar(
        title: const Text('GIS Map - Aquaculture Management'),
        backgroundColor: Colors.blueGrey.shade900,
        leading: widget.showBackButton ? const CustomBackButton() : null,
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
      body: WebViewWidget(controller: _webViewController),
      floatingActionButton: _isMapLoaded
          ? FloatingActionButton(
              onPressed: () {
                _webViewController.reload();
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
