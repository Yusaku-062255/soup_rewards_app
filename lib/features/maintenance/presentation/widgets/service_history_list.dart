import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/service_history.dart';
import '../maintenance_provider.dart';

/// サービス履歴リスト
class ServiceHistoryList extends ConsumerWidget {
  final String vehicleId;

  const ServiceHistoryList({
    super.key,
    required this.vehicleId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(serviceHistoryProvider(vehicleId));

    return historyAsync.when(
      data: (histories) {
        if (histories.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 64,
                  color: AppColors.grey400,
                ),
                const SizedBox(height: 16),
                Text(
                  '施工履歴がありません',
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
          itemCount: histories.length,
          itemBuilder: (context, index) {
            final history = histories[index];
            return _buildHistoryCard(context, history);
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

  Widget _buildHistoryCard(BuildContext context, ServiceHistory history) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getServiceTypeColor(history.serviceType)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    history.serviceType.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        history.courseName,
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
                              color: _getServiceTypeColor(history.serviceType)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              history.serviceType.displayName,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: _getServiceTypeColor(
                                        history.serviceType),
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDate(history.servicedAt),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: AppColors.textSub,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  '¥${_formatNumber(history.amount)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                ),
              ],
            ),
            if (history.technician != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 16,
                    color: AppColors.textSub,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '担当: ${history.technician}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSub,
                        ),
                  ),
                ],
              ),
            ],
            if (history.notes != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  history.notes!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
            if (history.warrantyExpiresAt != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: history.isWarrantyActive
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.grey400.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: history.isWarrantyActive
                        ? AppColors.success.withOpacity(0.3)
                        : AppColors.grey400.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      history.isWarrantyActive
                          ? Icons.verified_outlined
                          : Icons.cancel_outlined,
                      size: 16,
                      color: history.isWarrantyActive
                          ? AppColors.success
                          : AppColors.grey400,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      history.isWarrantyActive
                          ? '保証有効: ${_formatDate(history.warrantyExpiresAt!)}'
                          : '保証期限切れ',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: history.isWarrantyActive
                                ? AppColors.success
                                : AppColors.textSub,
                            fontWeight: FontWeight.w600,
                          ),
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

  Color _getServiceTypeColor(ServiceType type) {
    switch (type) {
      case ServiceType.coating:
        return AppColors.coating;
      case ServiceType.wash:
        return AppColors.carWash;
      case ServiceType.maintenance:
        return AppColors.maintenance;
      case ServiceType.repair:
        return AppColors.error;
      case ServiceType.inspection:
        return AppColors.primary;
      case ServiceType.other:
        return AppColors.grey400;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day}';
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}
