// Stub for web platforms - provides dummy WebViewController
// On web, we use HtmlElementView instead of WebViewWidget

import 'package:flutter/material.dart';

class WebViewController {
  void setJavaScriptMode(dynamic mode) {}

  void setNavigationDelegate(dynamic delegate) {}

  Future<void> loadFlutterAsset(String path) async {}

  Future<void> runJavaScript(String js) async {}

  Future<void> reload() async {}
}

enum JavaScriptMode { unrestricted, restricted }

class NavigationDelegate {
  NavigationDelegate({
    this.onPageStarted,
    this.onPageFinished,
    this.onWebResourceError,
  });

  final void Function(String)? onPageStarted;
  final void Function(String)? onPageFinished;
  final void Function(dynamic)? onWebResourceError;
}

class WebResourceError {
  WebResourceError({required this.description});
  final String description;
}

class WebViewWidget extends StatelessWidget {
  const WebViewWidget({required this.controller});
  final WebViewController controller;

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
