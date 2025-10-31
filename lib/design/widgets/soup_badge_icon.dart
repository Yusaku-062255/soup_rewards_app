import 'package:flutter/material.dart';
import '../theme.dart';

/// Icon with optional badge (e.g., for capacity indicators)
class SoupBadgeIcon extends StatelessWidget {
  final IconData icon;
  final String? badgeText;
  final Color? iconColor;
  final Color? badgeColor;
  final double size;

  const SoupBadgeIcon({
    super.key,
    required this.icon,
    this.badgeText,
    this.iconColor,
    this.badgeColor,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    if (badgeText == null || badgeText!.isEmpty) {
      return Icon(
        icon,
        size: size,
        color: iconColor ?? DesignTokens.textPrimary,
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          icon,
          size: size,
          color: iconColor ?? DesignTokens.textPrimary,
        ),
        Positioned(
          right: -8,
          top: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: badgeColor ?? DesignTokens.error,
              borderRadius: BorderRadius.circular(10),
            ),
            constraints: const BoxConstraints(
              minWidth: 18,
              minHeight: 18,
            ),
            child: Text(
              badgeText!,
              style: const TextStyle(
                color: DesignTokens.onPrimary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
