import 'package:flutter/material.dart';

/// SOUP Rewards アプリカラーパレット
/// 徳島発カーケアブランド「SOUP」のブランドカラーを定義
class AppColors {
  AppColors._();

  // ブランドカラー（SOUPロゴから抽出）
  static const Color primary = Color(0xFF00AEEF);      // SOUPブルー
  static const Color primaryDark = Color(0xFF0088CC);   // ダークブルー
  static const Color primaryLight = Color(0xFF33C1F2); // ライトブルー
  
  static const Color secondary = Color(0xFFFFD54F);     // アクセントイエロー
  static const Color secondaryDark = Color(0xFFFFB300); // ダークイエロー
  static const Color secondaryLight = Color(0xFFFFE082); // ライトイエロー

  // ベースカラー
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color surface = Color(0xFFFAFAFA);
  static const Color background = Color(0xFFF5F5F5);

  // テキストカラー
  static const Color textMain = Color(0xFF212121);      // メインテキスト
  static const Color textSub = Color(0xFF757575);       // サブテキスト
  static const Color textLight = Color(0xFF9E9E9E);     // ライトテキスト

  // グレースケール
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);

  // ステータスカラー
  static const Color success = Color(0xFF4CAF50);       // 成功
  static const Color warning = Color(0xFFFF9800);       // 警告
  static const Color error = Color(0xFFF44336);         // エラー
  static const Color info = Color(0xFF2196F3);          // 情報

  // カーケア関連カラー
  static const Color carWash = Color(0xFF81C784);       // 洗車グリーン
  static const Color coating = Color(0xFF64B5F6);       // コーティングブルー
  static const Color maintenance = Color(0xFFFFB74D);   // メンテナンスオレンジ

  // グラデーション
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, secondaryDark],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [white, surface],
  );

  // シャドウカラー
  static Color shadowLight = black.withOpacity(0.08);
  static Color shadowMedium = black.withOpacity(0.16);
  static Color shadowDark = black.withOpacity(0.24);

  // オーバーレイカラー
  static Color overlay = black.withOpacity(0.5);
  static Color overlayLight = black.withOpacity(0.3);
}
