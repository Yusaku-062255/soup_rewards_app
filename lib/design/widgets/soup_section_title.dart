import 'package:flutter/material.dart';
import '../theme.dart';

/// Section title with consistent spacing
class SoupSectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  const SoupSectionTitle({
    super.key,
    required this.title,
    this.trailing,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ??
          const EdgeInsets.only(
            left: DesignTokens.spaceBase,
            right: DesignTokens.spaceBase,
            top: DesignTokens.spaceSection,
            bottom: DesignTokens.spaceSmall,
          ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: DesignTokens.fontSizeH3,
              fontWeight: FontWeight.bold,
              color: DesignTokens.textPrimary,
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
