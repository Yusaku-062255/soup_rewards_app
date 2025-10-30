import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/tip.dart';
import '../tips_provider.dart';
import '../widgets/tip_card.dart';
import '../widgets/seasonal_checklist.dart';

/// アフターケアTipsページ
class TipsPage extends ConsumerWidget {
  const TipsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendedTipsAsync = ref.watch(recommendedTipsProvider);
    final currentSeason = Season.current;

    return Container(
      color: AppColors.white,
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // 季節バッジ
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadowLight,
                          offset: const Offset(0, 4),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Text(
                          currentSeason.emoji,
                          style: const TextStyle(fontSize: 32),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '現在の季節',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.textSub,
                                  ),
                            ),
                            Text(
                              currentSeason.displayName,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // 季節チェックリスト
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SeasonalChecklist(season: currentSeason),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // おすすめTips
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'おすすめTips',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // Tipsリスト
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: recommendedTipsAsync.when(
                  data: (tips) {
                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final tip = tips[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TipCard(tip: tip),
                          );
                        },
                        childCount: tips.length,
                      ),
                    );
                  },
                  loading: () => const SliverToBoxAdapter(
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (error, _) => SliverToBoxAdapter(
                    child: Center(
                      child: Text('エラー: $error'),
                    ),
                  ),
                ),
              ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}
