import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import 'home_page.dart';
import '../../../gacha/presentation/pages/gacha_page.dart';
import '../../../maintenance/presentation/pages/maintenance_page.dart';
import '../../../coupon/presentation/pages/coupon_page.dart';
import '../../../support/presentation/pages/support_page.dart';

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
    const GachaPage(),
    const MaintenancePage(),
    const CouponPage(),
    const SupportPage(),
  ];

  final List<BottomNavigationBarItem> _bottomNavItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home),
      label: 'ホーム',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.card_giftcard_outlined),
      activeIcon: Icon(Icons.card_giftcard),
      label: 'ガチャ',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.directions_car_outlined),
      activeIcon: Icon(Icons.directions_car),
      label: 'メンテ',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.local_offer_outlined),
      activeIcon: Icon(Icons.local_offer),
      label: 'クーポン',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.support_agent_outlined),
      activeIcon: Icon(Icons.support_agent),
      label: 'サポート',
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
