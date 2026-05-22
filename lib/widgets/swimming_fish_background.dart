import 'dart:math' as math;
import 'package:flutter/material.dart';

class SwimmingFishBackground extends StatefulWidget {
  final Widget? child;
  final int fishCount;

  const SwimmingFishBackground({
    super.key,
    this.child,
    this.fishCount = 6,
  });

  @override
  State<SwimmingFishBackground> createState() => _SwimmingFishBackgroundState();
}

class _Ripple {
  final Offset position;
  double radius = 0.0;
  double opacity = 1.0;

  _Ripple({
    required this.position,
  });
}

class _FishData {
  Offset position;
  Offset target;
  Color color;
  final double size;
  final double baseSpeed;
  double speed;
  double heading;
  double tailPhase;
  final double opacity;

  _FishData({
    required this.position,
    required this.target,
    required this.color,
    required this.size,
    required this.baseSpeed,
    required this.speed,
    required this.heading,
    required this.tailPhase,
    required this.opacity,
  });
}

class _SwimmingFishBackgroundState extends State<SwimmingFishBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_FishData> _fishes = [];
  final List<_Ripple> _ripples = [];
  math.Random random = math.Random();
  Size _lastSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..addListener(() {
        _updateFishPositions();
      });
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _initializeFishes(Size size) {
    _fishes.clear();
    for (int i = 0; i < widget.fishCount; i++) {
      // Mapped colors: Neon Indigo, Neon Teal, Glowing Pink/Coral, Cyan Accent
      Color color;
      switch (i % 4) {
        case 0:
          color = const Color(0xFF6366F1); // Indigo
          break;
        case 1:
          color = const Color(0xFF14B8A6); // Teal
          break;
        case 2:
          color = const Color(0xFFEC4899); // Pink
          break;
        default:
          color = const Color(0xFF06B6D4); // Cyan
      }

      double x = random.nextDouble() * size.width;
      double y = random.nextDouble() * size.height;

      // Schooling/Shoal depth layering:
      // 65% are smaller, peaceful background fish with lower opacity
      // 35% are larger, faster foreground/midground fish with higher opacity
      double fishSize;
      double opacity;
      double baseSpeed;

      if (random.nextDouble() < 0.65) {
        // Small background fish
        fishSize = 6.0 + random.nextDouble() * 10.0; // 6 to 16 scale
        opacity = 0.2 + (fishSize / 16.0) * 0.25; // 0.2 to 0.45 opacity
        baseSpeed = 0.6 + random.nextDouble() * 0.8; // slower, peaceful background drifting
      } else {
        // Normal/Large active foreground fish
        fishSize = 16.0 + random.nextDouble() * 16.0; // 16 to 32 scale
        opacity = 0.5 + (fishSize / 32.0) * 0.35; // 0.5 to 0.85 opacity
        baseSpeed = 1.2 + random.nextDouble() * 1.6; // faster active swimming
      }

      _fishes.add(_FishData(
        position: Offset(x, y),
        target: Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        ),
        color: color,
        size: fishSize,
        baseSpeed: baseSpeed,
        speed: baseSpeed,
        heading: random.nextDouble() * 2.0 * math.pi,
        tailPhase: random.nextDouble() * 10,
        opacity: opacity,
      ));
    }
    _lastSize = size;
  }

  void _updateFishPositions() {
    if (_lastSize == Size.zero) return;

    setState(() {
      // Update water ripples
      for (int i = _ripples.length - 1; i >= 0; i--) {
        var ripple = _ripples[i];
        ripple.radius += 2.5;
        ripple.opacity -= 0.015;
        if (ripple.opacity <= 0) {
          _ripples.removeAt(i);
        }
      }

      for (var fish in _fishes) {
        // Slow down back to baseSpeed if speed-boosted by touch
        if (fish.speed > fish.baseSpeed) {
          fish.speed -= 0.08;
          if (fish.speed < fish.baseSpeed) fish.speed = fish.baseSpeed;
        }

        // Distance to target
        double dx = fish.target.dx - fish.position.dx;
        double dy = fish.target.dy - fish.position.dy;
        double distance = math.sqrt(dx * dx + dy * dy);

        // If close to target, pick a new random target
        if (distance < 50) {
          fish.target = Offset(
            random.nextDouble() * _lastSize.width,
            random.nextDouble() * _lastSize.height,
          );
        }

        // Calculate target heading
        double targetHeading = math.atan2(dy, dx);

        // Smoothly interpolate heading angle (turning rate limit)
        double angleDiff = targetHeading - fish.heading;

        // Normalize angle difference to (-pi, pi)
        while (angleDiff < -math.pi) {
          angleDiff += 2 * math.pi;
        }
        while (angleDiff > math.pi) {
          angleDiff -= 2 * math.pi;
        }

        // Turn speed (radians per frame)
        double turnSpeed = 0.05;
        fish.heading += angleDiff.clamp(-turnSpeed, turnSpeed);

        // Move forward along the heading
        double speedModifier = distance < 120 ? 0.4 + (distance / 200) : 1.0;
        double actualSpeed = fish.speed * speedModifier;

        fish.position = Offset(
          fish.position.dx + math.cos(fish.heading) * actualSpeed,
          fish.position.dy + math.sin(fish.heading) * actualSpeed,
        );

        // Oscillate tail based on movement
        fish.tailPhase += 0.15 * actualSpeed;
      }
    });
  }

  void _handleTap(Offset tapPos) {
    setState(() {
      // Add a dynamic water ripple
      _ripples.add(_Ripple(position: tapPos));

      // Scatter/Startle any fish within 200 radius
      for (var fish in _fishes) {
        double dx = fish.position.dx - tapPos.dx;
        double dy = fish.position.dy - tapPos.dy;
        double distance = math.sqrt(dx * dx + dy * dy);

        if (distance < 200.0) {
          // Calculate heading away from touch point
          double runHeading = math.atan2(dy, dx);

          // Instantly update direction and apply rapid escape speed
          fish.heading = runHeading;
          fish.speed = fish.baseSpeed * 3.5;

          // Project a target escape point to run towards
          double escapeDist = 220.0 + random.nextDouble() * 100.0;
          fish.target = Offset(
            (fish.position.dx + math.cos(runHeading) * escapeDist).clamp(0, _lastSize.width),
            (fish.position.dy + math.sin(runHeading) * escapeDist).clamp(0, _lastSize.height),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        Size size = Size(constraints.maxWidth, constraints.maxHeight);
        if (_fishes.isEmpty || _lastSize != size) {
          _initializeFishes(size);
        }

        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (PointerDownEvent event) {
            _handleTap(event.localPosition);
          },
          child: Stack(
            children: [
              // Dark glowing aquatic deep water background
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF070B13),
                        Color(0xFF090D16),
                        Color(0xFF0D1527),
                      ],
                    ),
                  ),
                ),
              ),
              // Custom Painter drawing the swimming fishes and water ripples
              Positioned.fill(
                child: CustomPaint(
                  painter: _FishSwarmPainter(fishes: _fishes, ripples: _ripples),
                ),
              ),
              // Floating glowing overlay lights for ambiance
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.2,
                        colors: [
                          Colors.indigoAccent.withOpacity(0.03),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.child != null) widget.child!,
            ],
          ),
        );
      },
    );
  }
}

