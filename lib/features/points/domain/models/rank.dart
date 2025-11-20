/// ランク計算とラベル管理
class Rank {
  final String id;
  final String label;
  final int minPoints;
  final int maxPoints;
  final double multiplier; // ポイント倍率（例: 1.0, 1.05, 1.1）

  const Rank({
    required this.id,
    required this.label,
    required this.minPoints,
    required this.maxPoints,
    required this.multiplier,
  });
}

/// ランク計算機
class RankCalculator {
  // ランク定義
  // 各ランクにポイント倍率を設定
  // Bronze: 1.0倍（基準）
  // Silver: 1.02〜1.05倍
  // Gold: 1.05〜1.1倍
  // Platinum: 1.1〜1.15倍
  static const List<Rank> ranks = [
    Rank(
      id: 'bronze',
      label: 'ブロンズ',
      minPoints: 0,
      maxPoints: 999,
      multiplier: 1.0, // 基準倍率
    ),
    Rank(
      id: 'silver',
      label: 'シルバー',
      minPoints: 1000,
      maxPoints: 4999,
      multiplier: 1.03, // 3%還元
    ),
    Rank(
      id: 'gold',
      label: 'ゴールド',
      minPoints: 5000,
      maxPoints: 19999,
      multiplier: 1.07, // 7%還元
    ),
    Rank(
      id: 'platinum',
      label: 'プラチナ',
      minPoints: 20000,
      maxPoints: 999999,
      multiplier: 1.12, // 12%還元
    ),
  ];

  /// ポイントからランクを計算
  static Rank calculate(int points) {
    for (var rank in ranks.reversed) {
      if (points >= rank.minPoints) {
        return rank;
      }
    }
    return ranks.first;
  }

  /// ランクのラベルを取得
  static String label(Rank rank) {
    return rank.label;
  }

  /// 次のランクまでのポイントを計算
  static int pointsToNextRank(int currentPoints) {
    final currentRank = calculate(currentPoints);
    if (currentRank == ranks.last) {
      return 0; // 最高ランク
    }
    final currentIndex = ranks.indexOf(currentRank);
    final nextRank = ranks[currentIndex + 1];
    return nextRank.minPoints - currentPoints;
  }

  /// 次のランクを取得
  static Rank? getNextRank(Rank currentRank) {
    if (currentRank == ranks.last) {
      return null; // 最高ランク
    }
    final currentIndex = ranks.indexOf(currentRank);
    return ranks[currentIndex + 1];
  }

  /// ランクのラベルを取得（日本語版、labelのエイリアス）
  static String labelJa(Rank rank) {
    return label(rank);
  }

  /// ランクの倍率を取得
  static double getMultiplier(Rank rank) {
    return rank.multiplier;
  }

  /// ベースポイントにランク倍率を適用して最終ポイントを計算
  ///
  /// [basePoints] ベースポイント（デイリーくじやQRスキャンの基本ポイント）
  /// [userPoints] ユーザーの現在の累計ポイント（ランク判定に使用）
  ///
  /// 戻り値: 倍率適用後のポイント（整数に丸める）
  ///
  /// 例:
  /// - Bronze (1.0倍): 100P → 100P
  /// - Silver (1.03倍): 100P → 103P
  /// - Gold (1.07倍): 100P → 107P
  /// - Platinum (1.12倍): 100P → 112P
  static int applyRankMultiplier(int basePoints, int userPoints) {
    final rank = calculate(userPoints);
    final multiplier = rank.multiplier;
    final finalPoints = (basePoints * multiplier).round();
    return finalPoints;
  }

  /// ゲスト利用時はBRONZE扱い
  /// ゲストの場合は常に1.0倍を返す
  static int applyRankMultiplierForGuest(int basePoints) {
    return basePoints; // ゲストは常に1.0倍（BRONZE相当）
  }
}
