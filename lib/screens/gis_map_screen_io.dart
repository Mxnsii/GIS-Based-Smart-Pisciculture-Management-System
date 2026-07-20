import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class GISMapScreen extends StatefulWidget {
  const GISMapScreen({super.key});

  @override
  State<GISMapScreen> createState() => _GISMapScreenState();
}

class _GISMapScreenState extends State<GISMapScreen> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadFlutterAsset('assets/maps/index.html');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GIS Fisheries Map'),
      ),
      body: WebViewWidget(
        controller: controller,
      ),
    );
  }
}