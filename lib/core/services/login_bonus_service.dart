// 日次ログインボーナスサービス（同日二重付与防止）
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import 'points_service.dart';

class LoginBonusService {
  static const String _lastLoginDateKey = 'last_login_date';
  static const int _dailyBonusPoints = 5;
  static const double _baseBonusMultiplier = 1.0;

  /// 日次ログインボーナスの付与判定・実行
  /// 同日二重付与を防止
  static Future<PointsState?> maybeGrantDailyBonus(
    PointsState current, {
    double rankMultiplier = 1.0,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = _formatDate(DateTime.now());
      final lastLoginDate = prefs.getString(_lastLoginDateKey);

      // 同日ログイン判定
      if (lastLoginDate == today) {
        developer.log('[SOUP] Daily bonus already granted today: $today');
        return null; // 既に今日付与済み
      }

      // ログインボーナス付与
      final newState = PointsService.grant(
        current,
        basePoint: _dailyBonusPoints,
        multiplier: _baseBonusMultiplier * rankMultiplier,
        title: 'Daily Login Bonus',
        note: 'Welcome back! Keep your streak going!',
      );

      // 最終ログイン日を保存
      await prefs.setString(_lastLoginDateKey, today);
      
      developer.log('[SOUP] Daily bonus granted for $today');
      return newState;
    } catch (e) {
      developer.log('[SOUP] Error granting daily bonus: $e');
      return null;
    }
  }

  /// 今日のログインボーナス取得済みかチェック
  static Future<bool> isTodayBonusGranted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = _formatDate(DateTime.now());
      final lastLoginDate = prefs.getString(_lastLoginDateKey);
      return lastLoginDate == today;
    } catch (e) {
      developer.log('[SOUP] Error checking today bonus: $e');
      return false;
    }
  }

  /// 連続ログイン日数を取得（将来の拡張用）
  static Future<int> getLoginStreak() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('login_streak') ?? 0;
    } catch (e) {
      developer.log('[SOUP] Error getting login streak: $e');
      return 0;
    }
  }

  /// 連続ログイン日数を更新（将来の拡張用）
  static Future<void> updateLoginStreak() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = _formatDate(DateTime.now());
      final lastLoginDate = prefs.getString(_lastLoginDateKey);
      final yesterday = _formatDate(DateTime.now().subtract(const Duration(days: 1)));
      
      int currentStreak = prefs.getInt('login_streak') ?? 0;
      
      if (lastLoginDate == yesterday) {
        // 連続ログイン
        currentStreak++;
      } else if (lastLoginDate != today) {
        // ストリーク途切れ
        currentStreak = 1;
      }
      
      await prefs.setInt('login_streak', currentStreak);
      developer.log('[SOUP] Login streak updated: $currentStreak days');
    } catch (e) {
      developer.log('[SOUP] Error updating login streak: $e');
    }
  }

  /// 日付を YYYY-MM-DD 形式でフォーマット
  static String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
           '${date.month.toString().padLeft(2, '0')}-'
           '${date.day.toString().padLeft(2, '0')}';
  }

  /// デバッグ用：最終ログイン日をリセット
  static Future<void> resetLastLoginDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastLoginDateKey);
      await prefs.remove('login_streak');
      developer.log('[SOUP] Last login date reset for testing');
    } catch (e) {
      developer.log('[SOUP] Error resetting login date: $e');
    }
  }
}
