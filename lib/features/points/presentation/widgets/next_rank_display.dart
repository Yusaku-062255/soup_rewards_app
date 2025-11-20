import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/rank.dart';

/// 次のランクまでの表示（バッジ風デザイン）
class NextRankDisplay extends StatelessWidget {
  final int currentPoints;

  const NextRankDisplay({
    super.key,
    required this.currentPoints,
  });

  @override
  Widget build(BuildContext context) {
    final currentRank = RankCalculator.calculate(currentPoints);
    final pointsToNext = RankCalculator.pointsToNextRank(currentPoints);
    final nextRank = RankCalculator.getNextRank(currentRank);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // 現在のランク表示（バッジ風）
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _getRankGradient(currentRank, isDark),
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _getRankBorderColor(currentRank, isDark),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: _getRankShadowColor(currentRank).withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              // ランクアイコン（リング風）
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.2),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    _getRankIcon(currentRank),
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '現在のランク',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                RankCalculator.label(currentRank),
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  fontSize: 28,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        
        // 次のランクまで
        if (nextRank != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.grey800 : AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.grey700 : AppColors.grey200,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.trending_up,
                          size: 20,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '次のランク: ${RankCalculator.label(nextRank)}',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'あと ${pointsToNext}P',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _calculateProgress(currentPoints, currentRank, nextRank),
                    backgroundColor: isDark
                        ? AppColors.grey700
                        : AppColors.grey200,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 10,
                  ),
                ),
              ],
            ),
          )
        else
          // 最高ランク達成
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.15),
                  AppColors.secondary.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.stars_rounded,
                    color: AppColors.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '最高ランク達成！',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'おめでとうございます',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// ランクに応じたグラデーション色を取得
  List<Color> _getRankGradient(Rank rank, bool isDark) {
    switch (rank.id) {
      case 'bronze':
        return isDark
            ? [
                const Color(0xFF8B4513).withValues(alpha: 0.8),
                const Color(0xFF654321).withValues(alpha: 0.7),
              ]
            : [
                const Color(0xFFCD7F32), // ブロンズ
                const Color(0xFFB87333),
              ];
      case 'silver':
        return isDark
            ? [
                const Color(0xFF708090).withValues(alpha: 0.8),
                const Color(0xFF556B2F).withValues(alpha: 0.7),
              ]
            : [
                const Color(0xFFC0C0C0), // シルバー
                const Color(0xFFA8A8A8),
              ];
      case 'gold':
        return isDark
            ? [
                const Color(0xFFDAA520).withValues(alpha: 0.8),
                const Color(0xFFB8860B).withValues(alpha: 0.7),
              ]
            : [
                const Color(0xFFFFD700), // ゴールド
                const Color(0xFFFFC125),
              ];
      case 'platinum':
        return isDark
            ? [
                const Color(0xFFE5E4E2).withValues(alpha: 0.8),
                const Color(0xFFD3D3D3).withValues(alpha: 0.7),
              ]
            : [
                const Color(0xFFE5E4E2), // プラチナ
                const Color(0xFFD3D3D3),
              ];
      default:
        // フォールバック（通常は到達しない）
        return [
          AppColors.primary,
          AppColors.secondary,
        ];
    }
  }

  /// ランクに応じたボーダー色を取得
  Color _getRankBorderColor(Rank rank, bool isDark) {
    switch (rank.id) {
      case 'bronze':
        return isDark
            ? const Color(0xFF8B4513).withValues(alpha: 0.5)
            : const Color(0xFFCD7F32).withValues(alpha: 0.6);
      case 'silver':
        return isDark
            ? const Color(0xFF708090).withValues(alpha: 0.5)
            : const Color(0xFFC0C0C0).withValues(alpha: 0.6);
      case 'gold':
        return isDark
            ? const Color(0xFFDAA520).withValues(alpha: 0.5)
            : const Color(0xFFFFD700).withValues(alpha: 0.6);
      case 'platinum':
        return isDark
            ? const Color(0xFFE5E4E2).withValues(alpha: 0.5)
            : const Color(0xFFE5E4E2).withValues(alpha: 0.6);
      default:
        // フォールバック（通常は到達しない）
        return AppColors.primary.withValues(alpha: 0.6);
    }
  }

  /// ランクに応じたシャドウ色を取得
  Color _getRankShadowColor(Rank rank) {
    switch (rank.id) {
      case 'bronze':
        return const Color(0xFFCD7F32);
      case 'silver':
        return const Color(0xFFC0C0C0);
      case 'gold':
        return const Color(0xFFFFD700);
      case 'platinum':
        return const Color(0xFFE5E4E2);
      default:
        // フォールバック（通常は到達しない）
        return AppColors.primary;
    }
  }

  /// ランクに応じたアイコンを取得
  IconData _getRankIcon(Rank rank) {
    switch (rank.id) {
      case 'bronze':
      case 'silver':
      case 'gold':
      case 'platinum':
        return Icons.workspace_premium;
      default:
        // フォールバック（通常は到達しない）
        return Icons.star;
    }
  }

  /// 進捗率を計算
  double _calculateProgress(int points, Rank currentRank, Rank? nextRank) {
    if (nextRank == null) return 1.0;

    // ランクの閾値を取得
    final currentThreshold = _getRankThreshold(currentRank);
    final nextThreshold = _getRankThreshold(nextRank);
    
    if (nextThreshold == currentThreshold) return 1.0;
    
    final progress = (points - currentThreshold) / (nextThreshold - currentThreshold);
    return progress.clamp(0.0, 1.0);
  }

  /// ランクの閾値を取得
  int _getRankThreshold(Rank rank) {
    switch (rank.id) {
      case 'bronze':
        return 0;
      case 'silver':
        return 1000;
      case 'gold':
        return 5000;
      case 'platinum':
        return 20000;
      default:
        // フォールバック（通常は到達しない）
        return 0;
    }
  }
}
