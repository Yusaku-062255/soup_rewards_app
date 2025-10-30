/// ガチャ結果モデル
class GachaResult {
  final int pointsAwarded;
  final int totalPoints;
  final int streak;
  final DateTime nextClaimAt;

  const GachaResult({
    required this.pointsAwarded,
    required this.totalPoints,
    required this.streak,
    required this.nextClaimAt,
  });

  factory GachaResult.fromJson(Map<String, dynamic> json) {
    return GachaResult(
      pointsAwarded: json['pointsAwarded'] as int,
      totalPoints: json['totalPoints'] as int,
      streak: json['streak'] as int,
      nextClaimAt: DateTime.parse(json['nextClaimAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pointsAwarded': pointsAwarded,
      'totalPoints': totalPoints,
      'streak': streak,
      'nextClaimAt': nextClaimAt.toIso8601String(),
    };
  }

  /// 獲得ポイントのランク判定
  GachaRank get rank {
    if (pointsAwarded >= 500) return GachaRank.legendary;
    if (pointsAwarded >= 100) return GachaRank.epic;
    if (pointsAwarded >= 30) return GachaRank.rare;
    if (pointsAwarded >= 10) return GachaRank.uncommon;
    return GachaRank.common;
  }

  @override
  String toString() {
    return 'GachaResult(pointsAwarded: $pointsAwarded, totalPoints: $totalPoints, streak: $streak)';
  }
}

/// ガチャランク
enum GachaRank {
  common('コモン', 5),
  uncommon('アンコモン', 10),
  rare('レア', 30),
  epic('エピック', 100),
  legendary('レジェンダリー', 500);

  final String displayName;
  final int minPoints;

  const GachaRank(this.displayName, this.minPoints);
}

/// ガチャ状態
enum GachaStatus {
  available('実行可能'),
  alreadyClaimed('本日実行済み'),
  loading('実行中'),
  error('エラー');

  final String displayName;

  const GachaStatus(this.displayName);
}
