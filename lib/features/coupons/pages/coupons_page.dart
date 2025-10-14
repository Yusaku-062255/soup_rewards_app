import 'package:flutter/material.dart';
import '../../../core/theme/soup_theme.dart';
import '../../../core/models/coupon_model.dart';
import '../../../core/services/coupon_store.dart';
import '../widgets/coupon_card.dart';

/// SOUP公式クーポンページ
/// 利用可能・使用済みクーポンを管理
class CouponsPage extends StatefulWidget {
  const CouponsPage({super.key});

  @override
  State<CouponsPage> createState() => _CouponsPageState();
}

class _CouponsPageState extends State<CouponsPage> 
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  
  List<CouponModel> _availableCoupons = [];
  List<CouponModel> _redeemedCoupons = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _loadCoupons();
    _initializeDefaultCoupons();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeDefaultCoupons() async {
    await CouponStore.initializeDefaultCoupons();
    _loadCoupons();
  }

  Future<void> _loadCoupons() async {
    setState(() => _isLoading = true);
    
    try {
      final available = await CouponStore.getAvailableCoupons();
      final redeemed = await CouponStore.getRedeemedCoupons();
      
      if (mounted) {
        setState(() {
          _availableCoupons = available;
          _redeemedCoupons = redeemed;
        });
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('クーポンの読み込みに失敗しました');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SoupTheme.backgroundGray,
      appBar: AppBar(
        title: const Text('クーポン'),
        backgroundColor: SoupTheme.primaryNavy,
        foregroundColor: SoupTheme.textWhite,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: SoupTheme.primaryGold,
          labelColor: SoupTheme.textWhite,
          unselectedLabelColor: SoupTheme.textWhite.withOpacity(0.7),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(SoupIcons.coupon, size: 16),
                  const SizedBox(width: 8),
                  Text('利用可能 (${_availableCoupons.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history, size: 16),
                  const SizedBox(width: 8),
                  Text('使用済み (${_redeemedCoupons.length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // 統計情報ヘッダー
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(SoupTheme.spacingL),
            decoration: BoxDecoration(
              gradient: SoupTheme.navyGradient,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  '${_availableCoupons.length}',
                  '利用可能',
                  SoupIcons.coupon,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: SoupTheme.textWhite.withOpacity(0.3),
                ),
                _buildStatItem(
                  '${_calculateTotalSavings()}円',
                  '節約可能額',
                  SoupIcons.points,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: SoupTheme.textWhite.withOpacity(0.3),
                ),
                _buildStatItem(
                  '${_redeemedCoupons.length}',
                  '使用済み',
                  Icons.history,
                ),
              ],
            ),
          ),
          
          // タブビュー
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAvailableCouponsTab(),
                _buildRedeemedCouponsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCouponInfo,
        backgroundColor: SoupTheme.primaryGold,
        foregroundColor: SoupTheme.textWhite,
        icon: const Icon(Icons.info_outline),
        label: const Text('クーポンについて'),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: SoupTheme.primaryGold,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: SoupTheme.headingSmall.copyWith(
            color: SoupTheme.textWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: SoupTheme.bodySmall.copyWith(
            color: SoupTheme.textWhite.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildAvailableCouponsTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: SoupTheme.primaryGold,
        ),
      );
    }

    if (_availableCoupons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              SoupIcons.coupon,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: SoupTheme.spacingL),
            Text(
              '利用可能なクーポンがありません',
              style: SoupTheme.headingSmall.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: SoupTheme.spacingS),
            Text(
              'ポイント交換や施工でクーポンを獲得しよう',
              style: SoupTheme.bodyMedium.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: SoupTheme.spacingL),
            ElevatedButton.icon(
              onPressed: () {
                // ポイントページに遷移
                DefaultTabController.of(context)?.animateTo(1);
              },
              style: SoupTheme.primaryButton,
              icon: const Icon(SoupIcons.points),
              label: const Text('ポイントを貯める'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCoupons,
      color: SoupTheme.primaryGold,
      child: ListView.builder(
        padding: const EdgeInsets.all(SoupTheme.spacingM),
        itemCount: _availableCoupons.length,
        itemBuilder: (context, index) {
          final coupon = _availableCoupons[index];
          return AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(
                    index * 0.1,
                    (index * 0.1) + 0.3,
                    curve: Curves.easeOutCubic,
                  ),
                )),
                child: FadeTransition(
                  opacity: Tween<double>(
                    begin: 0.0,
                    end: 1.0,
                  ).animate(CurvedAnimation(
                    parent: _animationController,
                    curve: Interval(
                      index * 0.1,
                      (index * 0.1) + 0.3,
                      curve: Curves.easeInOut,
                    ),
                  )),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: SoupTheme.spacingM),
                    child: CouponCard(
                      coupon: coupon,
                      onUse: () => _useCoupon(coupon),
                      isUsed: false,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildRedeemedCouponsTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: SoupTheme.primaryGold,
        ),
      );
    }

    if (_redeemedCoupons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: SoupTheme.spacingL),
            Text(
              '使用済みクーポンがありません',
              style: SoupTheme.headingSmall.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: SoupTheme.spacingS),
            Text(
              'クーポンを使用すると履歴が表示されます',
              style: SoupTheme.bodyMedium.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(SoupTheme.spacingM),
      itemCount: _redeemedCoupons.length,
      itemBuilder: (context, index) {
        final coupon = _redeemedCoupons[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: SoupTheme.spacingM),
          child: CouponCard(
            coupon: coupon,
            onUse: null,
            isUsed: true,
          ),
        );
      },
    );
  }

  int _calculateTotalSavings() {
    return _availableCoupons.fold(0, (total, coupon) {
      if (coupon.discountType == 'fixed') {
        return total + coupon.discountValue.toInt();
      } else {
        // パーセント割引の場合は概算値
        return total + (coupon.discountValue * 10).toInt();
      }
    });
  }

  Future<void> _useCoupon(CouponModel coupon) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SoupTheme.radiusL),
        ),
        title: Text(
          'クーポンを使用',
          style: SoupTheme.headingMedium,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              coupon.title,
              style: SoupTheme.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: SoupTheme.spacingS),
            Text(
              'このクーポンを使用しますか？\n使用後は元に戻せません。',
              style: SoupTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: SoupTheme.primaryButton,
            child: const Text('使用する'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await CouponStore.useCoupon(coupon.id);
        await _loadCoupons();
        
        if (mounted) {
          _showSuccessSnackBar('クーポンを使用しました');
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar('クーポンの使用に失敗しました');
        }
      }
    }
  }

  void _showCouponInfo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: SoupTheme.surfaceWhite,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(SoupTheme.radiusL),
              ),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(SoupTheme.spacingL),
                    children: [
                      Text(
                        'クーポンについて',
                        style: SoupTheme.headingMedium,
                      ),
                      const SizedBox(height: SoupTheme.spacingL),
                      
                      _buildInfoSection(
                        'クーポンの獲得方法',
                        [
                          '• ポイント交換（500P〜）',
                          '• 施工完了後の特典',
                          '• キャンペーン参加',
                          '• 誕生日特典',
                        ],
                      ),
                      
                      _buildInfoSection(
                        '使用方法',
                        [
                          '• 店舗でクーポン画面を提示',
                          '• 施工前に適用を確認',
                          '• 有効期限内に使用',
                          '• 他の割引との併用不可',
                        ],
                      ),
                      
                      _buildInfoSection(
                        '注意事項',
                        [
                          '• 使用後の取り消しはできません',
                          '• 有効期限を過ぎると自動的に無効',
                          '• 一部サービスで使用不可の場合あり',
                          '• 現金との交換はできません',
                        ],
                      ),
                      
                      const SizedBox(height: SoupTheme.spacingL),
                      
                      Container(
                        padding: const EdgeInsets.all(SoupTheme.spacingL),
                        decoration: BoxDecoration(
                          color: SoupTheme.primaryGold.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(SoupTheme.radiusM),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              SoupIcons.service,
                              color: SoupTheme.primaryGold,
                              size: 32,
                            ),
                            const SizedBox(height: SoupTheme.spacingS),
                            Text(
                              'お得にSOUPのサービスを利用しよう！',
                              style: SoupTheme.headingSmall.copyWith(
                                color: SoupTheme.primaryNavy,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: SoupTheme.spacingS),
                            Text(
                              'ポイントを貯めてクーポンと交換し、\nさらにお得にコーティングサービスをご利用ください。',
                              style: SoupTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: SoupTheme.headingSmall,
        ),
        const SizedBox(height: SoupTheme.spacingS),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            item,
            style: SoupTheme.bodyMedium,
          ),
        )),
        const SizedBox(height: SoupTheme.spacingL),
      ],
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
