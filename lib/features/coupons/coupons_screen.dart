import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../design/theme.dart';
import '../../design/widgets/soup_card.dart';
import '../../design/widgets/soup_section_title.dart';
import 'coupons_repository.dart';

final selectedFilterProvider = StateProvider<CouponFilter>((ref) => CouponFilter.active);

class CouponsScreen extends ConsumerWidget {
  const CouponsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to view your coupons.'),
        ),
      );
    }

    final selectedFilter = ref.watch(selectedFilterProvider);
    final couponsRepo = ref.watch(couponsRepositoryProvider);
    final couponsStream = couponsRepo.myCoupons(user.uid, filter: selectedFilter);

    return Scaffold(
      backgroundColor: DesignTokens.surface,
      appBar: AppBar(
        title: const Text('クーポン'),
        backgroundColor: DesignTokens.primary,
        foregroundColor: DesignTokens.onPrimary,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter chips
          Container(
            padding: const EdgeInsets.all(DesignTokens.spaceBase),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                    context,
                    ref,
                    label: '利用可能',
                    filter: CouponFilter.active,
                    isSelected: selectedFilter == CouponFilter.active,
                  ),
                  const SizedBox(width: DesignTokens.spaceSmall),
                  _buildFilterChip(
                    context,
                    ref,
                    label: '使用済',
                    filter: CouponFilter.redeemed,
                    isSelected: selectedFilter == CouponFilter.redeemed,
                  ),
                  const SizedBox(width: DesignTokens.spaceSmall),
                  _buildFilterChip(
                    context,
                    ref,
                    label: '期限切れ',
                    filter: CouponFilter.expired,
                    isSelected: selectedFilter == CouponFilter.expired,
                  ),
                  const SizedBox(width: DesignTokens.spaceSmall),
                  _buildFilterChip(
                    context,
                    ref,
                    label: 'すべて',
                    filter: CouponFilter.all,
                    isSelected: selectedFilter == CouponFilter.all,
                  ),
                ],
              ),
            ),
          ),

          // Coupons list
          Expanded(
            child: StreamBuilder<List<Coupon>>(
              stream: couponsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('エラー: ${snapshot.error}'),
                  );
                }

                final coupons = snapshot.data ?? [];
                if (coupons.isEmpty) {
                  return const Center(
                    child: Text('クーポンがありません'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(DesignTokens.spaceBase),
                  itemCount: coupons.length,
                  itemBuilder: (context, index) {
                    return _buildCouponCard(context, ref, coupons[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required CouponFilter filter,
    required bool isSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          ref.read(selectedFilterProvider.notifier).state = filter;
        }
      },
      backgroundColor: DesignTokens.card,
      selectedColor: DesignTokens.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : DesignTokens.textPrimary,
      ),
      checkmarkColor: Colors.white,
    );
  }

  Widget _buildCouponCard(BuildContext context, WidgetRef ref, Coupon coupon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.spaceBase),
      child: SoupCard(
        onTap: coupon.isActive ? () => _showCouponDetail(context, ref, coupon) : null,
        backgroundColor: coupon.isActive ? DesignTokens.card : DesignTokens.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: coupon.isActive
                        ? DesignTokens.accentMint
                        : DesignTokens.textSecondary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    CupertinoIcons.ticket,
                    color: coupon.isActive ? DesignTokens.primary : DesignTokens.textSecondary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: DesignTokens.spaceBase),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        coupon.title,
                        style: TextStyle(
                          fontSize: DesignTokens.fontSizeBody,
                          fontWeight: FontWeight.bold,
                          color: coupon.isActive
                              ? DesignTokens.textPrimary
                              : DesignTokens.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        coupon.description,
                        style: const TextStyle(
                          fontSize: DesignTokens.fontSizeCaption,
                          color: DesignTokens.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.spaceSmall),
            Divider(color: DesignTokens.textSecondary.withOpacity(0.2)),
            const SizedBox(height: DesignTokens.spaceSmall),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '有効期限: ${_formatDate(coupon.expiresAt)}',
                  style: const TextStyle(
                    fontSize: DesignTokens.fontSizeSmall,
                    color: DesignTokens.textSecondary,
                  ),
                ),
                _buildStatusChip(coupon),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(Coupon coupon) {
    Color color;
    String label;

    if (coupon.isRedeemed) {
      color = DesignTokens.textSecondary;
      label = '使用済';
    } else if (coupon.isExpired) {
      color = DesignTokens.error;
      label = '期限切れ';
    } else {
      color = DesignTokens.success;
      label = '利用可能';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spaceSmall,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: DesignTokens.fontSizeSmall,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}/${dt.month}/${dt.day}';
  }

  Future<void> _showCouponDetail(BuildContext context, WidgetRef ref, Coupon coupon) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(DesignTokens.spaceHeading),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: DesignTokens.textSecondary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.spaceBase),

              // Coupon details
              Icon(
                CupertinoIcons.ticket_fill,
                size: 64,
                color: DesignTokens.primary,
              ),
              const SizedBox(height: DesignTokens.spaceBase),
              Text(
                coupon.title,
                style: const TextStyle(
                  fontSize: DesignTokens.fontSizeH2,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: DesignTokens.spaceSmall),
              Text(
                coupon.description,
                style: const TextStyle(
                  fontSize: DesignTokens.fontSizeBody,
                  color: DesignTokens.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              if (coupon.code != null) ...[
                const SizedBox(height: DesignTokens.spaceBase),
                Container(
                  padding: const EdgeInsets.all(DesignTokens.spaceBase),
                  decoration: BoxDecoration(
                    color: DesignTokens.surface,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
                  ),
                  child: Text(
                    'コード: ${coupon.code}',
                    style: const TextStyle(
                      fontSize: DesignTokens.fontSizeBody,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: DesignTokens.spaceBase),
              Text(
                '有効期限: ${_formatDate(coupon.expiresAt)}',
                style: const TextStyle(
                  fontSize: DesignTokens.fontSizeCaption,
                  color: DesignTokens.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: DesignTokens.spaceSection),

              // Redeem button
              ElevatedButton(
                onPressed: () => _redeemCoupon(context, ref, coupon),
                child: const Text('このクーポンを使う'),
              ),
              const SizedBox(height: DesignTokens.spaceSmall),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('キャンセル'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _redeemCoupon(BuildContext context, WidgetRef ref, Coupon coupon) async {
    Navigator.of(context).pop(); // Close bottom sheet

    try {
      final couponsRepo = ref.read(couponsRepositoryProvider);
      await couponsRepo.redeem(coupon.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('クーポンを使用しました'),
            backgroundColor: DesignTokens.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('クーポンの使用に失敗しました: $e'),
            backgroundColor: DesignTokens.error,
          ),
        );
      }
    }
  }
}
