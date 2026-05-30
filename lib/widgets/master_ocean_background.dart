import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'swimming_fish_background.dart';
import 'floating_bubbles_bg.dart';
import 'animated_wave_header.dart';

class MasterOceanBackground extends StatelessWidget {
  final Widget child;
  final bool showFishes;

  const MasterOceanBackground({
    super.key, 
    required this.child,
    this.showFishes = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget background = Stack(
      children: [
        // 1. Bubbles Overlay
        const FloatingBubblesBackground(
          bubbleCount: 25,
          child: SizedBox.expand(),
        ),
        
        // 2. Waves at the bottom
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.rotationX(math.pi), // Flips the waves vertically to stay at bottom
            child: const AnimatedWaveHeader(height: 120, showWaves: true),
          ),
        ),
        
        // 3. Main Content
        child,
      ],
    );

    if (showFishes) {
      return SwimmingFishBackground(
        fishCount: 12,
        child: background,
      );
    }

    return background;
  }
}