class _FishSwarmPainter extends CustomPainter {
  final List<_FishData> fishes;
  final List<_Ripple> ripples;

  _FishSwarmPainter({required this.fishes, required this.ripples});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw organic wavelike water ripples first
    final ripplePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (var ripple in ripples) {
      if (ripple.opacity > 0) {
        // Cyan outer ripple
        ripplePaint.color = const Color(0xFF06B6D4).withOpacity(ripple.opacity * 0.45);
        canvas.drawCircle(ripple.position, ripple.radius, ripplePaint);

        // Faint indigo secondary concentric wave
        if (ripple.radius > 20) {
          ripplePaint.color = const Color(0xFF6366F1).withOpacity(ripple.opacity * 0.25);
          canvas.drawCircle(ripple.position, ripple.radius - 15, ripplePaint);
        }
      }
    }

    // 2. Draw swimming fishes
    for (var fish in fishes) {
      canvas.save();

      // Translate to fish position and rotate by heading
      canvas.translate(fish.position.dx, fish.position.dy);
      canvas.rotate(fish.heading);

      // Tail oscillation angle
      double wiggle = math.sin(fish.tailPhase) * 0.35;

      // Draw glowing body backdrop glow
      final glowPaint = Paint()
        ..color = fish.color.withOpacity(0.18 * fish.opacity)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      
      _drawFishShape(canvas, glowPaint, fish.size, wiggle);

      // Draw primary fish body
      final bodyPaint = Paint()
        ..color = fish.color.withOpacity(0.7 * fish.opacity)
        ..style = PaintingStyle.fill;
      _drawFishShape(canvas, bodyPaint, fish.size, wiggle);

      // Draw fine details (spine, eye, etc.)
      final detailPaint = Paint()
        ..color = Colors.white.withOpacity(0.9 * fish.opacity)
        ..style = PaintingStyle.fill;

      // Draw eye on the upper side (pointing forwards)
      canvas.drawCircle(Offset(fish.size * 0.35, -fish.size * 0.08), fish.size * 0.04, detailPaint);

      // Draw pectoral fins
      final finPaint = Paint()
        ..color = fish.color.withOpacity(0.5 * fish.opacity)
        ..style = PaintingStyle.fill;

      Path leftFin = Path();
      leftFin.moveTo(fish.size * 0.1, -fish.size * 0.1);
      leftFin.quadraticBezierTo(
        fish.size * 0.05, -fish.size * 0.3,
        -fish.size * 0.1, -fish.size * 0.25,
      );
      leftFin.close();
      canvas.drawPath(leftFin, finPaint);

      Path rightFin = Path();
      rightFin.moveTo(fish.size * 0.1, fish.size * 0.1);
      rightFin.quadraticBezierTo(
        fish.size * 0.05, fish.size * 0.3,
        -fish.size * 0.1, fish.size * 0.25,
      );
      rightFin.close();
      canvas.drawPath(rightFin, finPaint);

      canvas.restore();
    }
  }

  // Draw organic vector fish body & wagging tail
  void _drawFishShape(Canvas canvas, Paint paint, double len, double wiggle) {
    Path path = Path();
    
    // Fish snout
    path.moveTo(len * 0.5, 0);

    // Upper curve of fish body
    path.quadraticBezierTo(
      len * 0.15, -len * 0.18,
      -len * 0.15, -len * 0.06,
    );

    // Draw the oscillating tail fin connection
    double tailX = -len * 0.55;
    double tailY = math.sin(wiggle) * (len * 0.25);
    
    path.lineTo(tailX, tailY);

    // Draw tail fin
    path.lineTo(tailX - len * 0.2, tailY - len * 0.25);
    path.quadraticBezierTo(tailX - len * 0.1, tailY, tailX - len * 0.2, tailY + len * 0.25);
    path.lineTo(tailX, tailY);

    // Lower curve of fish body
    path.lineTo(-len * 0.15, len * 0.06);
    path.quadraticBezierTo(
      len * 0.15, len * 0.18,
      len * 0.5, 0,
    );
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
