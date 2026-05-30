import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';

/// An animated wave header that paints 2 overlapping sine waves 
/// to create a fluid, oceanic top header effect.
class AnimatedWaveHeader extends StatefulWidget {
  final double height;
  final Widget? child;
  final bool showWaves;
  
  const AnimatedWaveHeader({
    super.key,
    this.height = 160.0,
    this.child,
    this.showWaves = false,
  });

  @override
  State<AnimatedWaveHeader> createState() => _AnimatedWaveHeaderState();
}

class _AnimatedWaveHeaderState extends State<AnimatedWaveHeader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    if (widget.showWaves) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(AnimatedWaveHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showWaves != oldWidget.showWaves) {
      if (widget.showWaves) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: Stack(
        children: [
          // The animated waves
          if (widget.showWaves)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return CustomPaint(
                  painter: _WavePainter(
                    animationValue: _controller.value,
                    color1: AppColors.primary.withOpacity(0.8),
                    color2: AppColors.secondary.withOpacity(0.4),
                  ),
                  size: Size(double.infinity, widget.height),
                );
              },
            ),
          // Header content on top
          if (widget.child != null)
            widget.child!,
        ],
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double animationValue;
  final Color color1;
  final Color color2;

  _WavePainter({
    required this.animationValue,
    required this.color1,
    required this.color2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = color1
      ..style = PaintingStyle.fill;
      
    final paint2 = Paint()
      ..color = color2
      ..style = PaintingStyle.fill;

    final path1 = Path();
    final path2 = Path();

    final waveHeight = 20.0;
    
    // Wave 1
    path1.moveTo(0, size.height - waveHeight);
    for (double i = 0; i <= size.width; i++) {
      path1.lineTo(
        i, 
        size.height - waveHeight - math.sin((i / size.width * 2 * math.pi) + (animationValue * 2 * math.pi)) * waveHeight
      );
    }
    path1.lineTo(size.width, 0);
    path1.lineTo(0, 0);
    path1.close();

    // Wave 2 (offset)
    path2.moveTo(0, size.height - waveHeight * 1.5);
    for (double i = 0; i <= size.width; i++) {
      path2.lineTo(
        i, 
        size.height - waveHeight * 1.5 - math.sin((i / size.width * 2 * math.pi) + (animationValue * 2 * math.pi) + math.pi) * waveHeight
      );
    }
    path2.lineTo(size.width, 0);
    path2.lineTo(0, 0);
    path2.close();

    canvas.drawPath(path2, paint2);
    canvas.drawPath(path1, paint1);
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) => old.animationValue != animationValue;
}
