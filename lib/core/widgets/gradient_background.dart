import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Gradient background widget for consistent app-wide backgrounds
class GradientBackground extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;

  const GradientBackground({
    super.key,
    required this.child,
    this.colors,
    this.begin = Alignment.topCenter,
    this.end = Alignment.bottomCenter,
  });

  @override
  Widget build(BuildContext context) {
    final defaultColors = [
      AppTheme.backgroundColor,
      AppTheme.backgroundColor.withOpacity(0.95),
      Colors.white.withOpacity(0.98),
    ];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: begin,
          end: end,
          colors: colors ?? defaultColors,
        ),
      ),
      child: child,
    );
  }
}
