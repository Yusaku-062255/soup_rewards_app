import 'package:flutter/material.dart';
import '../../../core/theme/soup_theme.dart';
import '../../../core/models/coupon_model.dart';

/// クーポンカードウィジェット
class CouponCard extends StatelessWidget {
  final CouponModel coupon;
  final VoidCallback? onUse;
  final bool isUsed;

  const CouponCard({
    super.key,
    required this.coupon,
    this.onUse,
    required this.isUsed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(SoupTheme.radiusL),
        boxShadow: [
          BoxShadow(
            color: SoupTheme.cardShadow,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(SoupTheme.radiusL),
        child: Stack(
          children: [
            // メインカード
            Container(
              decoration: BoxDecoration(
                gradient: isUsed
                    ? LinearGradient(
                        colors: [
                          Colors.grey[300]!,
                          Colors.grey[400]!,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : _getCouponGradient(),
              ),
              child: Row(
                children: [
                  // 左側：割引情報
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.all(SoupTheme.spacingL),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 割引額
                          Text(
                            _getDiscountText(),
                            style: SoupTheme.headingLarge.copyWith(
                              color: SoupTheme.textWhite,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          
                          const SizedBox(height: 4),
                          
                          // タイトル
                          Text(
                            coupon.title,
                            style: SoupTheme.bodyLarge.copyWith(
                              color: SoupTheme.textWhite,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          
                          const SizedBox(height: SoupTheme.spacingS),
                          
                          // 説明
                          Text(
                            coupon.description,
                            style: SoupTheme.bodySmall.copyWith(
                              color: SoupTheme.textWhite.withOpacity(0.9),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          
                          const SizedBox(height: SoupTheme.spacingM),
                          
                          // 有効期限
                          Row(
                            children: [
                              Icon(
                                SoupIcons.time,
                                color: SoupTheme.textWhite.withOpacity(0.8),
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${_formatDate(coupon.expiryDate)}まで',
                                style: SoupTheme.bodySmall.copyWith(
                                  color: SoupTheme.textWhite.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // 右側：アクション部分
                  Expanded(
                    flex: 1,
                    child: Container(
                      height: 160,
                      decoration: BoxDecoration(
                        color: SoupTheme.textWhite.withOpacity(0.1),
                        border: Border(
                          left: BorderSide(
                            color: SoupTheme.textWhite.withOpacity(0.3),
                            width: 1,
                            style: BorderStyle.solid,
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // カテゴリアイコン
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: SoupTheme.textWhite.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getCategoryIcon(),
                              color: SoupTheme.textWhite,
                              size: 24,
                            ),
                          ),
                          
                          const SizedBox(height: SoupTheme.spacingM),
                          
                          // アクションボタン
                          if (!isUsed && onUse != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: SoupTheme.spacingS,
                              ),
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isExpired() ? null : onUse,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: SoupTheme.textWhite,
                                    foregroundColor: _getCouponColor(),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    _isExpired() ? '期限切れ' : '使用する',
                                    style: SoupTheme.bodySmall.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: SoupTheme.textWhite.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isUsed ? '使用済み' : '利用可能',
                                style: SoupTheme.bodySmall.copyWith(
                                  color: SoupTheme.textWhite,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // 使用済みオーバーレイ
            if (isUsed)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(SoupTheme.radiusL),
                  ),
                  child: Center(
                    child: Transform.rotate(
                      angle: -0.2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '使用済み',
                          style: SoupTheme.bodyLarge.copyWith(
                            color: SoupTheme.textWhite,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            
            // 期限切れオーバーレイ
            if (!isUsed && _isExpired())
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(SoupTheme.radiusL),
                  ),
                  child: Center(
                    child: Transform.rotate(
                      angle: -0.2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '期限切れ',
                          style: SoupTheme.bodyLarge.copyWith(
                            color: SoupTheme.textWhite,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Gradient _getCouponGradient() {
    switch (coupon.category) {
      case 'points_exchange':
        return SoupTheme.goldGradient;
      case 'service_completion':
        return SoupTheme.navyGradient;
      case 'campaign':
        return const LinearGradient(
          colors: [SoupTheme.accentOrange, Color(0xFFFF6B35)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'birthday':
        return const LinearGradient(
          colors: [Colors.purple, Colors.pinkAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return SoupTheme.navyGradient;
    }
  }

  Color _getCouponColor() {
    switch (coupon.category) {
      case 'points_exchange':
        return SoupTheme.primaryGold;
      case 'service_completion':
        return SoupTheme.primaryNavy;
      case 'campaign':
        return SoupTheme.accentOrange;
      case 'birthday':
        return Colors.purple;
      default:
        return SoupTheme.primaryNavy;
    }
  }

  IconData _getCategoryIcon() {
    switch (coupon.category) {
      case 'points_exchange':
        return SoupIcons.points;
      case 'service_completion':
        return SoupIcons.service;
      case 'campaign':
        return Icons.campaign;
      case 'birthday':
        return Icons.cake;
      default:
        return SoupIcons.coupon;
    }
  }

  String _getDiscountText() {
    if (coupon.discountType == 'fixed') {
      return '¥${coupon.discountValue.toInt()}';
    } else {
      return '${coupon.discountValue.toInt()}%';
    }
  }

  bool _isExpired() {
    return DateTime.now().isAfter(coupon.expiryDate);
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day}';
  }
}
