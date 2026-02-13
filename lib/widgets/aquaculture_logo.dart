import 'package:flutter/material.dart';

class AquacultureLogo extends StatelessWidget {
  final double size;
  final Color color;

  const AquacultureLogo({
    super.key,
    this.size = 80.0,
    this.color = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Clip the bottom part of the icon to hide the "crooked" chopsticks
        ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: 0.55, // Adjusted to crop out the chopsticks completely
            child: Icon(
              Icons.set_meal,
              size: size,
              color: color,
            ),
          ),
        ),
        SizedBox(height: size * 0.05),
        // Add two straight lines
        _buildLine(),
        SizedBox(height: size * 0.05),
        _buildLine(),
      ],
    );
  }

  Widget _buildLine() {
    return Container(
      height: size * 0.08, // Proportional thickness
      width: size * 0.8,   // Proportional width
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.04), // Rounded edges
      ),
    );
  }
}
