import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/soup_theme.dart';
import '../../../core/services/points_service.dart';
import '../../../core/services/vehicle_store.dart';
import '../../../core/services/coupon_store.dart';
import '../../../core/models/coupon_model.dart';

/// SOUP公式ポイント詳細ページ
/// ポイント管理とランクシステムを統合
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
    _loadData();
    _checkLoginBonus();
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
    setState(() => _isLoading = true);
    
    try {
      await Future.delayed(const Duration(milliseconds: 500)); // アニメーション用
      final pointsService = ref.read(pointsServiceProvider.notifier);
      await pointsService.loadPointsData();
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
      final pointsService = ref.read(pointsServiceProvider.notifier);
      final bonusAwarded = await pointsService.checkAndAwardLoginBonus();
      
      if (bonusAwarded && mounted) {
        _showLoginBonusDialog();
      }
    } catch (e) {
      // ログインボーナスのエラーは無視
    }
  }

  @override
  Widget build(BuildContext context) {
    final pointsService = ref.watch(pointsServiceProvider);
    final vehicleStore = ref.watch(vehicleStoreProvider);
    
    return Scaffold(
      backgroundColor: SoupTheme.backgroundGray,
      body: CustomScrollView(
        slivers: [
          // カスタムアプリバー
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: SoupTheme.primaryNavy,
            foregroundColor: SoupTheme.textWhite,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'ポイント',
                style: TextStyle(
                  color: SoupTheme.textWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: SoupTheme.navyGradient,
                ),
                child: Stack(
                  children: [
                    // 背景パターン
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.1,
                        child: Image.asset(
                          'assets/soup_hero_section.webp',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    
                    // ポイント表示
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
                                  border: Border.all(
                                    color: SoupTheme.primaryGold.withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      '${pointsService.currentPoints}',
                                      style: SoupTheme.headingLarge.copyWith(
                                        color: SoupTheme.primaryGold,
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'ポイント',
                                      style: SoupTheme.bodyLarge.copyWith(
                                        color: SoupTheme.textWhite,
                                      ),
                                    ),
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
          ),
          
          // ランク情報
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(SoupTheme.spacingM),
              child: _buildRankCard(pointsService, vehicleStore),
            ),
          ),
          
          // ポイント獲得方法
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(
                horizontal: SoupTheme.spacingM,
                vertical: SoupTheme.spacingS,
              ),
              child: _buildEarnPointsSection(),
            ),
          ),
          
          // ポイント交換
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(
                horizontal: SoupTheme.spacingM,
                vertical: SoupTheme.spacingS,
              ),
              child: _buildExchangeSection(pointsService),
            ),
          ),
          
          // ポイント履歴
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(
                horizontal: SoupTheme.spacingM,
                vertical: SoupTheme.spacingS,
              ),
              child: _buildHistorySection(pointsService),
            ),
          ),
          
          // 下部余白
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  Widget _buildRankCard(PointsService pointsService, VehicleStore vehicleStore) {
    final currentRank = pointsService.currentRank;
    final nextRank = pointsService.nextRank;
    final progress = pointsService.rankProgress;
    
    return Card(
      child: Container(
        padding: const EdgeInsets.all(SoupTheme.spacingL),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(int.parse(currentRank['color'].replaceFirst('#', '0xFF'))),
              Color(int.parse(currentRank['color'].replaceFirst('#', '0xFF'))).withOpacity(0.7),
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
                Text(
                  currentRank['icon'] ?? '🥉',
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: SoupTheme.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '現在のランク',
                        style: SoupTheme.bodySmall.copyWith(
                          color: SoupTheme.textWhite.withOpacity(0.8),
                        ),
                      ),
                      Text(
                        currentRank['name'] ?? 'ブロンズ',
                        style: SoupTheme.headingMedium.copyWith(
                          color: SoupTheme.textWhite,
                        ),
                      ),
                    ],
                  ),
                ),
                if (vehicleStore.currentVehicle?.isEV == true)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: SoupTheme.primaryGold,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.electric_car,
                          color: SoupTheme.textWhite,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'EV特典',
                          style: SoupTheme.bodySmall.copyWith(
                            color: SoupTheme.textWhite,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            
            if (nextRank != null) ...[
              const SizedBox(height: SoupTheme.spacingL),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '次のランクまで',
                        style: SoupTheme.bodyMedium.copyWith(
                          color: SoupTheme.textWhite.withOpacity(0.9),
                        ),
                      ),
                      Text(
                        '${nextRank['requiredPoints'] - pointsService.currentPoints}P',
                        style: SoupTheme.bodyMedium.copyWith(
                          color: SoupTheme.textWhite,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: SoupTheme.spacingS),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: SoupTheme.textWhite.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      SoupTheme.primaryGold,
                    ),
                  ),
                  const SizedBox(height: SoupTheme.spacingS),
                  Row(
                    children: [
                      Text(
                        nextRank['icon'] ?? '🥈',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        nextRank['name'] ?? 'シルバー',
                        style: SoupTheme.bodySmall.copyWith(
                          color: SoupTheme.textWhite.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEarnPointsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ポイントを貯める',
          style: SoupTheme.headingMedium,
        ),
        const SizedBox(height: SoupTheme.spacingM),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(SoupTheme.spacingM),
            child: Column(
              children: [
                _buildEarnMethodItem(
                  icon: SoupIcons.coating,
                  title: 'コーティング施工',
                  description: '施工料金の1%をポイント還元',
                  points: '100円 = 1P',
                  color: SoupTheme.primaryGold,
                ),
                const Divider(),
                _buildEarnMethodItem(
                  icon: SoupIcons.service,
                  title: 'メンテナンス',
                  description: 'メンテナンス料金の0.5%をポイント還元',
                  points: '200円 = 1P',
                  color: SoupTheme.primaryNavy,
                ),
                const Divider(),
                _buildEarnMethodItem(
                  icon: Icons.electric_car,
                  title: 'EV車両特典',
                  description: 'EV車両は全てのポイントが2倍',
                  points: '通常の2倍',
                  color: Colors.green,
                ),
                const Divider(),
                _buildEarnMethodItem(
                  icon: SoupIcons.time,
                  title: 'ログインボーナス',
                  description: '毎日のアプリ起動で10ポイント',
                  points: '1日 = 10P',
                  color: SoupTheme.accentOrange,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEarnMethodItem({
    required IconData icon,
    required String title,
    required String description,
    required String points,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SoupTheme.spacingS),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: SoupTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: SoupTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: SoupTheme.bodySmall.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              points,
              style: SoupTheme.bodySmall.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExchangeSection(PointsService pointsService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ポイント交換',
          style: SoupTheme.headingMedium,
        ),
        const SizedBox(height: SoupTheme.spacingM),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(SoupTheme.spacingM),
            child: Column(
              children: [
                _buildExchangeItem(
                  title: '500円割引クーポン',
                  requiredPoints: 500,
                  description: '次回施工時に使用可能',
                  onExchange: () => _exchangePoints(500, '500円割引クーポン'),
                  canExchange: pointsService.currentPoints >= 500,
                ),
                const Divider(),
                _buildExchangeItem(
                  title: '1000円割引クーポン',
                  requiredPoints: 1000,
                  description: '次回施工時に使用可能',
                  onExchange: () => _exchangePoints(1000, '1000円割引クーポン'),
                  canExchange: pointsService.currentPoints >= 1000,
                ),
                const Divider(),
                _buildExchangeItem(
                  title: '洗車サービス無料券',
                  requiredPoints: 2000,
                  description: '手洗い洗車サービス1回分',
                  onExchange: () => _exchangePoints(2000, '洗車サービス無料券'),
                  canExchange: pointsService.currentPoints >= 2000,
                ),
                const Divider(),
                _buildExchangeItem(
                  title: 'コーティング10%OFF',
                  requiredPoints: 5000,
                  description: '全コーティングメニュー対象',
                  onExchange: () => _exchangePoints(5000, 'コーティング10%OFF'),
                  canExchange: pointsService.currentPoints >= 5000,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExchangeItem({
    required String title,
    required int requiredPoints,
    required String description,
    required VoidCallback onExchange,
    required bool canExchange,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SoupTheme.spacingS),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: SoupTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: SoupTheme.bodySmall.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${requiredPoints}P',
                  style: SoupTheme.bodyMedium.copyWith(
                    color: SoupTheme.primaryGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: canExchange && !_isExchanging ? onExchange : null,
            style: canExchange
                ? SoupTheme.primaryButton
                : SoupTheme.disabledButton,
            child: _isExchanging
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: SoupTheme.textWhite,
                    ),
                  )
                : const Text('交換'),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection(PointsService pointsService) {
    final history = pointsService.pointsHistory;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ポイント履歴',
          style: SoupTheme.headingMedium,
        ),
        const SizedBox(height: SoupTheme.spacingM),
        Card(
          child: history.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(SoupTheme.spacingXL),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          SoupIcons.points,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: SoupTheme.spacingM),
                        Text(
                          'ポイント履歴がありません',
                          style: SoupTheme.bodyLarge.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: history.take(10).map((item) {
                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: item['type'] == 'earn'
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          item['type'] == 'earn'
                              ? Icons.add
                              : Icons.remove,
                          color: item['type'] == 'earn'
                              ? Colors.green
                              : Colors.red,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        item['description'] ?? '',
                        style: SoupTheme.bodyMedium,
                      ),
                      subtitle: Text(
                        _formatDate(DateTime.parse(item['date'])),
                        style: SoupTheme.bodySmall.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      trailing: Text(
                        '${item['type'] == 'earn' ? '+' : '-'}${item['points']}P',
                        style: SoupTheme.bodyMedium.copyWith(
                          color: item['type'] == 'earn'
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Future<void> _exchangePoints(int points, String itemName) async {
    setState(() => _isExchanging = true);
    
    try {
      final pointsService = ref.read(pointsServiceProvider.notifier);
      await pointsService.exchangePoints(points, itemName);
      
      // クーポンを生成
      final coupon = CouponModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: itemName,
        description: 'ポイント交換で獲得したクーポンです',
        discountType: 'fixed',
        discountValue: points == 500 ? 500 : points == 1000 ? 1000 : 0,
        expiryDate: DateTime.now().add(const Duration(days: 90)),
        isUsed: false,
        category: 'points_exchange',
      );
      
      await CouponStore.addCoupon(coupon);
      
      if (mounted) {
        _showSuccessSnackBar('${itemName}と交換しました！');
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('交換に失敗しました');
      }
    } finally {
      if (mounted) {
        setState(() => _isExchanging = false);
      }
    }
  }

  void _showLoginBonusDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SoupTheme.radiusL),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: SoupTheme.goldGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                SoupIcons.points,
                color: SoupTheme.textWhite,
                size: 48,
              ),
            ),
            const SizedBox(height: SoupTheme.spacingL),
            Text(
              'ログインボーナス',
              style: SoupTheme.headingMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: SoupTheme.spacingS),
            Text(
              '10ポイントを獲得しました！',
              style: SoupTheme.bodyLarge.copyWith(
                color: SoupTheme.primaryGold,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: SoupTheme.spacingS),
            Text(
              '毎日アプリを開いてポイントを貯めよう',
              style: SoupTheme.bodyMedium.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: SoupTheme.primaryButton,
              child: const Text('OK'),
            ),
          ),
        ],
      ),
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

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day}';
  }
}
