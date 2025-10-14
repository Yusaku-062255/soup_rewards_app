// ポイント管理サービス（残高・累計分離）
import 'dart:developer' as developer;

/// ポイント状態管理クラス
class PointsState {
  final int balance;        // 現在残高（交換で減算）
  final int totalEarned;    // 累計獲得（ランク判定用、交換では減らさない）
  final List<PointEntry> history; // 履歴（最新順）

  const PointsState({
    required this.balance,
    required this.totalEarned,
    required this.history,
  });

  /// 初期状態
  static const PointsState initial = PointsState(
    balance: 0,
    totalEarned: 0,
    history: [],
  );

  /// コピーメソッド
  PointsState copyWith({
    int? balance,
    int? totalEarned,
    List<PointEntry>? history,
  }) {
    return PointsState(
      balance: balance ?? this.balance,
      totalEarned: totalEarned ?? this.totalEarned,
      history: history ?? this.history,
    );
  }

  /// JSON変換
  Map<String, dynamic> toJson() => {
    'balance': balance,
    'totalEarned': totalEarned,
    'history': history.map((e) => e.toJson()).toList(),
  };

  factory PointsState.fromJson(Map<String, dynamic> json) => PointsState(
    balance: json['balance'] as int? ?? 0,
    totalEarned: json['totalEarned'] as int? ?? 0,
    history: (json['history'] as List<dynamic>?)
        ?.map((e) => PointEntry.fromJson(e as Map<String, dynamic>))
        .toList() ?? [],
  );
}

/// ポイント履歴エントリ
class PointEntry {
  final DateTime date;
  final int delta;        // +付与 / -交換
  final String title;     // "Daily Login Bonus", "Fuel Voucher Exchange"
  final String? note;     // 追加情報（オプション）

  const PointEntry({
    required this.date,
    required this.delta,
    required this.title,
    this.note,
  });

  /// JSON変換
  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'delta': delta,
    'title': title,
    if (note != null) 'note': note,
  };

  factory PointEntry.fromJson(Map<String, dynamic> json) => PointEntry(
    date: DateTime.parse(json['date'] as String),
    delta: json['delta'] as int,
    title: json['title'] as String,
    note: json['note'] as String?,
  );
}

/// ポイントサービス
class PointsService {
  /// ポイント付与
  /// basePoint × multiplier を四捨五入で加算
  static PointsState grant(
    PointsState current, {
    required int basePoint,
    required double multiplier,
    required String title,
    String? note,
  }) {
    final grantedPoints = (basePoint * multiplier).round();
    
    final entry = PointEntry(
      date: DateTime.now(),
      delta: grantedPoints,
      title: title,
      note: note,
    );

    final newState = current.copyWith(
      balance: current.balance + grantedPoints,
      totalEarned: current.totalEarned + grantedPoints,
      history: [entry, ...current.history], // 最新順
    );

    developer.log('[SOUP] Points granted: +${grantedPoints}pt ($title)');
    developer.log('[SOUP] Balance: ${newState.balance}pt, Total: ${newState.totalEarned}pt');
    
    return newState;
  }

  /// ポイント交換
  /// 現在残高から減算、累計は減らさない
  static PointsState? exchange(
    PointsState current, {
    required int cost,
    required String title,
    String? note,
  }) {
    if (current.balance < cost) {
      developer.log('[SOUP] Insufficient balance: ${current.balance} < $cost');
      return null; // 残高不足
    }

    final entry = PointEntry(
      date: DateTime.now(),
      delta: -cost,
      title: title,
      note: note,
    );

    final newState = current.copyWith(
      balance: current.balance - cost,
      // totalEarned は変更しない（ランク判定用）
      history: [entry, ...current.history], // 最新順
    );

    developer.log('[SOUP] Points exchanged: -${cost}pt ($title)');
    developer.log('[SOUP] Balance: ${newState.balance}pt, Total: ${newState.totalEarned}pt');
    
    return newState;
  }

  /// 交換可能性チェック
  static bool canExchange(PointsState current, int cost) {
    return current.balance >= cost;
  }

  /// 統計情報
  static Map<String, dynamic> getStats(PointsState state) {
    final earnedEntries = state.history.where((e) => e.delta > 0);
    final spentEntries = state.history.where((e) => e.delta < 0);
    
    return {
      'balance': state.balance,
      'totalEarned': state.totalEarned,
      'totalSpent': spentEntries.fold<int>(0, (sum, e) => sum + e.delta.abs()),
      'transactionCount': state.history.length,
      'earnedTransactions': earnedEntries.length,
      'spentTransactions': spentEntries.length,
    };
  }
}
