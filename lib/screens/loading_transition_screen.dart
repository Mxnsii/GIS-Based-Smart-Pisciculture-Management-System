import 'dart:async';
import 'package:flutter/material.dart';

class LoadingTransitionScreen extends StatefulWidget {
  final Widget targetPage;
  final String message;

  const LoadingTransitionScreen({
    super.key,
    required this.targetPage,
    this.message = 'Sychronizing Data...',
  });

  @override
  State<LoadingTransitionScreen> createState() => _LoadingTransitionScreenState();
}

class _LoadingTransitionScreenState extends State<LoadingTransitionScreen> {
  @override
  void initState() {
    super.initState();
    // Simulate a 2-second loading time for the beautiful GIF transition
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => widget.targetPage),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Using the loader.gif provided in assets/images/
            Image.asset(
              'assets/images/loader.gif',
              width: 280,
              height: 280,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            Text(
              widget.message.toUpperCase(),
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
