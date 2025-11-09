import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

/// SOUP Rewards アプリテーマ
/// Material3準拠、SOUPブランド対応
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      
      // ColorScheme (Material3準拠)
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        onSurface: AppColors.textMain,
        error: AppColors.error,
        onPrimary: AppColors.white,
        onSecondary: AppColors.textMain,
        onError: AppColors.white,
      ),
      
      // AppBarTheme
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 8,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textMain,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          fontFamily: 'NotoSansJP',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textMain,
        ),
      ),
      
      // CardTheme
      cardTheme: CardThemeData(
        elevation: 12,
        shadowColor: AppColors.shadowLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: AppColors.white,
        surfaceTintColor: Colors.transparent,
      ),
      
      // ElevatedButtonTheme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // BottomNavigationBarTheme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.grey400,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
      
      // InputDecorationTheme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.grey50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.grey200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      
      // TextTheme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'NotoSansJP',
          fontSize: 32,
          fontWeight: FontWeight.w700,
          height: 1.2,
          color: AppColors.textMain,
        ),
        displayMedium: TextStyle(
          fontFamily: 'NotoSansJP',
          fontSize: 28,
          fontWeight: FontWeight.w700,
          height: 1.2,
          color: AppColors.textMain,
        ),
        displaySmall: TextStyle(
          fontFamily: 'NotoSansJP',
          fontSize: 24,
          fontWeight: FontWeight.w700,
          height: 1.3,
          color: AppColors.textMain,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'NotoSansJP',
          fontSize: 22,
          fontWeight: FontWeight.w700,
          height: 1.3,
          color: AppColors.textMain,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'NotoSansJP',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          height: 1.3,
          color: AppColors.textMain,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'NotoSansJP',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          height: 1.4,
          color: AppColors.textMain,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Inter',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          height: 1.4,
          color: AppColors.textMain,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 1.4,
          color: AppColors.textMain,
        ),
        titleSmall: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.4,
          color: AppColors.textMain,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'NotoSansJP',
          fontSize: 18,
          fontWeight: FontWeight.w500,
          height: 1.5,
          color: AppColors.textMain,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'NotoSansJP',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          height: 1.5,
          color: AppColors.textMain,
        ),
        bodySmall: TextStyle(
          fontFamily: 'NotoSansJP',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.5,
          color: AppColors.textSub,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          height: 1.4,
          color: AppColors.textMain,
        ),
        labelMedium: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.4,
          color: AppColors.textSub,
        ),
        labelSmall: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w400,
          height: 1.4,
          color: AppColors.textSub,
        ),
      ),
      
      // フォントファミリー
      fontFamily: 'NotoSansJP',
      
      // Material3追加設定
      splashFactory: InkRipple.splashFactory,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      
      // ColorScheme (Material3準拠 - ダークモード)
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
        primary: AppColors.primaryLight,
        secondary: AppColors.secondaryLight,
        surface: const Color(0xFF121212),
        onSurface: AppColors.white,
        error: AppColors.error,
        onPrimary: AppColors.black,
        onSecondary: AppColors.black,
        onError: AppColors.white,
      ),
      
      // フォントファミリー
      fontFamily: 'NotoSansJP',
      
      // Material3追加設定
      splashFactory: InkRipple.splashFactory,
    );
  }
}
