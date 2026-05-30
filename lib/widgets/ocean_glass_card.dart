import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

/// A reusable glassmorphic card with soft shadows, oceanic styling,
/// and built-in hover/tap scaling animations.
class OceanGlassCard extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;

  const OceanGlassCard({
    super.key,
    required this.child,
    this.borderRadius = 24.0,
    this.padding = const EdgeInsets.all(20.0),
    this.margin = const EdgeInsets.only(bottom: 16.0),
    this.onTap,
  });

  @override
  State<OceanGlassCard> createState() => _OceanGlassCardState();
}

class _OceanGlassCardState extends State<OceanGlassCard> {
  bool _isHovered = false;
  bool _isTapped = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isTapped = true),
        onTapUp: (_) {
          setState(() => _isTapped = false);
          if (widget.onTap != null) widget.onTap!();
        },
        onTapCancel: () => setState(() => _isTapped = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          margin: widget.margin,
          transform: Matrix4.identity()..scale(_isTapped ? 0.98 : (_isHovered ? 1.01 : 1.0)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowBlue.withOpacity(_isHovered ? 0.3 : 0.15),
                blurRadius: _isHovered ? 30 : 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: widget.padding,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  border: Border.all(
                    color: AppTheme.isDark
                        ? Colors.white.withOpacity(0.12)
                        : Colors.white.withOpacity(0.6),
                    width: 1.5,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: AppTheme.isDark
                        ? [
                            Colors.white.withOpacity(0.08),
                            Colors.white.withOpacity(0.02),
                          ]
                        : [
                            Colors.white.withOpacity(0.8),
                            Colors.white.withOpacity(0.4),
                          ],
                  ),
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ).animate().fade(duration: 400.ms).slideY(begin: 0.05, end: 0, duration: 400.ms, curve: Curves.easeOutCubic),
    );
  }
}
