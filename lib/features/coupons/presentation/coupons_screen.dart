import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../design/theme.dart';
import '../../../design/widgets/soup_card.dart';
import '../../../design/widgets/soup_section_title.dart';
import '../data/coupons_repository.dart';
import '../domain/models/coupon.dart';

class CouponsScreen extends ConsumerStatefulWidget {
  const CouponsScreen({super.key});

  @override
  ConsumerState<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends ConsumerState<CouponsScreen> {
  bool _isRedeeming = false;
  CouponTemplate? _template;

  @override
  void initState() {
    super.initState();
    _loadTemplate();
  }

  Future<void> _loadTemplate() async {
    final repo = ref.read(couponsRepositoryProvider);
    try {
      final template = await repo.getFuelVoucherTemplate();
      if (template == null) {
        // Template doesn't exist, create it
        await repo.ensureFuelVoucherTemplate();
        final newTemplate = await repo.getFuelVoucherTemplate();
        if (mounted) {
          setState(() => _template = newTemplate);
        }
      } else {
        if (mounted) {
          setState(() => _template = template);
        }
      }
    } catch (e) {
      print('Error loading template: $e');
    }
  }

  String _getErrorMessage(Object error) {
    final errorString = error.toString();

    // Firebase Functions エラー
    if (errorString.contains('insufficient_points')) {
      return 'ポイントが不足しています';
    } else if (errorString.contains('invalid_staff_pin')) {
      return 'スタッフ用PINが正しくありません';
    } else if (errorString.contains('already_redeemed')) {
      return 'このクーポンは既に使用済みです';
    } else if (errorString.contains('expired')) {
      return 'このクーポンは有効期限が切れています';
    } else if (errorString.contains('functions/not-found')) {
      return 'クーポンが見つかりません';
    } else if (errorString.contains('functions/unauthenticated')) {
      return 'ログインが必要です。再度ログインしてください。';
    } else if (errorString.contains('functions/permission-denied')) {
      return '権限がありません';
    } else if (errorString.contains('functions/unavailable')) {
      return 'サーバーに接続できません。ネットワーク接続を確認してください。';
    } else if (errorString.contains('functions/deadline-exceeded')) {
      return '処理がタイムアウトしました。もう一度お試しください。';
    }

    // ネットワークエラー
    if (errorString.contains('SocketException') ||
        errorString.contains('NetworkError')) {
      return 'ネットワーク接続を確認してください。';
    }

    // その他のエラー
    return 'エラーが発生しました。もう一度お試しください。';
  }

  Future<void> _redeemFuelVoucher(BuildContext context) async {
    if (_template == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('テンプレートを読み込んでいます...'),
          backgroundColor: DesignTokens.warning,
        ),
      );
      return;
    }

    setState(() => _isRedeeming = true);

