import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/floating_action_buttons.dart';

class NewHomePage extends ConsumerStatefulWidget {
  const NewHomePage({super.key});

  @override
  ConsumerState<NewHomePage> createState() => _NewHomePageState();
}

class _NewHomePageState extends ConsumerState<NewHomePage> {
  @override
  void initState() {
    super.initState();
    // TODO: Initialize analytics service
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ヒーローセクション
              SliverToBoxAdapter(
                child: _buildHeroSection(),
              ),
              // メニューグリッド
              SliverToBoxAdapter(
                child: _buildMenuGrid(),
              ),
              // 最新情報セクション
              SliverToBoxAdapter(
                child: _buildLatestNewsSection(),
              ),
            ],
          ),
          // 固定FABボタン
          const Positioned(
            right: 16,
            bottom: 100,
            child: SoupFloatingActionButtons(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      height: 300,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1E3A8A), // SOUP ブルー
            Color(0xFF3B82F6),
          ],
        ),
      ),
      child: Stack(
        children: [
          // 背景画像
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: 'https://soup.tokushima.jp/wp-content/uploads/2024/hero-image.jpg',
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[300],
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[300],
                child: const Icon(Icons.image_not_supported),
              ),
            ),
          ),
          // オーバーレイ
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.6),
                ],
              ),
            ),
          ),
          // テキストコンテンツ
          Positioned(
            left: 24,
            right: 24,
            bottom: 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SOUP',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '徳島発、プロフェッショナル\nカーケアサービス',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _onBookingTap(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '今すぐ予約',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGrid() {
    final menuItems = [
      _MenuItem(
        title: 'サービス・料金',
        icon: Icons.car_repair,
        color: const Color(0xFF3B82F6),
        onTap: () => _onMenuTap('services'),
      ),
      _MenuItem(
        title: '施工実績',
        icon: Icons.photo_library,
        color: const Color(0xFF10B981),
        onTap: () => _onMenuTap('gallery'),
      ),
      _MenuItem(
        title: '予約',
        icon: Icons.calendar_today,
        color: const Color(0xFFEF4444),
        onTap: () => _onMenuTap('booking'),
      ),
      _MenuItem(
        title: 'FAQ',
        icon: Icons.help_outline,
        color: const Color(0xFF8B5CF6),
        onTap: () => _onMenuTap('faq'),
      ),
      _MenuItem(
        title: '店舗情報',
        icon: Icons.location_on,
        color: const Color(0xFFF59E0B),
        onTap: () => _onMenuTap('store'),
      ),
      _MenuItem(
        title: 'ブログ',
        icon: Icons.article,
        color: const Color(0xFF6B7280),
        onTap: () => _onMenuTap('blog'),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'メニュー',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
            ),
            itemCount: menuItems.length,
            itemBuilder: (context, index) {
              final item = menuItems[index];
              return _buildMenuItem(item);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(_MenuItem item) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  item.icon,
                  color: item.color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                item.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLatestNewsSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '最新情報',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          // TODO: WordPress APIから最新記事を取得して表示
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '最新情報を読み込み中...',
              style: TextStyle(
                color: Color(0xFF6B7280),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onBookingTap() {
    // TODO: Implement analytics logging
    _launchUrl('https://soup.tokushima.jp/reserve');
  }

  void _onMenuTap(String menuName) {
    // TODO: Implement analytics logging and navigation
    switch (menuName) {
      case 'services':
        // TODO: Navigate to services page
        break;
      case 'gallery':
        // TODO: Navigate to gallery page
        break;
      case 'booking':
        _launchUrl('https://soup.tokushima.jp/reserve');
        break;
      case 'faq':
        // TODO: Navigate to FAQ page
        break;
      case 'store':
        // TODO: Navigate to store page
        break;
      case 'blog':
        // TODO: Navigate to blog page
        break;
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _MenuItem {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _MenuItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
