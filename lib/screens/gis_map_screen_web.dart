import 'package:flutter/material.dart';

class GISMapScreen extends StatelessWidget {
  const GISMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GIS Fisheries Map'),
      ),
      body: const SizedBox.expand(
        child: GISMapWebView(),
      ),
    );
  }
}

class GISMapWebView extends StatelessWidget {
  const GISMapWebView({super.key});

  @override
  Widget build(BuildContext context) {
    return const HtmlElementView(viewType: 'gis-map-leaflet-iframe');
  }
}