    try {
      final repo = ref.read(couponsRepositoryProvider);
      final result = await repo.redeemPointsForFuelVoucher(_template!.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('給油券を発行しました！ コード: ${result['code']}'),
            backgroundColor: DesignTokens.success,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getErrorMessage(e)),
            backgroundColor: DesignTokens.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRedeeming = false);
      }
    }
  }

  Future<void> _useAtStore(BuildContext context, Coupon coupon) async {
    final staffPin = await showDialog<String>(
      context: context,
      builder: (context) => _StaffPinDialog(),
    );

    if (staffPin == null || staffPin.isEmpty) {
      return;
    }

    if (!mounted) return;

    try {
      final repo = ref.read(couponsRepositoryProvider);
      await repo.redeemAtStore(
        couponId: coupon.id,
        centerId: 'default', // TODO: 複数店舗対応時に選択可能にする
        staffPin: staffPin,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'クーポンを使用しました！ ${coupon.meta.discountValueYen}円割引'),
            backgroundColor: DesignTokens.success,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getErrorMessage(e)),
            backgroundColor: DesignTokens.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('ログインしてください'),
        ),
      );
    }

    final repo = ref.watch(couponsRepositoryProvider);
    final couponsStream = repo.myCoupons(user.uid);

    return Scaffold(
      backgroundColor: DesignTokens.surface,
      appBar: AppBar(
        title: const Text('クーポン'),
        backgroundColor: DesignTokens.primary,
        foregroundColor: DesignTokens.onPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with fuel voucher info
            if (_template != null)
              Container(
                padding: const EdgeInsets.all(DesignTokens.spaceHeading),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      DesignTokens.primary,
                      DesignTokens.accentMint,
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      CupertinoIcons.ticket_fill,
                      size: 64,
                      color: Colors.white,
                    ),
                    const SizedBox(height: DesignTokens.spaceSmall),
                    Text(
                      _template!.title,
                      style: const TextStyle(
                        fontSize: DesignTokens.fontSizeH2,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spaceSmall),
                    Text(
                      '${_template!.discountValueYen}円割引',
                      style: const TextStyle(
                        fontSize: DesignTokens.fontSizeH3,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(DesignTokens.spaceBase),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Redeem button
                  if (_template != null)
                    SoupCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '必要ポイント',
                                style: TextStyle(
                                  fontSize: DesignTokens.fontSizeBody,
                                  color: DesignTokens.textSecondary,
                                ),
                              ),
                              Text(
                                '${_template!.pointsCost} pt',
                                style: const TextStyle(
                                  fontSize: DesignTokens.fontSizeH3,
                                  fontWeight: FontWeight.bold,
                                  color: DesignTokens.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: DesignTokens.spaceSmall),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '有効期限',
                                style: TextStyle(
                                  fontSize: DesignTokens.fontSizeBody,
                                  color: DesignTokens.textSecondary,
                                ),
                              ),
                              Text(
                                '発行から${_template!.validityDays}日間',
                                style: const TextStyle(
                                  fontSize: DesignTokens.fontSizeBody,
                                  color: DesignTokens.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: DesignTokens.spaceBase),
                          ElevatedButton.icon(
                            onPressed: _isRedeeming
                                ? null
                                : () => _redeemFuelVoucher(context),
                            icon: _isRedeeming
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(CupertinoIcons.ticket),
                            label: const Text('給油券に交換'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: DesignTokens.spaceBase * 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: DesignTokens.spaceSection),

                  // My coupons list
                  const SoupSectionTitle(title: 'マイクーポン'),
                  const SizedBox(height: DesignTokens.spaceBase),

                  StreamBuilder<List<Coupon>>(
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
                          child: Padding(
                            padding: EdgeInsets.all(DesignTokens.spaceHeading),
                            child: Text(
                              'クーポンがありません',
                              style: TextStyle(
                                fontSize: DesignTokens.fontSizeBody,
                                color: DesignTokens.textSecondary,
                              ),
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: coupons.map((coupon) {
                          return _CouponCard(
                            coupon: coupon,
                            onUseAtStore: () => _useAtStore(context, coupon),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CouponCard extends StatelessWidget {
  final Coupon coupon;
  final VoidCallback onUseAtStore;

  const _CouponCard({
    required this.coupon,
    required this.onUseAtStore,
  });

  @override
  Widget build(BuildContext context) {
    final isExpired = coupon.isExpired;
    final isRedeemed = coupon.isRedeemed;
    final isActive = coupon.isActive && !isExpired;

    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.spaceBase),
      child: SoupCard(
        backgroundColor: isActive
            ? null
            : DesignTokens.textSecondary.withOpacity(0.1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    coupon.meta.title,
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeH3,
                      fontWeight: FontWeight.bold,
                      color: isActive
                          ? DesignTokens.textPrimary
                          : DesignTokens.textSecondary,
                    ),
                  ),
                ),
                if (isRedeemed)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.spaceSmall,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: DesignTokens.textSecondary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '使用済み',
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeCaption,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else if (isExpired)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.spaceSmall,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: DesignTokens.error,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '期限切れ',
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeCaption,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: DesignTokens.spaceSmall),

            // Discount value
            Text(
              '${coupon.meta.discountValueYen}円割引',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeH2,
                fontWeight: FontWeight.bold,
                color: isActive
                    ? DesignTokens.primary
                    : DesignTokens.textSecondary,
              ),
            ),
            const SizedBox(height: DesignTokens.spaceBase),

            // Code
            Container(
              padding: const EdgeInsets.all(DesignTokens.spaceBase),
              decoration: BoxDecoration(
                color: isActive
                    ? DesignTokens.primary.withOpacity(0.1)
                    : DesignTokens.textSecondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    coupon.code,
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeH2,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                      fontFamily: 'monospace',
                      color: isActive
                          ? DesignTokens.primary
                          : DesignTokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.spaceBase),

            // Expiry date
            Row(
              children: [
                Icon(
                  CupertinoIcons.clock,
                  size: 16,
                  color: isActive
                      ? DesignTokens.textSecondary
                      : DesignTokens.textSecondary.withOpacity(0.5),
                ),
                const SizedBox(width: 4),
                Text(
                  '有効期限: ${_formatDate(coupon.expiresAt)}',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeCaption,
                    color: isActive
                        ? DesignTokens.textSecondary
                        : DesignTokens.textSecondary.withOpacity(0.5),
                  ),
                ),
              ],
            ),

            // Redeemed info
            if (isRedeemed && coupon.redeemedAt != null) ...[
              const SizedBox(height: DesignTokens.spaceSmall),
              Row(
                children: [
                  Icon(
                    CupertinoIcons.checkmark_circle,
                    size: 16,
                    color: DesignTokens.textSecondary.withOpacity(0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '使用日時: ${_formatDateTime(coupon.redeemedAt!)}',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeCaption,
                      color: DesignTokens.textSecondary.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ],

            // Use button
            if (isActive) ...[
              const SizedBox(height: DesignTokens.spaceBase),
              OutlinedButton.icon(
                onPressed: onUseAtStore,
                icon: const Icon(CupertinoIcons.location_solid),
                label: const Text('店頭で使う'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: DesignTokens.spaceBase,
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.spaceSmall),
              const Text(
                '※店頭でスタッフがPINを入力します',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeCaption,
                  color: DesignTokens.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _StaffPinDialog extends StatefulWidget {
  @override
  State<_StaffPinDialog> createState() => _StaffPinDialogState();
}

class _StaffPinDialogState extends State<_StaffPinDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('店頭での使用'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'スタッフにクーポンコードを提示し、スタッフ用6桁PINを入力してください。',
            style: TextStyle(fontSize: DesignTokens.fontSizeBody),
          ),
          const SizedBox(height: DesignTokens.spaceBase),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'スタッフ用PIN（6桁）',
              hintText: '123456',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            maxLength: 6,
            obscureText: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: () {
            final pin = _controller.text;
            if (pin.length == 6) {
              Navigator.of(context).pop(pin);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('6桁のPINを入力してください'),
                  backgroundColor: DesignTokens.error,
                ),
              );
            }
          },
          child: const Text('使用する'),
        ),
      ],
    );
  }
}
