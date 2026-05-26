import 'dart:html' as html;
import 'package:flutter/widgets.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../screens/farm_details_screen.dart';

void registerMessageListener(GlobalKey<NavigatorState> navigatorKey) {
  html.window.addEventListener('message', (event) {
    try {
      final data = event is html.MessageEvent ? event.data : null;
      final parsed = (data is String) ? (data.isNotEmpty ? jsonDecode(data) : null) : data;
      if (parsed != null && parsed['type'] == 'openFarm') {
        final id = parsed['id'];
        if (id != null && navigatorKey.currentState != null) {
          navigatorKey.currentState!.push(MaterialPageRoute(builder: (_) => FarmDetailsScreen(farmId: id)));
        }
      }
    } catch (e) {
      // ignore
    }
  });
}
