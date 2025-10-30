import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/tip.dart';
import '../tips_provider.dart';

/// 季節チェックリスト
class SeasonalChecklist extends ConsumerWidget {
  final Season season;

  const SeasonalChecklist({
    super.key,
    required this.season,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checklistAsync = ref.watch(seasonalChecklistProvider(season));

    return checklistAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return const SizedBox.shrink();
        }

        final completedCount = items.where((item) => item.isCompleted).length;
        final progress = items.isNotEmpty ? completedCount / items.length : 0.0;

        return Container(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    season.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${season.displayName}のチェックリスト',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$completedCount / ${items.length} 完了',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSub,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: AppColors.grey200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress == 1.0 ? AppColors.success : AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ...items.map((item) {
                return _buildChecklistItem(context, ref, item);
              }),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildChecklistItem(
    BuildContext context,
    WidgetRef ref,
    ChecklistItem item,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: item.isCompleted
              ? AppColors.success.withOpacity(0.05)
              : AppColors.grey100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: item.isCompleted
                ? AppColors.success.withOpacity(0.3)
                : AppColors.grey300,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Checkbox(
              value: item.isCompleted,
              onChanged: (value) async {
                final repository = ref.read(tipsRepositoryProvider);
                await repository.toggleChecklistItem(item.id, value ?? false);
                // Refresh the checklist
                ref.invalidate(seasonalChecklistProvider(season));
              },
              activeColor: AppColors.success,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          decoration: item.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: item.isCompleted
                              ? AppColors.textSub
                              : AppColors.textMain,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSub,
                        ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getCategoryColor(item.category).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                item.category.emoji,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(TipCategory category) {
    switch (category) {
      case TipCategory.wash:
        return AppColors.carWash;
      case TipCategory.coating:
        return AppColors.coating;
      case TipCategory.maintenance:
        return AppColors.maintenance;
      case TipCategory.seasonal:
        return AppColors.secondary;
      case TipCategory.general:
        return AppColors.primary;
    }
  }
}
