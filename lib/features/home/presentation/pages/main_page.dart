import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import 'home_page.dart';
import '../../../coupons/presentation/pages/coupons_page.dart';
import '../../../points/presentation/pages/points_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../qr_scan/presentation/pages/qr_scan_page_new.dart';

/// メインページ - BottomNavigationBar付きの画面管理
class MainPage extends ConsumerStatefulWidget {
  const MainPage({super.key});

  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const CouponsPage(),
    const QrScanPageNew(), // QRスキャンタブ
    const PointsPage(),
    const ProfilePage(),
  ];

  final List<BottomNavigationBarItem> _bottomNavItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home),
      label: 'ホーム',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.local_offer_outlined),
      activeIcon: Icon(Icons.local_offer),
      label: 'クーポン',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.qr_code_scanner_outlined),
      activeIcon: Icon(Icons.qr_code_scanner),
      label: 'QRスキャン',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.stars_outlined),
      activeIcon: Icon(Icons.stars),
      label: 'ポイント',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.person_outline),
      activeIcon: Icon(Icons.person),
      label: 'マイページ',
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
              color: AppColors.shadowLight,
              offset: const Offset(0, -2),
              blurRadius: 8,
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
          backgroundColor: AppColors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.grey400,
          selectedLabelStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
          items: _bottomNavItems,
        ),
      ),
    );
  }
}
