import 'package:flutter/material.dart';
import 'dart:math' as math;

/// A subtle, full-screen background widget that animates floating bubbles
/// upwards to create a calming, underwater/aquarium aesthetic.
class FloatingBubblesBackground extends StatefulWidget {
  final Widget child;
  final int bubbleCount;
  final Color? bubbleColor;

  const FloatingBubblesBackground({
    super.key,
    required this.child,
    this.bubbleCount = 15,
    this.bubbleColor,
  });

  @override
  State<FloatingBubblesBackground> createState() => _FloatingBubblesBackgroundState();
}

class _FloatingBubblesBackgroundState extends State<FloatingBubblesBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Bubble> _bubbles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Initialize bubbles with random positions, speeds, and sizes
    for (int i = 0; i < widget.bubbleCount; i++) {
      _bubbles.add(_Bubble(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        speed: 0.05 + _random.nextDouble() * 0.1,
        radius: 2 + _random.nextDouble() * 12,
        wobbleSpeed: 1 + _random.nextDouble() * 3,
        wobbleAmp: 0.01 + _random.nextDouble() * 0.03,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _BubblePainter(
                  bubbles: _bubbles,
                  progress: _controller.value,
                  color: widget.bubbleColor ?? const Color(0xFF00BCD4).withOpacity(0.15),
                ),
              );
            },
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _Bubble {
  double x;
  double y;
  double speed;
  double radius;
  double wobbleSpeed;
  double wobbleAmp;

  _Bubble({
    required this.x,
    required this.y,
    required this.speed,
    required this.radius,
    required this.wobbleSpeed,
    required this.wobbleAmp,
  });
}

class _BubblePainter extends CustomPainter {
  final List<_Bubble> bubbles;
  final double progress;
  final Color color;

  _BubblePainter({required this.bubbles, required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (var b in bubbles) {
      // Calculate current Y position (moving up)
      double currentY = b.y - (progress * b.speed * 10);
      // Wrap around if it goes off top
      currentY = currentY % 1.0;
      if (currentY < 0) currentY += 1.0;

      // Add wobble to X
      double currentX = b.x + math.sin(progress * math.pi * 2 * b.wobbleSpeed) * b.wobbleAmp;

      canvas.drawCircle(
        Offset(currentX * size.width, currentY * size.height),
        b.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BubblePainter old) => true;
}
