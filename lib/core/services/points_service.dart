// ポイント管理サービス
import 'dart:developer' as developer;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// ポイント取引の種類
enum PointTransactionType {
  earn('獲得'),
  spend('使用'),
  bonus('ボーナス'),
  evBonus('EV特典');

  const PointTransactionType(this.displayName);
  final String displayName;
}

// ポイント取引記録
class PointTransaction {
  final String id;
  final PointTransactionType type;
  final int amount;
  final String description;
  final DateTime timestamp;

  const PointTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'amount': amount,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory PointTransaction.fromJson(Map<String, dynamic> json) {
    return PointTransaction(
      id: json['id'] ?? '',
      type: PointTransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => PointTransactionType.earn,
      ),
      amount: json['amount'] ?? 0,
      description: json['description'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    );
  }
}

// ランク情報
class RankInfo {
  final String name;
  final int minPoints;
  final int maxPoints;
  final String color;
  final String icon;
  final double evMultiplier;

  const RankInfo({
    required this.name,
    required this.minPoints,
    required this.maxPoints,
    required this.color,
    required this.icon,
    this.evMultiplier = 1.0,
  });

  static const List<RankInfo> ranks = [
    RankInfo(
      name: 'ブロンズ',
      minPoints: 0,
      maxPoints: 999,
      color: '#CD7F32',
      icon: '🥉',
      evMultiplier: 1.2,
    ),
    RankInfo(
      name: 'シルバー',
      minPoints: 1000,
      maxPoints: 4999,
      color: '#C0C0C0',
      icon: '🥈',
      evMultiplier: 1.3,
    ),
    RankInfo(
      name: 'ゴールド',
      minPoints: 5000,
      maxPoints: 14999,
      color: '#FFD700',
      icon: '🥇',
      evMultiplier: 1.5,
    ),
    RankInfo(
      name: 'プラチナ',
      minPoints: 15000,
      maxPoints: 49999,
      color: '#E5E4E2',
      icon: '💎',
      evMultiplier: 1.8,
    ),
    RankInfo(
      name: 'ダイヤモンド',
      minPoints: 50000,
      maxPoints: 999999,
      color: '#B9F2FF',
      icon: '💠',
      evMultiplier: 2.0,
    ),
  ];

  static RankInfo getRankByPoints(int points) {
    return ranks.firstWhere(
      (rank) => points >= rank.minPoints && points <= rank.maxPoints,
      orElse: () => ranks.first,
    );
  }

  static RankInfo? getNextRank(int points) {
    final currentRankIndex = ranks.indexWhere(
      (rank) => points >= rank.minPoints && points <= rank.maxPoints,
    );
    
    if (currentRankIndex >= 0 && currentRankIndex < ranks.length - 1) {
      return ranks[currentRankIndex + 1];
    }
    return null;
  }
}

// ポイントサービス
class PointsService {
  static const String _pointsKey = 'user_points';
  static const String _totalEarnedKey = 'total_earned_points';
  static const String _transactionsKey = 'point_transactions';
  static const String _lastLoginKey = 'last_login_date';

