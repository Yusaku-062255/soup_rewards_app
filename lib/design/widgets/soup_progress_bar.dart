import 'package:flutter/material.dart';
import '../theme.dart';

/// Custom progress bar with rounded corners (ahamo-style)
class SoupProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final double height;
  final Color? backgroundColor;
  final Color? progressColor;

  const SoupProgressBar({
    super.key,
    required this.progress,
    this.height = 8.0,
    this.backgroundColor,
    this.progressColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: LinearProgressIndicator(
        value: progress.clamp(0.0, 1.0),
        minHeight: height,
        backgroundColor: backgroundColor ?? DesignTokens.surface,
        valueColor: AlwaysStoppedAnimation<Color>(
          progressColor ?? DesignTokens.primary,
        ),
      ),
    );
  }
}
