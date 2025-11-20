import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/user_model.dart';

/// ポイント残高表示カード（高級感のあるデザイン）
class PointsBalanceDisplay extends StatelessWidget {
  final int points;
  final VehicleType? vehicleType; // 車種区分（EV車の場合のみバッジを表示）

  const PointsBalanceDisplay({
    super.key,
    required this.points,
    this.vehicleType,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  // ダークモード: 上品なダークオレンジ × ブラウン
                  const Color(0xFF8B4513).withValues(alpha: 0.9),
                  const Color(0xFF654321).withValues(alpha: 0.8),
                ]
              : [
                  // ライトモード: カフェ感のあるオレンジ × ダークブラウン
                  const Color(0xFFFF8C42), // 上品なオレンジ
                  const Color(0xFFD2691E), // ダークオレンジ
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isDark ? const Color(0xFF8B4513) : const Color(0xFFFF8C42))
                .withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
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
              Text(
                '現在のポイント',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
              ),
              // EV車を選んだユーザーのみEVバッジを表示
              if (vehicleType == VehicleType.ev)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.electric_car,
                        size: 16,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'EV',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                      ),
                    ],
                  ),
                )
              // ガソリン車などの場合は「通常」バッジを表示（オプション）
              else if (vehicleType == VehicleType.gasoline)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '通常',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                        ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${formatter.format(points)}P',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 48,
                  letterSpacing: -1,
                  height: 1.1,
                ),
          ),
        ],
      ),
    );
  }
}
