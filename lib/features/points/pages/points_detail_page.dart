import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/soup_theme.dart';
import '../../../core/services/points_service.dart';
import '../../../core/services/vehicle_store.dart';
import '../../../core/services/coupon_store.dart';
import '../../../core/models/coupon_model.dart';
import '../../../core/models/vehicle_model.dart';

class PointsDetailPage extends ConsumerStatefulWidget {
  const PointsDetailPage({super.key});

  @override
  ConsumerState<PointsDetailPage> createState() => _PointsDetailPageState();
}

class _PointsDetailPageState extends ConsumerState<PointsDetailPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isLoading = false;
  bool _isExchanging = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _checkLoginBonus();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      await ref.read(pointsProvider.notifier).loadPointsData();
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('データの読み込みに失敗しました');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _checkLoginBonus() async {
    try {
      final bonusAwarded = await ref.read(pointsProvider.notifier).checkAndAwardLoginBonus();
      if (bonusAwarded && mounted) {
        _showLoginBonusDialog();
      }
    } catch (e) {
      // Bonus errors can be ignored
    }
  }

  @override
  Widget build(BuildContext context) {
    final pointsState = ref.watch(pointsProvider);
    final vehicle = ref.watch(vehicleStoreProvider).currentVehicle;
    
    return Scaffold(
      backgroundColor: SoupTheme.backgroundGray,
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(pointsState),
            SliverToBoxAdapter(child: _buildRankCard(pointsState, vehicle)),
            SliverToBoxAdapter(child: _buildEarnPointsSection()),
            SliverToBoxAdapter(child: _buildExchangeSection(pointsState)),
            SliverToBoxAdapter(child: _buildHistorySection(pointsState)),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(PointsState pointsState) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: SoupTheme.primaryNavy,
      foregroundColor: SoupTheme.textWhite,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text('ポイント', style: TextStyle(color: SoupTheme.textWhite, fontWeight: FontWeight.bold)),
        background: Container(
          decoration: BoxDecoration(gradient: SoupTheme.navyGradient),
          child: Stack(
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: 0.1,
                  child: Image.asset('assets/soup/hero/kv.webp', fit: BoxFit.cover),
                ),
              ),
              Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: SoupTheme.textWhite.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: SoupTheme.primaryGold.withOpacity(0.3), width: 2),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${pointsState.currentPoints}',
                                style: SoupTheme.headingLarge.copyWith(color: SoupTheme.primaryGold, fontSize: 48, fontWeight: FontWeight.bold),
                              ),
                              Text('ポイント', style: SoupTheme.bodyLarge.copyWith(color: SoupTheme.textWhite)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRankCard(PointsState pointsState, Vehicle? vehicle) {
    final currentRank = pointsState.currentRank;
    final nextRank = pointsState.nextRank;
    final progress = pointsState.rankProgress;

    return Card(
      child: Container(
        padding: const EdgeInsets.all(SoupTheme.spacingL),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(int.parse(currentRank.color.replaceFirst('#', '0xFF'))),
              Color(int.parse(currentRank.color.replaceFirst('#', '0xFF'))).withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(SoupTheme.radiusM),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Text(currentRank.icon, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: SoupTheme.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('現在のランク', style: SoupTheme.bodySmall.copyWith(color: SoupTheme.textWhite.withOpacity(0.8))),
                      Text(currentRank.name, style: SoupTheme.headingMedium.copyWith(color: SoupTheme.textWhite)),
                    ],
                  ),
                ),
                if (vehicle?.isEV == true)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: SoupTheme.primaryGold, borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.electric_car, color: SoupTheme.textWhite, size: 16),
                        const SizedBox(width: 4),
                        Text('EV特典 x${currentRank.evMultiplier}', style: SoupTheme.bodySmall.copyWith(color: SoupTheme.textWhite, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: SoupTheme.spacingM),
            if (nextRank != null) ...[
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(SoupTheme.primaryGold),
              ),
              const SizedBox(height: SoupTheme.spacingS),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('次のランクまで', style: SoupTheme.bodySmall.copyWith(color: SoupTheme.textWhite.withOpacity(0.9))),
                  Text('${pointsState.pointsToNextRank}P', style: SoupTheme.bodyMedium.copyWith(color: SoupTheme.textWhite, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEarnPointsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(SoupTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ポイントを貯める', style: SoupTheme.headingSmall),
            const SizedBox(height: SoupTheme.spacingM),
            _buildEarnItem(Icons.login, '毎日のログイン', '100ポイント'),
            _buildEarnItem(Icons.car_repair, 'サービスの利用', '利用額に応じて付与'),
            _buildEarnItem(Icons.electric_car, 'EV車両の登録', 'ポイントレートUP'),
          ],
        ),
      ),
    );
  }

  Widget _buildExchangeSection(PointsState pointsState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(SoupTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ポイントを使う', style: SoupTheme.headingSmall),
            const SizedBox(height: SoupTheme.spacingM),
            _buildExchangeItem(
              title: '500円割引クーポン',
              requiredPoints: 500,
              description: '次回施工時に使用可能',
              onExchange: () => _exchangePoints(500, '500円割引クーポン'),
              canExchange: pointsState.currentPoints >= 500,
            ),
            const Divider(),
            _buildExchangeItem(
              title: '1000円割引クーポン',
              requiredPoints: 1000,
              description: '次回施工時に使用可能',
              onExchange: () => _exchangePoints(1000, '1000円割引クーポン'),
              canExchange: pointsState.currentPoints >= 1000,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection(PointsState pointsState) {
    final history = pointsState.history;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(SoupTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ポイント履歴', style: SoupTheme.headingSmall),
            const SizedBox(height: SoupTheme.spacingM),
            if (history.isEmpty)
              const Center(child: Text('取引履歴はありません。'))
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final item = history[index];
                  final isPositive = item.amount > 0;
                  return ListTile(
                    leading: Icon(isPositive ? Icons.add_circle : Icons.remove_circle, color: isPositive ? Colors.green : Colors.red),
                    title: Text(item.description),
                    subtitle: Text(DateFormat('yyyy/MM/dd HH:mm').format(item.timestamp)),
                    trailing: Text('${isPositive ? '+' : ''}${item.amount} P', style: TextStyle(color: isPositive ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                  );
                },
                separatorBuilder: (context, index) => const Divider(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarnItem(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: SoupTheme.primaryGold),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }

  Widget _buildExchangeItem({
    required String title,
    required int requiredPoints,
    required String description,
    required VoidCallback onExchange,
    required bool canExchange,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: Text(description),
      trailing: ElevatedButton(
        onPressed: canExchange && !_isExchanging ? onExchange : null,
        child: Text('$requiredPoints P'),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showLoginBonusDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ログインボーナス！'),
        content: const Text('100ポイントを獲得しました！'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _exchangePoints(int points, String itemName) async {
    if (!mounted) return;
    setState(() => _isExchanging = true);

    try {
      final success = await ref.read(pointsProvider.notifier).spendPoints(points, 'クーポン交換: $itemName');
      if (success && mounted) {
        final coupon = CouponModel(
          id: 'exchanged_${DateTime.now().millisecondsSinceEpoch}',
          title: itemName,
          description: 'ポイント交換で獲得',
          category: 'exchange',
          discountType: 'fixed',
          discountValue: points.toDouble(),
          expiryDate: DateTime.now().add(const Duration(days: 90)),
        );
        await CouponStore.addCoupon(coupon);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$itemNameと交換しました！'), backgroundColor: Colors.green),
        );
      } else if (mounted) {
        _showErrorSnackBar('ポイントが不足しています。');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('交換中にエラーが発生しました。');
      }
    } finally {
      if (mounted) {
        setState(() => _isExchanging = false);
      }
    }
  }
}

