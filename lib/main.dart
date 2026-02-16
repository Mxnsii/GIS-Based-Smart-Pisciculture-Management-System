import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/landing_page.dart'; // Step 1: Add this import
import 'theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgriConnect',
      theme: AppTheme.lightTheme,
      // Step 2: Change LoginScreen() to LandingPage()
      home: const LandingPage(), 
      debugShowCheckedModeBanner: false,
    );
  }
}