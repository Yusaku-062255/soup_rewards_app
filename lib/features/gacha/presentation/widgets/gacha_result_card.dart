import 'package:flutter/material.dart';
import '../../domain/gacha_result.dart';

/// ガチャ結果カード
class GachaResultCard extends StatelessWidget {
  final GachaResult result;

  const GachaResultCard({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final rank = result.rank;

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _getGradientColors(rank),
          ),
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            // ランク表示
            Text(
              rank.displayName,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
            ),

            const SizedBox(height: 16),

            // 獲得ポイント
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${result.pointsAwarded}',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 64,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'ポイント',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 合計ポイント
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '合計: ${result.totalPoints}pt',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _getGradientColors(GachaRank rank) {
    switch (rank) {
      case GachaRank.legendary:
        return [
          const Color(0xFFFFD700),
          const Color(0xFFFF8C00),
        ];
      case GachaRank.epic:
        return [
          const Color(0xFF9C27B0),
          const Color(0xFF7B1FA2),
        ];
      case GachaRank.rare:
        return [
          const Color(0xFF2196F3),
          const Color(0xFF1976D2),
        ];
      case GachaRank.uncommon:
        return [
          const Color(0xFF4CAF50),
          const Color(0xFF388E3C),
        ];
      case GachaRank.common:
        return [
          const Color(0xFF9E9E9E),
          const Color(0xFF757575),
        ];
    }
  }
}
