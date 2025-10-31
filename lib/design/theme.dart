import 'package:flutter/material.dart';

/// Design tokens for SOUP Rewards App (ahamo-level UI)
class DesignTokens {
  // Colors
  static const Color primary = Color(0xFF00C853);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF8FAFB);
  static const Color card = Color(0xFFFFFFFF);
  static const Color accentMint = Color(0xFFCFF9D9);
  static const Color textPrimary = Color(0xFF14161A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color error = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFF57C00);
  static const Color success = Color(0xFF00C853);

  // Spacing
  static const double spaceBase = 16.0;
  static const double spaceSection = 20.0;
  static const double spaceHeading = 24.0;
  static const double spaceSmall = 8.0;
  static const double spaceLarge = 32.0;

  // Border Radius
  static const double radiusCard = 24.0;
  static const double radiusBottomSheet = 32.0;
  static const double radiusButton = 12.0;
  static const double radiusChip = 20.0;

  // Typography
  static const double fontSizeH1 = 28.0;
  static const double fontSizeH2 = 24.0;
  static const double fontSizeH3 = 20.0;
  static const double fontSizeBody = 16.0;
  static const double fontSizeCaption = 14.0;
  static const double fontSizeSmall = 12.0;

  // Elevation
  static const double elevationCard = 2.0;
  static const double elevationButton = 4.0;
  static const double elevationBottomSheet = 8.0;

  DesignTokens._();
}

/// Creates the app theme using design tokens
ThemeData createAppTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: DesignTokens.primary,
      onPrimary: DesignTokens.onPrimary,
      surface: DesignTokens.surface,
      onSurface: DesignTokens.textPrimary,
      error: DesignTokens.error,
      secondary: DesignTokens.accentMint,
      onSecondary: DesignTokens.textPrimary,
    ),
    scaffoldBackgroundColor: DesignTokens.surface,
    cardTheme: CardTheme(
      color: DesignTokens.card,
      elevation: DesignTokens.elevationCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusCard),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: DesignTokens.primary,
        foregroundColor: DesignTokens.onPrimary,
        elevation: DesignTokens.elevationButton,
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spaceBase * 2,
          vertical: DesignTokens.spaceBase,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
        ),
        textStyle: const TextStyle(
          fontSize: DesignTokens.fontSizeBody,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: DesignTokens.card,
      selectedColor: DesignTokens.primary,
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spaceBase,
        vertical: DesignTokens.spaceSmall,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusChip),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: DesignTokens.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DesignTokens.radiusBottomSheet),
        ),
      ),
      elevation: DesignTokens.elevationBottomSheet,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: DesignTokens.fontSizeH1,
        fontWeight: FontWeight.bold,
        color: DesignTokens.textPrimary,
      ),
      displayMedium: TextStyle(
        fontSize: DesignTokens.fontSizeH2,
        fontWeight: FontWeight.bold,
        color: DesignTokens.textPrimary,
      ),
      displaySmall: TextStyle(
        fontSize: DesignTokens.fontSizeH3,
        fontWeight: FontWeight.w600,
        color: DesignTokens.textPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: DesignTokens.fontSizeBody,
        color: DesignTokens.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: DesignTokens.fontSizeCaption,
        color: DesignTokens.textPrimary,
      ),
      bodySmall: TextStyle(
        fontSize: DesignTokens.fontSizeSmall,
        color: DesignTokens.textSecondary,
      ),
    ),
  );
}
