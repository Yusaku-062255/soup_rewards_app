import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/service_history.dart';
import '../maintenance_provider.dart';

/// 保証情報リスト
class WarrantyList extends ConsumerWidget {
  final String vehicleId;

  const WarrantyList({
    super.key,
    required this.vehicleId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final warrantiesAsync = ref.watch(warrantiesProvider(vehicleId));

    return warrantiesAsync.when(
      data: (warranties) {
        if (warranties.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: 64,
                  color: AppColors.grey400,
                ),
                const SizedBox(height: 16),
                Text(
                  '保証情報がありません',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textSub,
                      ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: warranties.length,
          itemBuilder: (context, index) {
            final warranty = warranties[index];
            return _buildWarrantyCard(context, warranty);
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, _) => Center(
        child: Text('エラー: $error'),
      ),
    );
  }

  Widget _buildWarrantyCard(BuildContext context, WarrantyInfo warranty) {
    final isActive = warranty.isActive && !warranty.isExpired;
    final isExpiringSoon = warranty.isExpiringSoon;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isActive
              ? (isExpiringSoon
                  ? AppColors.warning.withOpacity(0.3)
                  : AppColors.success.withOpacity(0.3))
              : AppColors.grey400.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isActive
                        ? (isExpiringSoon
                            ? AppColors.warning.withOpacity(0.1)
                            : AppColors.success.withOpacity(0.1))
                        : AppColors.grey400.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isActive
                        ? (isExpiringSoon
                            ? Icons.warning_amber_outlined
                            : Icons.shield)
                        : Icons.shield_outlined,
                    color: isActive
                        ? (isExpiringSoon ? AppColors.warning : AppColors.success)
                        : AppColors.grey400,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        warranty.serviceName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? (isExpiringSoon
                                      ? AppColors.warning.withOpacity(0.1)
                                      : AppColors.success.withOpacity(0.1))
                                  : AppColors.grey400.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isActive
                                  ? (isExpiringSoon ? '期限間近' : '有効')
                                  : '期限切れ',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: isActive
                                        ? (isExpiringSoon
                                            ? AppColors.warning
                                            : AppColors.success)
                                        : AppColors.grey400,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.event,
                        size: 16,
                        color: AppColors.textSub,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '開始日',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSub,
                            ),
                      ),
                      const Spacer(),
                      Text(
                        _formatDate(warranty.startDate),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.event_busy,
                        size: 16,
                        color: AppColors.textSub,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '期限',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSub,
                            ),
                      ),
                      const Spacer(),
                      Text(
                        _formatDate(warranty.expiresAt),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isActive
                                  ? (isExpiringSoon
                                      ? AppColors.warning
                                      : AppColors.success)
                                  : AppColors.error,
                            ),
                      ),
                    ],
                  ),
                  if (isActive) ...[
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 16,
                          color: AppColors.textSub,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '残り日数',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSub,
                                  ),
                        ),
                        const Spacer(),
                        Text(
                          '${warranty.daysRemaining}日',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isExpiringSoon
                                    ? AppColors.warning
                                    : AppColors.success,
                              ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (warranty.coverageDetails != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '保証内容',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      warranty.coverageDetails!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }
}
