import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/landing_page.dart'; // Your landing page
import 'theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // Add this at the top for kIsWeb

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    if (!kIsWeb) {
      // Background notifications and manual topic subscriptions are 
      // strictly reserved for native Android/iOS mobile environments
      await messaging.subscribeToTopic('farmer_alerts');
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    }

  } catch (e) {
    debugPrint("Firebase init error: $e");
  }

  try {
    await NotificationService.init();
  } catch (e) {
    debugPrint("Notification init error: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgriConnect',
      theme: AppTheme.lightTheme.copyWith(
        textTheme: GoogleFonts.latoTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      home: const LandingPage(), // Show Landing Page as home
      debugShowCheckedModeBanner: false,
    );
  }
}