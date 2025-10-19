import 'dart:developer' as developer;
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

// PointsServiceの状態を定義
class PointsState {
  final int currentPoints;
  final int totalEarnedPoints;
  final List<PointTransaction> history;
  final RankInfo currentRank;
  final RankInfo? nextRank;
  final double rankProgress;
  final int pointsToNextRank;

  PointsState({
    this.currentPoints = 0,
    this.totalEarnedPoints = 0,
    this.history = const [],
    required this.currentRank,
    this.nextRank,
    this.rankProgress = 0.0,
    this.pointsToNextRank = 0,
  });

  PointsState copyWith({
    int? currentPoints,
    int? totalEarnedPoints,
    List<PointTransaction>? history,
    RankInfo? currentRank,
    RankInfo? nextRank,
    double? rankProgress,
    int? pointsToNextRank,
  }) {
    return PointsState(
      currentPoints: currentPoints ?? this.currentPoints,
      totalEarnedPoints: totalEarnedPoints ?? this.totalEarnedPoints,
      history: history ?? this.history,
      currentRank: currentRank ?? this.currentRank,
      nextRank: nextRank ?? this.nextRank,
      rankProgress: rankProgress ?? this.rankProgress,
      pointsToNextRank: pointsToNextRank ?? this.pointsToNextRank,
    );
  }
}

// PointsServiceNotifierを定義
class PointsServiceNotifier extends StateNotifier<PointsState> {
  static const String _pointsKey = 'user_points';
  static const String _totalEarnedKey = 'total_earned_points';
  static const String _transactionsKey = 'point_transactions';
  static const String _lastLoginKey = 'last_login_date';

  PointsServiceNotifier() : super(PointsState(currentRank: RankInfo.ranks.first)) {
    _init();
  }

  Future<void> _init() async {
    await loadPointsData();
  }

  // Public API
  int get currentPoints => state.currentPoints;
  List<PointTransaction> get pointsHistory => state.history;
  RankInfo get currentRank => state.currentRank;
  RankInfo? get nextRank => state.nextRank;
  double get rankProgress => state.rankProgress;
  int get pointsToNextRank => state.pointsToNextRank;

  Future<void> loadPointsData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentPoints = prefs.getInt(_pointsKey) ?? 0;
      final totalEarned = prefs.getInt(_totalEarnedKey) ?? 0;
      final transactions = await _getTransactionHistory(limit: 10);
      final currentRank = RankInfo.getRankByPoints(totalEarned);
      final nextRank = RankInfo.getNextRank(totalEarned);
      final rankProgress = _getRankProgress(totalEarned, currentRank);
      final pointsToNext = _getPointsToNextRank(totalEarned, nextRank);

