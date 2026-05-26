import 'package:flutter/material.dart';
import 'gis_map_web_view_web.dart';

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