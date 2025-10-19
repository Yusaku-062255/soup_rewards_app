import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/soup_theme.dart';
import '../../../../core/services/points_service.dart';
import '../../../../core/services/vehicle_store.dart';
import '../../../points/pages/points_detail_page.dart';
import '../../../coupons/pages/coupons_page.dart';
import '../../../mycar/mycar_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';

/// SOUP公式ホーム画面
/// 公式サイトのデザインを基準に再構築
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final isScrolled = _scrollController.offset > 100;
    if (isScrolled != _isScrolled) {
      setState(() {
        _isScrolled = isScrolled;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pointsService = ref.watch(pointsServiceProvider);
    final vehicleStore = ref.watch(vehicleStoreProvider);
    
    return Scaffold(
      backgroundColor: SoupTheme.backgroundGray,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // カスタムアプリバー
          SliverAppBar(
            expandedHeight: 80,
            floating: true,
            pinned: true,
            backgroundColor: _isScrolled 
                ? SoupTheme.primaryNavy 
                : Colors.transparent,
            elevation: _isScrolled ? 4 : 0,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: AnimatedOpacity(
                opacity: _isScrolled ? 1.0 : 0.0,
                duration: SoupTheme.animationDuration,
                child: const Text(
                  'SOUP',
                  style: TextStyle(
                    color: SoupTheme.textWhite,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            actions: [
              // ポイント表示
              Container(
                margin: const EdgeInsets.only(right: 16),
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PointsDetailPage(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: SoupTheme.goldGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            SoupIcons.points,
                            color: SoupTheme.textWhite,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${pointsService.currentPoints}P',
                            style: SoupTheme.bodySmall.copyWith(
                              color: SoupTheme.textWhite,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // ヒーローセクション
          SliverToBoxAdapter(
            child: _buildHeroSection(),
          ),
          
          // クイックアクション
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(SoupTheme.spacingM),
              child: _buildQuickActions(),
            ),
          ),
          
          // サービス紹介
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SoupTheme.spacingM,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'サービスのご案内',
                    style: SoupTheme.headingMedium,
                  ),
                  const SizedBox(height: SoupTheme.spacingS),
                  Text(
                    '徳島のカーコーティング専門店SOUPが提供する\n高品質なサービスをご紹介します',
                    style: SoupTheme.bodyMedium.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: SoupTheme.spacingL),
                ],
              ),
            ),
          ),
          
          // サービスカード
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: SoupTheme.spacingM,
            ),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: SoupTheme.spacingM,
                mainAxisSpacing: SoupTheme.spacingM,
              ),
              delegate: SliverChildListDelegate([
                _buildServiceCard(
                  title: 'System X\nセラミック',
                  subtitle: '最高品質',
                  description: '航空宇宙産業向けに開発された\n世界最高水準のコーティング',
                  icon: SoupIcons.coating,
                  gradient: SoupTheme.goldGradient,
                  onTap: () => _showServiceDetail('system_x'),
                ),
                _buildServiceCard(
                  title: 'G.Guard\nガラス',
                  subtitle: '高品質',
                  description: '無機質のガラス被膜で\n長期間の美しさを維持',
                  icon: SoupIcons.coating,
                  gradient: SoupTheme.navyGradient,
                  onTap: () => _showServiceDetail('g_guard'),
                ),
                _buildServiceCard(
                  title: 'バイク\nコーティング',
                  subtitle: 'バイク専用',
                  description: 'バイク専用の高性能\nセラミックコーティング',
                  icon: SoupIcons.bike,
                  gradient: const LinearGradient(
                    colors: [SoupTheme.accentOrange, Color(0xFFFF6B35)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  onTap: () => _showServiceDetail('bike'),
                ),
                _buildServiceCard(
                  title: 'パーツ\nコーティング',
                  subtitle: '部位別',
                  description: 'ホイール・ガラス・インテリア\nなど部位別の専用コーティング',
                  icon: SoupIcons.wheel,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2C3E50), Color(0xFF34495E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  onTap: () => _showServiceDetail('parts'),
                ),
              ]),
            ),
          ),
          
          // 実績セクション
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(SoupTheme.spacingM),
              padding: const EdgeInsets.all(SoupTheme.spacingL),
              decoration: SoupTheme.cardDecoration,
              child: Column(
                children: [
                  Text(
                    'SOUPが選ばれる理由',
                    style: SoupTheme.headingSmall,
                  ),
                  const SizedBox(height: SoupTheme.spacingL),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('4万台+', '施工実績'),
                      _buildStatItem('20年+', '業界経験'),
                      _buildStatItem('98.5%', '満足度'),
                    ],
                  ),
                  const SizedBox(height: SoupTheme.spacingL),
                  Container(
                    padding: const EdgeInsets.all(SoupTheme.spacingM),
                    decoration: BoxDecoration(
                      color: SoupTheme.backgroundGray,
                      borderRadius: BorderRadius.circular(SoupTheme.radiusM),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          SoupIcons.service,
                          color: SoupTheme.primaryGold,
                          size: 32,
                        ),
                        const SizedBox(height: SoupTheme.spacingS),
                        Text(
                          'キレイな車は幸せを呼ぶ！',
                          style: SoupTheme.headingSmall.copyWith(
                            color: SoupTheme.primaryNavy,
                          ),
                        ),
                        const SizedBox(height: SoupTheme.spacingS),
                        Text(
                          'SOUPでは、車を大切にするという事業を通じて、\n幸せなクオリティタイムを応援しています。',
                          style: SoupTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // マイカー情報（登録済みの場合）
          if (vehicleStore.hasVehicle)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: SoupTheme.spacingM,
                  vertical: SoupTheme.spacingS,
                ),
                child: Card(
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: vehicleStore.currentVehicle?.isEV == true
                            ? Colors.green.withOpacity(0.1)
                            : SoupTheme.primaryGold.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        SoupIcons.car,
                        color: vehicleStore.currentVehicle?.isEV == true
                            ? Colors.green
                            : SoupTheme.primaryGold,
                      ),
                    ),
                    title: Text(
                      '${vehicleStore.currentVehicle?.make} ${vehicleStore.currentVehicle?.model}',
                      style: SoupTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      vehicleStore.currentVehicle?.isEV == true
                          ? 'EV車両（ポイント2倍）'
                          : '登録済み車両',
                      style: SoupTheme.bodySmall,
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MyCarPage(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          
          // ニュース・お知らせ
          SliverToBoxAdapter(
            child: _buildNewsSection(),
          ),
          
          // フッター
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(SoupTheme.spacingM),
              padding: const EdgeInsets.all(SoupTheme.spacingL),
              decoration: BoxDecoration(
                color: SoupTheme.primaryNavy,
                borderRadius: BorderRadius.circular(SoupTheme.radiusL),
              ),
              child: Column(
                children: [
                  const Text(
                    'SOUP（スープ）',
                    style: TextStyle(
                      color: SoupTheme.textWhite,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: SoupTheme.spacingS),
                  const Text(
                    '徳島のカーコーティング専門店',
                    style: TextStyle(
                      color: SoupTheme.textWhite,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: SoupTheme.spacingL),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildFooterAction(
                        SoupIcons.phone,
                        '電話する',
                        _launchPhone,
                      ),
                      _buildFooterAction(
                        SoupIcons.location,
                        '地図を見る',
                        _launchMap,
                      ),
                      _buildFooterAction(
                        SoupIcons.reserve,
                        '予約する',
                        _launchReservation,
                      ),
                    ],
                  ),
                ],
              ),
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

  Widget _buildHeroSection() {
    return Container(
      height: 300,
      margin: const EdgeInsets.all(SoupTheme.spacingM),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(SoupTheme.radiusL),
        gradient: SoupTheme.navyGradient,
        image: const DecorationImage(
          image: AssetImage('assets/soup_hero_section.webp'),
          fit: BoxFit.cover,
          opacity: 0.3,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(SoupTheme.spacingL),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(SoupTheme.radiusL),
          gradient: LinearGradient(
            colors: [
              SoupTheme.primaryNavy.withOpacity(0.8),
              Colors.transparent,
            ],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '徳島のカーコーティング専門店',
              style: SoupTheme.bodyLarge.copyWith(
                color: SoupTheme.textWhite,
              ),
            ),
            const SizedBox(height: SoupTheme.spacingS),
            Text(
              'SOUP（スープ）',
              style: SoupTheme.headingLarge.copyWith(
                color: SoupTheme.textWhite,
                fontSize: 32,
              ),
            ),
            const SizedBox(height: SoupTheme.spacingS),
            Text(
              'キレイな車は幸せを呼ぶ！',
              style: SoupTheme.bodyLarge.copyWith(
                color: SoupTheme.primaryGold,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionButton(
            icon: SoupIcons.reserve,
            label: '施工予約',
            color: SoupTheme.primaryGold,
            onTap: _launchReservation,
          ),
        ),
        const SizedBox(width: SoupTheme.spacingM),
        Expanded(
          child: _buildQuickActionButton(
            icon: SoupIcons.phone,
            label: '電話する',
            color: SoupTheme.primaryNavy,
            onTap: _launchPhone,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: SoupTheme.spacingM,
          horizontal: SoupTheme.spacingL,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(SoupTheme.radiusM),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: SoupTheme.textWhite,
              size: 20,
            ),
            const SizedBox(width: SoupTheme.spacingS),
            Text(
              label,
              style: SoupTheme.bodyMedium.copyWith(
                color: SoupTheme.textWhite,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard({
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(SoupTheme.spacingM),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(SoupTheme.radiusL),
          boxShadow: [
            BoxShadow(
              color: SoupTheme.cardShadow,
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: SoupTheme.textWhite.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: SoupTheme.textWhite,
                size: 24,
              ),
            ),
            const SizedBox(height: SoupTheme.spacingM),
            Text(
              subtitle,
              style: SoupTheme.bodySmall.copyWith(
                color: SoupTheme.textWhite.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: SoupTheme.spacingXS),
            Text(
              title,
              style: SoupTheme.headingSmall.copyWith(
                color: SoupTheme.textWhite,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: SoupTheme.spacingS),
            Text(
              description,
              style: SoupTheme.bodySmall.copyWith(
                color: SoupTheme.textWhite.withOpacity(0.9),
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: SoupTheme.headingMedium.copyWith(
            color: SoupTheme.primaryGold,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: SoupTheme.bodySmall.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildFooterAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: SoupTheme.primaryGold,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: SoupTheme.textWhite,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: SoupTheme.bodySmall.copyWith(
              color: SoupTheme.textWhite,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsSection() {
    return Container(
      margin: const EdgeInsets.all(SoupTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'お知らせ・ニュース',
            style: SoupTheme.headingMedium,
          ),
          const SizedBox(height: SoupTheme.spacingM),
          Card(
            child: Column(
              children: [
                _buildNewsItem(
                  '新サービス「System X PRO」導入',
                  'より高性能なセラミックコーティングの取り扱いを開始',
                  '2024.03.20',
                  Colors.red,
                ),
                const Divider(height: 1),
                _buildNewsItem(
                  '春のキャンペーン開催中！',
                  'コーティング施工料金が最大20%OFF',
                  '2024.03.01',
                  SoupTheme.accentOrange,
                ),
                const Divider(height: 1),
                _buildNewsItem(
                  '施工実績4万台達成',
                  'おかげさまで累計施工実績が4万台を突破',
                  '2024.02.28',
                  SoupTheme.primaryNavy,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsItem(String title, String subtitle, String date, Color color) {
    return ListTile(
      leading: Container(
        width: 4,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      title: Text(
        title,
        style: SoupTheme.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: SoupTheme.bodySmall,
      ),
      trailing: Text(
        date,
        style: SoupTheme.bodySmall.copyWith(
          color: Colors.grey[600],
        ),
      ),
    );
  }

  void _showServiceDetail(String serviceType) {
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
                      _buildServiceDetailContent(serviceType),
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

  Widget _buildServiceDetailContent(String serviceType) {
    switch (serviceType) {
      case 'system_x':
        return _buildSystemXDetail();
      case 'g_guard':
        return _buildGGuardDetail();
      case 'bike':
        return _buildBikeDetail();
      case 'parts':
        return _buildPartsDetail();
      default:
        return const SizedBox();
    }
  }

  Widget _buildSystemXDetail() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'System X セラミックコーティング',
          style: SoupTheme.headingMedium,
        ),
        const SizedBox(height: SoupTheme.spacingS),
        Text(
          '世界最高水準のセラミックコーティング',
          style: SoupTheme.bodyLarge.copyWith(
            color: SoupTheme.primaryGold,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: SoupTheme.spacingL),
        Text(
          '航空宇宙産業向けに開発されたセラミックコーティング剤で、耐熱性、耐紫外線性、耐薬品性に優れています。9Hの高硬度被膜と最大22μの厚みを持ち、深い光沢と艶を長期間維持します。',
          style: SoupTheme.bodyMedium,
        ),
        const SizedBox(height: SoupTheme.spacingL),
        _buildFeatureList([
          '9Hの高硬度被膜',
          '最大22μの厚み',
          '深い光沢と艶を長期間維持',
          '高い疎水性により水シミを防止',
          'セルフクリーニング効果',
        ]),
        const SizedBox(height: SoupTheme.spacingL),
        _buildServiceInfo('3-5年', '¥80,000～¥150,000', '1000P'),
      ],
    );
  }

  Widget _buildGGuardDetail() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'G.Guard ガラスコーティング',
          style: SoupTheme.headingMedium,
        ),
        const SizedBox(height: SoupTheme.spacingS),
        Text(
          '無機質のガラス被膜を形成',
          style: SoupTheme.bodyLarge.copyWith(
            color: SoupTheme.primaryNavy,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: SoupTheme.spacingL),
        Text(
          '不純物を含まないシリカガラス被膜が塗装内部に浸透し、ボディの光沢と艶を長期間維持します。耐紫外線性、約700℃の耐熱性、不燃性、耐酸性、耐透水性、耐汚染性、防錆性に優れます。',
          style: SoupTheme.bodyMedium,
        ),
        const SizedBox(height: SoupTheme.spacingL),
        _buildFeatureList([
          '無機質シリカガラス被膜',
          '約700℃の耐熱性',
          '耐紫外線性・耐酸性',
          '防錆性・耐汚染性',
          '汚れの付着も容易に除去可能',
        ]),
        const SizedBox(height: SoupTheme.spacingL),
        _buildServiceInfo('2-3年', '¥60,000～¥120,000', '800P'),
      ],
    );
  }

  Widget _buildBikeDetail() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'System X バイクコーティング',
          style: SoupTheme.headingMedium,
        ),
        const SizedBox(height: SoupTheme.spacingS),
        Text(
          'バイク専用高性能コーティング',
          style: SoupTheme.bodyLarge.copyWith(
            color: SoupTheme.accentOrange,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: SoupTheme.spacingL),
        Text(
          '航空宇宙産業向けに開発された高品質・高性能なセラミックコーティングで、紫外線・酸性雨・飛び石・汚れなどからバイクを強力に保護します。深みのある高光沢な仕上がりが長期間続きます。',
          style: SoupTheme.bodyMedium,
        ),
        const SizedBox(height: SoupTheme.spacingL),
        _buildFeatureList([
          '紫外線・酸性雨から保護',
          '飛び石・汚れから強力保護',
          '深みのある高光沢仕上がり',
          '洗車・メンテナンスが楽に',
          '遠赤外線による乾燥',
        ]),
        const SizedBox(height: SoupTheme.spacingL),
        _buildServiceInfo('2-3年', '¥40,000～¥80,000', '600P'),
      ],
    );
  }

  Widget _buildPartsDetail() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'パーツコーティング',
          style: SoupTheme.headingMedium,
        ),
        const SizedBox(height: SoupTheme.spacingS),
        Text(
          '部位別専用コーティング',
          style: SoupTheme.bodyLarge.copyWith(
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: SoupTheme.spacingL),
        Text(
          'ホイール、ガラス、インテリアなど、各部位に最適化された専用コーティングをご提供します。部位ごとの特性に合わせた最適な保護と美しさを実現します。',
          style: SoupTheme.bodyMedium,
        ),
        const SizedBox(height: SoupTheme.spacingL),
        _buildFeatureList([
          'ホイールコーティング（ブレーキダスト対策）',
          'ウィンドウコート（撥水性向上）',
          'インテリアコーティング（劣化防止）',
          'ヘッドライトコーティング（黄ばみ防止）',
          '各部位に最適化された専用処理',
        ]),
        const SizedBox(height: SoupTheme.spacingL),
        _buildServiceInfo('1-3年', '¥15,000～¥40,000', '200-300P'),
      ],
    );
  }

  Widget _buildFeatureList(List<String> features) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '特徴',
          style: SoupTheme.headingSmall,
        ),
        const SizedBox(height: SoupTheme.spacingS),
        ...features.map((feature) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 6),
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: SoupTheme.primaryGold,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  feature,
                  style: SoupTheme.bodyMedium,
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildServiceInfo(String duration, String price, String points) {
    return Container(
      padding: const EdgeInsets.all(SoupTheme.spacingM),
      decoration: BoxDecoration(
        color: SoupTheme.backgroundGray,
        borderRadius: BorderRadius.circular(SoupTheme.radiusM),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoItem('耐久年数', duration),
              _buildInfoItem('価格帯', price),
              _buildInfoItem('獲得ポイント', points),
            ],
          ),
          const SizedBox(height: SoupTheme.spacingL),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _launchReservation,
              style: SoupTheme.primaryButton,
              child: const Text('予約・お問い合わせ'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: SoupTheme.bodySmall.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: SoupTheme.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Future<void> _launchPhone() async {
    const phoneNumber = 'tel:088-377-2016';
    if (await canLaunchUrl(Uri.parse(phoneNumber))) {
      await launchUrl(Uri.parse(phoneNumber));
    }
  }

  Future<void> _launchReservation() async {
    const reservationUrl = 'https://soup.tokushima.jp/reserve';
    if (await canLaunchUrl(Uri.parse(reservationUrl))) {
      await launchUrl(
        Uri.parse(reservationUrl),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  Future<void> _launchMap() async {
    const mapUrl = 'https://maps.google.com/?q=徳島県三好市三野町加茂野宮445-1';
    if (await canLaunchUrl(Uri.parse(mapUrl))) {
      await launchUrl(
        Uri.parse(mapUrl),
        mode: LaunchMode.externalApplication,
      );
    }
  }
}
