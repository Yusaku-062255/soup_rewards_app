import 'package:flutter/material.dart';
import '../theme.dart';

/// Reusable card widget with ahamo-level styling
class SoupCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final double? elevation;

  const SoupCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    final card = Card(
      color: backgroundColor ?? DesignTokens.card,
      elevation: elevation ?? DesignTokens.elevationCard,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(DesignTokens.spaceBase),
        child: child,
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusCard),
        child: card,
      );
    }

    return card;
  }
}
