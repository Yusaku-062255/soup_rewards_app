import 'package:flutter/material.dart';
import '../../../../core/theme/soup_theme.dart';
import 'home_page.dart';
import '../../../coupons/pages/coupons_page.dart';
import '../../../qr_scan/presentation/pages/qr_scan_page.dart';
import '../../../points/pages/points_detail_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';

/// SOUP公式アプリのメインページ
/// ボトムナビゲーションを管理
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const PointsDetailPage(),
    const QrScanPage(),
    const CouponsPage(),
    const ProfilePage(),
  ];

  final List<BottomNavigationBarItem> _navItems = [
    const BottomNavigationBarItem(
      icon: Icon(SoupIcons.service),
      label: 'ホーム',
    ),
    const BottomNavigationBarItem(
      icon: Icon(SoupIcons.points),
      label: 'ポイント',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.qr_code_scanner),
      label: 'QRスキャン',
    ),
    const BottomNavigationBarItem(
      icon: Icon(SoupIcons.coupon),
      label: 'クーポン',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.person),
      label: 'プロフィール',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: SoupTheme.cardShadow,
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: SoupTheme.surfaceWhite,
          selectedItemColor: SoupTheme.primaryGold,
          unselectedItemColor: Colors.grey[600],
          selectedLabelStyle: SoupTheme.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: SoupTheme.bodySmall,
          elevation: 0,
          items: _navItems,
        ),
      ),
    );
  }
}