      state = state.copyWith(
        currentPoints: currentPoints,
        totalEarnedPoints: totalEarned,
        history: transactions,
        currentRank: currentRank,
        nextRank: nextRank,
        rankProgress: rankProgress,
        pointsToNextRank: pointsToNext,
      );
    } catch (e) {
      developer.log('[SOUP] Error loading points data: $e');
    }
  }

  Future<bool> addPoints(
    int amount,
    String description, {
    PointTransactionType type = PointTransactionType.earn,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final newPoints = state.currentPoints + amount;
      final newTotalEarned = type == PointTransactionType.earn || type == PointTransactionType.bonus || type == PointTransactionType.evBonus
          ? state.totalEarnedPoints + amount
          : state.totalEarnedPoints;
      
      await prefs.setInt(_pointsKey, newPoints);
      await prefs.setInt(_totalEarnedKey, newTotalEarned);
      
      final transaction = PointTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: type,
        amount: amount,
        description: description,
        timestamp: DateTime.now(),
      );
      await _addTransaction(transaction);
      
      await loadPointsData(); // 状態を再読み込み
      developer.log('[SOUP] Points added: $amount ($description) - New balance: $newPoints');
      return true;
    } catch (e) {
      developer.log('[SOUP] Error adding points: $e');
      return false;
    }
  }

  Future<bool> spendPoints(int amount, String description) async {
    try {
      if (state.currentPoints < amount) {
        developer.log('[SOUP] Insufficient points: ${state.currentPoints} < $amount');
        return false;
      }
      
      final prefs = await SharedPreferences.getInstance();
      final newPoints = state.currentPoints - amount;
      
      await prefs.setInt(_pointsKey, newPoints);
      
      final transaction = PointTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: PointTransactionType.spend,
        amount: -amount,
        description: description,
        timestamp: DateTime.now(),
      );
      await _addTransaction(transaction);
      
      await loadPointsData(); // 状態を再読み込み
      developer.log('[SOUP] Points spent: $amount ($description) - New balance: $newPoints');
      return true;
    } catch (e) {
      developer.log('[SOUP] Error spending points: $e');
      return false;
    }
  }

  Future<List<PointTransaction>> _getTransactionHistory({
    int limit = 50,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final transactionsJson = prefs.getStringList(_transactionsKey) ?? [];
      
      final transactions = transactionsJson
          .map((json) => PointTransaction.fromJson(jsonDecode(json)))
          .toList();
      
      transactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      return transactions.take(limit).toList();
    } catch (e) {
      developer.log('[SOUP] Error getting transaction history: $e');
      return [];
    }
  }

  Future<void> _addTransaction(PointTransaction transaction) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final transactionsJson = prefs.getStringList(_transactionsKey) ?? [];
      
      transactionsJson.add(jsonEncode(transaction.toJson()));
      
      if (transactionsJson.length > 100) {
        transactionsJson.removeRange(0, transactionsJson.length - 100);
      }
      
      await prefs.setStringList(_transactionsKey, transactionsJson);
    } catch (e) {
      developer.log('[SOUP] Error adding transaction: $e');
    }
  }

  double _getRankProgress(int totalEarned, RankInfo currentRank) {
    if (currentRank == RankInfo.ranks.last) {
      return 1.0; // 最高ランク
    }
    
    final progress = (totalEarned - currentRank.minPoints) / 
                    (currentRank.maxPoints - currentRank.minPoints);
    
    return progress.clamp(0.0, 1.0);
  }

  int _getPointsToNextRank(int totalEarned, RankInfo? nextRank) {
    if (nextRank == null) {
      return 0; // 最高ランク
    }
    return nextRank.minPoints - totalEarned;
  }

  Future<bool> checkAndAwardLoginBonus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastLoginStr = prefs.getString(_lastLoginKey);
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      if (lastLoginStr != todayStr) {
        await prefs.setString(_lastLoginKey, todayStr);
        
        const bonusAmount = 100;
        await addPoints(
          bonusAmount,
          '毎日ログインボーナス',
          type: PointTransactionType.bonus,
        );
        return true;
      }
      return false;
    } catch (e) {
      developer.log('[SOUP] Error checking login bonus: $e');
      return false;
    }
  }

  Future<bool> addEvBonus(int baseAmount, String description) async {
    final currentRank = state.currentRank;
    final bonusAmount = (baseAmount * currentRank.evMultiplier).round();
    
    return await addPoints(
      bonusAmount,
      '$description (EV特典 ${currentRank.evMultiplier}x)',
      type: PointTransactionType.evBonus,
    );
  }

  Future<bool> exchangePoints(int points, String itemName) async {
    return await spendPoints(points, '$itemName (${points}pt消費)');
  }

  Future<bool> resetAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pointsKey);
      await prefs.remove(_totalEarnedKey);
      await prefs.remove(_transactionsKey);
      await prefs.remove(_lastLoginKey);
      
      await loadPointsData(); // 状態をリセット後に再読み込み
      developer.log('[SOUP] All points data reset');
      return true;
    } catch (e) {
      developer.log('[SOUP] Error resetting points data: $e');
      return false;
    }
  }
}

// Riverpodプロバイダ
final pointsProvider = StateNotifierProvider<PointsServiceNotifier, PointsState>((ref) {
  return PointsServiceNotifier();
});

