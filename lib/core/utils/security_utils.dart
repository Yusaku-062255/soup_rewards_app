import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// セキュリティ関連のユーティリティ

class SecurityUtils {
  /// パスワードの強度チェック
  static PasswordStrength checkPasswordStrength(String password) {
    if (password.length < 6) return PasswordStrength.weak;
    
    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasLowercase = password.contains(RegExp(r'[a-z]'));
    bool hasDigits = password.contains(RegExp(r'[0-9]'));
    bool hasSpecialCharacters = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    
    int score = 0;
    if (hasUppercase) score++;
    if (hasLowercase) score++;
    if (hasDigits) score++;
    if (hasSpecialCharacters) score++;
    if (password.length >= 12) score++;
    
    if (score >= 4) return PasswordStrength.strong;
    if (score >= 2) return PasswordStrength.medium;
    return PasswordStrength.weak;
  }

  /// メールアドレスの形式チェック
  static bool isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }

  /// 電話番号の形式チェック（日本の形式）
  static bool isValidPhoneNumber(String phoneNumber) {
    // 日本の電話番号形式をチェック
    return RegExp(r'^(\+81|0)[0-9]{9,10}$').hasMatch(phoneNumber.replaceAll('-', ''));
  }

  /// 文字列のハッシュ化
  static String hashString(String input) {
    var bytes = utf8.encode(input);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// ランダムな文字列生成
  static String generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(length, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }

  /// 入力値のサニタイズ
  static String sanitizeInput(String input) {
    return input
        .replaceAll(RegExp(r'<[^>]*>'), '') // HTMLタグを除去
        .replaceAll(RegExp(r'[<>&"\x27`]'), '') // 危険な文字を除去
        .trim();
  }

  /// SQLインジェクション対策
  static String escapeSqlString(String input) {
    return input.replaceAll("'", "''");
  }

  /// デバッグ情報の安全な出力
  static void secureDebugPrint(String message) {
    if (kDebugMode) {
      // 本番環境では出力しない
      debugPrint('[DEBUG] $message');
    }
  }

  /// 機密データのマスキング
  static String maskSensitiveData(String data, {int visibleChars = 4}) {
    if (data.length <= visibleChars) {
      return '*' * data.length;
    }
    
    final visible = data.substring(0, visibleChars);
    final masked = '*' * (data.length - visibleChars);
    return visible + masked;
  }

  /// APIキーの検証
  static bool isValidApiKey(String apiKey) {
    // APIキーの基本的な形式チェック
    return apiKey.isNotEmpty && 
           apiKey.length >= 32 && 
           RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(apiKey);
  }

  /// セッショントークンの生成
  static String generateSessionToken() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final randomPart = generateRandomString(32);
    return hashString(timestamp + randomPart);
  }

  /// 入力値の長さ制限チェック
  static bool isWithinLengthLimit(String input, int maxLength) {
    return input.length <= maxLength;
  }

  /// 不正な文字の検出
  static bool containsMaliciousContent(String input) {
    final maliciousPatterns = [
      RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false),
      RegExp(r'javascript:', caseSensitive: false),
      RegExp(r'on\w+\s*=', caseSensitive: false),
      RegExp(r'(union|select|insert|update|delete|drop|create|alter)\s+', caseSensitive: false),
    ];

    return maliciousPatterns.any((pattern) => pattern.hasMatch(input));
  }
}

/// パスワード強度の列挙型
enum PasswordStrength {
  weak,
  medium,
  strong,
}

/// パスワード強度の拡張
extension PasswordStrengthExtension on PasswordStrength {
  String get displayName {
    switch (this) {
      case PasswordStrength.weak:
        return '弱い';
      case PasswordStrength.medium:
        return '普通';
      case PasswordStrength.strong:
        return '強い';
    }
  }

  Color get color {
    switch (this) {
      case PasswordStrength.weak:
        return const Color(0xFFE53E3E);
      case PasswordStrength.medium:
        return const Color(0xFFD69E2E);
      case PasswordStrength.strong:
        return const Color(0xFF38A169);
    }
  }
}

/// セキュアな入力フィールド
class SecureInputValidator {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'メールアドレスを入力してください';
    }
    if (!SecurityUtils.isValidEmail(value)) {
      return '正しいメールアドレスを入力してください';
    }
    if (SecurityUtils.containsMaliciousContent(value)) {
      return '不正な文字が含まれています';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'パスワードを入力してください';
    }
    if (value.length < 6) {
      return 'パスワードは6文字以上で入力してください';
    }
    if (SecurityUtils.checkPasswordStrength(value) == PasswordStrength.weak) {
      return 'より強力なパスワードを設定してください';
    }
    return null;
  }

  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return '電話番号を入力してください';
    }
    if (!SecurityUtils.isValidPhoneNumber(value)) {
      return '正しい電話番号を入力してください';
    }
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldNameを入力してください';
    }
    if (SecurityUtils.containsMaliciousContent(value)) {
      return '不正な文字が含まれています';
    }
    return null;
  }
}
