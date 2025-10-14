// ランクサービス（EV優遇・倍率計算）
import 'dart:developer' as developer;

enum MemberRank {
  bronze,
  silver,
  gold,
  platinum,
  evElite,
}

class RankService {
  // ランク閾値（累計獲得ポイント基準）
  static const Map<MemberRank, int> rankThresholds = {
    MemberRank.bronze: 0,
    MemberRank.silver: 100,
    MemberRank.gold: 300,
    MemberRank.platinum: 600,
    MemberRank.evElite: 1000,
  };

  // ランク名称
  static const Map<MemberRank, String> rankNames = {
    MemberRank.bronze: 'Bronze',
    MemberRank.silver: 'Silver',
    MemberRank.gold: 'Gold',
    MemberRank.platinum: 'Platinum',
    MemberRank.evElite: 'EV Elite',
  };

  // ランク基本倍率
  static const Map<MemberRank, double> baseMultipliers = {
    MemberRank.bronze: 1.0,
    MemberRank.silver: 1.1,
    MemberRank.gold: 1.2,
    MemberRank.platinum: 1.3,
    MemberRank.evElite: 1.5,
  };

  /// 累計獲得ポイントからランクを計算
  static MemberRank calculateRank(int totalEarned) {
    if (totalEarned >= rankThresholds[MemberRank.evElite]!) {
      return MemberRank.evElite;
    } else if (totalEarned >= rankThresholds[MemberRank.platinum]!) {
      return MemberRank.platinum;
    } else if (totalEarned >= rankThresholds[MemberRank.gold]!) {
      return MemberRank.gold;
    } else if (totalEarned >= rankThresholds[MemberRank.silver]!) {
      return MemberRank.silver;
    }
    return MemberRank.bronze;
  }

  /// 効果的な倍率を計算（EV優遇含む）
  static double effectiveMultiplier(int totalEarned, {bool hasEv = false}) {
    final rank = calculateRank(totalEarned);
    final baseMultiplier = baseMultipliers[rank] ?? 1.0;
    
    // EV優遇：追加10%ボーナス
    final evBonus = hasEv ? 0.1 : 0.0;
    final effectiveMultiplier = baseMultiplier + evBonus;
    
    developer.log('[SOUP] Rank: ${rankNames[rank]}, Base: ${baseMultiplier}x, EV: ${hasEv ? "+0.1x" : "none"}, Effective: ${effectiveMultiplier}x');
    
    return effectiveMultiplier;
  }

  /// 次のランクまでの必要ポイント
  static int pointsToNextRank(int totalEarned) {
    final currentRank = calculateRank(totalEarned);
    final nextRankThreshold = _getNextRankThreshold(currentRank);
    
    if (nextRankThreshold == null) {
      return 0; // 最高ランク
    }
    
    return nextRankThreshold - totalEarned;
  }

  /// 次のランク進捗率（0.0 - 1.0）
  static double rankProgress(int totalEarned) {
    final currentRank = calculateRank(totalEarned);
    final currentThreshold = rankThresholds[currentRank] ?? 0;
    final nextThreshold = _getNextRankThreshold(currentRank);
    
    if (nextThreshold == null) {
      return 1.0; // 最高ランク
    }
    
    final progress = (totalEarned - currentThreshold) / (nextThreshold - currentThreshold);
    return progress.clamp(0.0, 1.0);
  }

  /// 次のランク名
  static String? nextRankName(int totalEarned) {
    final currentRank = calculateRank(totalEarned);
    final nextRank = _getNextRank(currentRank);
    return nextRank != null ? rankNames[nextRank] : null;
  }

  /// ランクアップ判定
  static bool isRankUp(int oldTotalEarned, int newTotalEarned) {
    final oldRank = calculateRank(oldTotalEarned);
    final newRank = calculateRank(newTotalEarned);
    return newRank != oldRank;
  }

  /// 次のランク閾値を取得
  static int? _getNextRankThreshold(MemberRank currentRank) {
    final nextRank = _getNextRank(currentRank);
    return nextRank != null ? rankThresholds[nextRank] : null;
  }

  /// 次のランクを取得
  static MemberRank? _getNextRank(MemberRank currentRank) {
    switch (currentRank) {
      case MemberRank.bronze:
        return MemberRank.silver;
      case MemberRank.silver:
        return MemberRank.gold;
      case MemberRank.gold:
        return MemberRank.platinum;
      case MemberRank.platinum:
        return MemberRank.evElite;
      case MemberRank.evElite:
        return null; // 最高ランク
    }
  }

  /// ランク色を取得
  static List<int> getRankColors(MemberRank rank) {
    switch (rank) {
      case MemberRank.bronze:
        return [0xFF8D6E63, 0xFFBCAAA4];
      case MemberRank.silver:
        return [0xFF90A4AE, 0xFFCFD8DC];
      case MemberRank.gold:
        return [0xFFFFB300, 0xFFFFC107];
      case MemberRank.platinum:
        return [0xFF37474F, 0xFF607D8B];
      case MemberRank.evElite:
        return [0xFFFF6F00, 0xFFFFD54F];
    }
  }

  /// デバッグ情報
  static Map<String, dynamic> getDebugInfo(int totalEarned, {bool hasEv = false}) {
    final rank = calculateRank(totalEarned);
    return {
      'totalEarned': totalEarned,
      'currentRank': rankNames[rank],
      'rankIndex': rank.index,
      'baseMultiplier': baseMultipliers[rank],
      'hasEv': hasEv,
      'effectiveMultiplier': effectiveMultiplier(totalEarned, hasEv: hasEv),
      'pointsToNext': pointsToNextRank(totalEarned),
      'progress': rankProgress(totalEarned),
      'nextRank': nextRankName(totalEarned),
    };
  }
}