  // 現在のポイント残高を取得
  static Future<int> getCurrentPoints() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_pointsKey) ?? 0;
    } catch (e) {
      developer.log('[SOUP] Error getting current points: $e');
      return 0;
    }
  }

  // 累計獲得ポイントを取得
  static Future<int> getTotalEarnedPoints() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_totalEarnedKey) ?? 0;
    } catch (e) {
      developer.log('[SOUP] Error getting total earned points: $e');
      return 0;
    }
  }

  // ポイントを追加
  static Future<bool> addPoints(
    int amount,
    String description, {
    PointTransactionType type = PointTransactionType.earn,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentPoints = await getCurrentPoints();
      final totalEarned = await getTotalEarnedPoints();
      
      // ポイント更新
      final newPoints = currentPoints + amount;
      final newTotalEarned = type == PointTransactionType.earn || type == PointTransactionType.bonus || type == PointTransactionType.evBonus
          ? totalEarned + amount
          : totalEarned;
      
      await prefs.setInt(_pointsKey, newPoints);
      await prefs.setInt(_totalEarnedKey, newTotalEarned);
      
      // 取引記録を追加
      await _addTransaction(PointTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: type,
        amount: amount,
        description: description,
        timestamp: DateTime.now(),
      ));
      
      developer.log('[SOUP] Points added: $amount ($description) - New balance: $newPoints');
      return true;
    } catch (e) {
      developer.log('[SOUP] Error adding points: $e');
      return false;
    }
  }

  // ポイントを使用
  static Future<bool> spendPoints(int amount, String description) async {
    try {
      final currentPoints = await getCurrentPoints();
      
      if (currentPoints < amount) {
        developer.log('[SOUP] Insufficient points: $currentPoints < $amount');
        return false;
      }
      
      final prefs = await SharedPreferences.getInstance();
      final newPoints = currentPoints - amount;
      
      await prefs.setInt(_pointsKey, newPoints);
      
      // 取引記録を追加
      await _addTransaction(PointTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: PointTransactionType.spend,
        amount: -amount,
        description: description,
        timestamp: DateTime.now(),
      ));
      
      developer.log('[SOUP] Points spent: $amount ($description) - New balance: $newPoints');
      return true;
    } catch (e) {
      developer.log('[SOUP] Error spending points: $e');
      return false;
    }
  }

  // 取引履歴を取得
  static Future<List<PointTransaction>> getTransactionHistory({
    int limit = 50,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final transactionsJson = prefs.getStringList(_transactionsKey) ?? [];
      
      final transactions = transactionsJson
          .map((json) => PointTransaction.fromJson(jsonDecode(json)))
          .toList();
      
      // 日付順でソート（新しい順）
      transactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      return transactions.take(limit).toList();
    } catch (e) {
      developer.log('[SOUP] Error getting transaction history: $e');
      return [];
    }
  }

  // 取引記録を追加
  static Future<void> _addTransaction(PointTransaction transaction) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final transactionsJson = prefs.getStringList(_transactionsKey) ?? [];
      
      transactionsJson.add(jsonEncode(transaction.toJson()));
      
      // 最新100件のみ保持
      if (transactionsJson.length > 100) {
        transactionsJson.removeRange(0, transactionsJson.length - 100);
      }
      
      await prefs.setStringList(_transactionsKey, transactionsJson);
    } catch (e) {
      developer.log('[SOUP] Error adding transaction: $e');
    }
  }

  // 現在のランク情報を取得
  static Future<RankInfo> getCurrentRank() async {
    final totalEarned = await getTotalEarnedPoints();
    return RankInfo.getRankByPoints(totalEarned);
  }

  // 次のランク情報を取得
  static Future<RankInfo?> getNextRank() async {
    final totalEarned = await getTotalEarnedPoints();
    return RankInfo.getNextRank(totalEarned);
  }

  // ランク進捗を取得（0.0-1.0）
  static Future<double> getRankProgress() async {
    final totalEarned = await getTotalEarnedPoints();
    final currentRank = RankInfo.getRankByPoints(totalEarned);
    
    if (currentRank == RankInfo.ranks.last) {
      return 1.0; // 最高ランク
    }
    
    final progress = (totalEarned - currentRank.minPoints) / 
                    (currentRank.maxPoints - currentRank.minPoints);
    
    return progress.clamp(0.0, 1.0);
  }

  // 次のランクまでの必要ポイント
  static Future<int> getPointsToNextRank() async {
    final totalEarned = await getTotalEarnedPoints();
    final nextRank = RankInfo.getNextRank(totalEarned);
    
    if (nextRank == null) {
      return 0; // 最高ランク
    }
    
    return nextRank.minPoints - totalEarned;
  }

  // ログインボーナスをチェック
  static Future<Map<String, dynamic>> checkLoginBonus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastLoginStr = prefs.getString(_lastLoginKey);
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      if (lastLoginStr != todayStr) {
        // 今日初回ログイン
        await prefs.setString(_lastLoginKey, todayStr);
        
        // ログインボーナスを付与
        const bonusAmount = 100;
        await addPoints(
          bonusAmount,
          '毎日ログインボーナス',
          type: PointTransactionType.bonus,
        );
        
        return {
          'isFirstLogin': true,
          'bonusAmount': bonusAmount,
          'message': '毎日ログインボーナス ${bonusAmount}pt を獲得しました！',
        };
      }
      
      return {
        'isFirstLogin': false,
        'bonusAmount': 0,
        'message': '今日のログインボーナスは既に受け取り済みです',
      };
    } catch (e) {
      developer.log('[SOUP] Error checking login bonus: $e');
      return {
        'isFirstLogin': false,
        'bonusAmount': 0,
        'message': 'ログインボーナスの確認に失敗しました',
      };
    }
  }

  // EV特典ポイントを付与
  static Future<bool> addEvBonus(int baseAmount, String description) async {
    final currentRank = await getCurrentRank();
    final bonusAmount = (baseAmount * currentRank.evMultiplier).round();
    
    return await addPoints(
      bonusAmount,
      '$description (EV特典 ${currentRank.evMultiplier}x)',
      type: PointTransactionType.evBonus,
    );
  }

  // ポイント統計情報を取得
  static Future<Map<String, dynamic>> getPointsStats() async {
    try {
      final currentPoints = await getCurrentPoints();
      final totalEarned = await getTotalEarnedPoints();
      final currentRank = await getCurrentRank();
      final nextRank = await getNextRank();
      final progress = await getRankProgress();
      final pointsToNext = await getPointsToNextRank();
      final transactions = await getTransactionHistory(limit: 10);
      
      return {
        'currentPoints': currentPoints,
        'totalEarned': totalEarned,
        'currentRank': {
          'name': currentRank.name,
          'icon': currentRank.icon,
          'color': currentRank.color,
          'evMultiplier': currentRank.evMultiplier,
        },
        'nextRank': nextRank != null ? {
          'name': nextRank.name,
          'icon': nextRank.icon,
          'color': nextRank.color,
        } : null,
        'progress': progress,
        'pointsToNextRank': pointsToNext,
        'recentTransactions': transactions.map((t) => {
          'type': t.type.displayName,
          'amount': t.amount,
          'description': t.description,
          'timestamp': t.timestamp.toIso8601String(),
        }).toList(),
      };
    } catch (e) {
      developer.log('[SOUP] Error getting points stats: $e');
      return {};
    }
  }

  // データをリセット（デバッグ用）
  static Future<bool> resetAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pointsKey);
      await prefs.remove(_totalEarnedKey);
      await prefs.remove(_transactionsKey);
      await prefs.remove(_lastLoginKey);
      
      developer.log('[SOUP] All points data reset');
      return true;
    } catch (e) {
      developer.log('[SOUP] Error resetting points data: $e');
      return false;
    }
  }
}
