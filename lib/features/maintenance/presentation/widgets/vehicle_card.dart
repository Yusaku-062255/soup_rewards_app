import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/vehicle.dart';

/// 車両カード
class VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback? onTap;

  const VehicleCard({
    super.key,
    required this.vehicle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = vehicle.maintenanceStatus;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getStatusColor(status).withOpacity(0.3),
            width: 2,
          ),
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
                // 車両アイコン
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.maintenance.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.directions_car,
                    color: AppColors.maintenance,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),

                // 車両情報
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      if (vehicle.licensePlate != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          vehicle.licensePlate!,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSub,
                                  ),
                        ),
                      ],
                      if (vehicle.make != null && vehicle.model != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${vehicle.make} ${vehicle.model}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSub,
                                  ),
                        ),
                      ],
                    ],
                  ),
                ),

                // ステータスバッジ
                _buildStatusBadge(context, status),
              ],
            ),

            const SizedBox(height: 16),

            // メンテナンス情報
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getStatusColor(status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _getStatusIcon(status),
                    color: _getStatusColor(status),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '次回メンテナンス',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSub,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDate(vehicle.nextMaintenanceAt),
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: _getStatusColor(status),
                              ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _getDaysUntilText(vehicle.daysUntilMaintenance),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: _getStatusColor(status),
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

  Widget _buildStatusBadge(BuildContext context, MaintenanceStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getStatusColor(status).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        status.displayName,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: _getStatusColor(status),
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Color _getStatusColor(MaintenanceStatus status) {
    switch (status) {
      case MaintenanceStatus.ok:
        return AppColors.success;
      case MaintenanceStatus.soon:
        return AppColors.warning;
      case MaintenanceStatus.overdue:
        return AppColors.error;
    }
  }

  IconData _getStatusIcon(MaintenanceStatus status) {
    switch (status) {
      case MaintenanceStatus.ok:
        return Icons.check_circle_outline;
      case MaintenanceStatus.soon:
        return Icons.warning_amber_outlined;
      case MaintenanceStatus.overdue:
        return Icons.error_outline;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }

  String _getDaysUntilText(int days) {
    if (days < 0) {
      return '${days.abs()}日超過';
    } else if (days == 0) {
      return '本日';
    } else {
      return 'あと${days}日';
    }
  }
}
