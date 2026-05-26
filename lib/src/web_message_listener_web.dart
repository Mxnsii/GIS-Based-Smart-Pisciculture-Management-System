import 'dart:html' as html;
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/farm_details_screen.dart';

void registerMessageListener(GlobalKey<NavigatorState> navigatorKey) {
  html.window.addEventListener('message', (event) {
    try {
      final data = event is html.MessageEvent ? event.data : null;
      final parsed = (data is String) ? (data.isNotEmpty ? jsonDecode(data) : null) : data;
      if (parsed != null && parsed['type'] == 'openFarm') {
        final id = parsed['id'];
        if (id != null && navigatorKey.currentState != null) {
          // Fetch farm data from Firestore and navigate
          FirebaseFirestore.instance.collection('farms').doc(id).get().then((doc) {
            if (doc.exists) {
              final farmData = Map<String, dynamic>.from(doc.data() ?? {});
              farmData['id'] = doc.id;
              navigatorKey.currentState!.push(
                MaterialPageRoute(builder: (_) => FarmDetailsScreen(farmData: farmData))
              );
            }
          });
        }
      }
    } catch (e) {
      // ignore
    }
  });
}
