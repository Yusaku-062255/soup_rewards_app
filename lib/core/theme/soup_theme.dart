import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// SOUP公式ブランドテーマ
/// 公式サイト（https://soup.tokushima.jp/）のデザインを基準に作成
class SoupTheme {
  // ブランドカラー（公式サイトから抽出）
  static const Color primaryNavy = Color(0xFF1A2332); // ダークブルー/ネイビー
  static const Color primaryGold = Color(0xFFD4AF37); // ゴールド
  static const Color accentOrange = Color(0xFFFF8C00); // オレンジ
  static const Color surfaceWhite = Color(0xFFFFFFFF); // ホワイト
  static const Color textBlack = Color(0xFF000000); // ブラック
  static const Color textWhite = Color(0xFFFFFFFF); // ホワイト
  static const Color backgroundGray = Color(0xFFF5F5F5); // ライトグレー
  static const Color cardShadow = Color(0x1A000000); // シャドウ

  // グラデーションカラー
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient navyGradient = LinearGradient(
    colors: [Color(0xFF1A2332), Color(0xFF2C3E50)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // テキストスタイル
  static const TextStyle headingLarge = TextStyle(
    fontFamily: 'NotoSansJP',
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: textBlack,
    height: 1.2,
  );

  static const TextStyle headingMedium = TextStyle(
    fontFamily: 'NotoSansJP',
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textBlack,
    height: 1.3,
  );

  static const TextStyle headingSmall = TextStyle(
    fontFamily: 'NotoSansJP',
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textBlack,
    height: 1.4,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'NotoSansJP',
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textBlack,
    height: 1.6,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'NotoSansJP',
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textBlack,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'NotoSansJP',
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: textBlack,
    height: 1.4,
  );

  static const TextStyle buttonText = TextStyle(
    fontFamily: 'NotoSansJP',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textWhite,
  );

  // ボタンスタイル
  static ButtonStyle primaryButton = ElevatedButton.styleFrom(
    backgroundColor: primaryGold,
    foregroundColor: textWhite,
    elevation: 4,
    shadowColor: cardShadow,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    textStyle: buttonText,
  );

  static ButtonStyle secondaryButton = ElevatedButton.styleFrom(
    backgroundColor: primaryNavy,
    foregroundColor: textWhite,
    elevation: 2,
    shadowColor: cardShadow,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    textStyle: buttonText.copyWith(fontSize: 14),
  );

  static ButtonStyle outlineButton = OutlinedButton.styleFrom(
    foregroundColor: primaryNavy,
    side: const BorderSide(color: primaryNavy, width: 2),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    textStyle: buttonText.copyWith(color: primaryNavy),
  );

  // カードスタイル
  static BoxDecoration cardDecoration = BoxDecoration(
    color: surfaceWhite,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: cardShadow,
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration goldCardDecoration = BoxDecoration(
    gradient: goldGradient,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: primaryGold.withOpacity(0.3),
        blurRadius: 12,
        offset: const Offset(0, 6),
      ),
    ],
  );

  // アプリバースタイル
  static AppBarTheme appBarTheme = const AppBarTheme(
    backgroundColor: primaryNavy,
    foregroundColor: textWhite,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      fontFamily: 'NotoSansJP',
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: textWhite,
    ),
    systemOverlayStyle: SystemUiOverlayStyle.light,
  );

  // ボトムナビゲーションテーマ
  static BottomNavigationBarThemeData bottomNavTheme = const BottomNavigationBarThemeData(
    backgroundColor: surfaceWhite,
    selectedItemColor: primaryGold,
    unselectedItemColor: Colors.grey,
    type: BottomNavigationBarType.fixed,
    elevation: 8,
    selectedLabelStyle: TextStyle(
      fontFamily: 'NotoSansJP',
      fontSize: 12,
      fontWeight: FontWeight.w600,
    ),
    unselectedLabelStyle: TextStyle(
      fontFamily: 'NotoSansJP',
      fontSize: 12,
      fontWeight: FontWeight.normal,
    ),
  );

  // 入力フィールドテーマ
  static InputDecorationTheme inputTheme = InputDecorationTheme(
    filled: true,
    fillColor: surfaceWhite,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.grey, width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.grey, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: primaryGold, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.red, width: 1),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    labelStyle: bodyMedium.copyWith(color: Colors.grey[600]),
    hintStyle: bodyMedium.copyWith(color: Colors.grey[400]),
  );

  // メインテーマデータ
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryNavy,
      colorScheme: const ColorScheme.light(
        primary: primaryNavy,
        secondary: primaryGold,
        tertiary: accentOrange,
        surface: surfaceWhite,
        background: backgroundGray,
        onPrimary: textWhite,
        onSecondary: textBlack,
        onSurface: textBlack,
        onBackground: textBlack,
      ),
      
      // フォント設定
      fontFamily: 'NotoSansJP',
      
      // テキストテーマ
      textTheme: const TextTheme(
        headlineLarge: headingLarge,
        headlineMedium: headingMedium,
        headlineSmall: headingSmall,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelLarge: buttonText,
      ),
      
      // コンポーネントテーマ
      appBarTheme: appBarTheme,
      bottomNavigationBarTheme: bottomNavTheme,
      inputDecorationTheme: inputTheme,
      
      // ボタンテーマ
      elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButton),
      outlinedButtonTheme: OutlinedButtonThemeData(style: outlineButton),
      
      // カードテーマ
      cardTheme: CardTheme(
        color: surfaceWhite,
        elevation: 4,
        shadowColor: cardShadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      
      // その他
      scaffoldBackgroundColor: backgroundGray,
      dividerColor: Colors.grey[300],
    );
  }

  // ダークモードは無効（公式サイトに合わせて常時ライト）
  static ThemeData get darkTheme => lightTheme;

  // ユーティリティメソッド
  static BoxDecoration heroGradient = const BoxDecoration(
    gradient: LinearGradient(
      colors: [primaryNavy, Color(0xFF2C3E50)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  );

  static BoxDecoration serviceCardDecoration = BoxDecoration(
    color: surfaceWhite,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: primaryGold.withOpacity(0.3), width: 1),
    boxShadow: [
      BoxShadow(
        color: cardShadow,
        blurRadius: 12,
        offset: const Offset(0, 6),
      ),
    ],
  );

  // アニメーション設定
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Curve animationCurve = Curves.easeInOut;

  // スペーシング
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // ボーダーラディウス
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;
}

/// SOUP公式ブランドのアイコン定義
class SoupIcons {
  static const IconData coating = Icons.car_repair;
  static const IconData bike = Icons.motorcycle;
  static const IconData protection = Icons.shield;
  static const IconData wheel = Icons.tire_repair;
  static const IconData glass = Icons.window;
  static const IconData interior = Icons.airline_seat_recline_normal;
  static const IconData headlight = Icons.lightbulb;
  static const IconData points = Icons.stars;
  static const IconData coupon = Icons.local_offer;
  static const IconData car = Icons.directions_car;
  static const IconData phone = Icons.phone;
  static const IconData location = Icons.location_on;
  static const IconData time = Icons.access_time;
  static const IconData gallery = Icons.photo_library;
  static const IconData service = Icons.build;
  static const IconData info = Icons.info;
  static const IconData reserve = Icons.event_available;
}
