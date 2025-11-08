import 'dart:developer' as dev;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'design/theme.dart';
import 'features/home/home_screen.dart';
import 'features/booking/booking_screen.dart';
import 'features/points/points_screen.dart';
import 'features/coupons/coupons_screen.dart';

class SoupRewardsApp extends StatefulWidget {
  const SoupRewardsApp({super.key});

  @override
  State<SoupRewardsApp> createState() => _SoupRewardsAppState();
}

class _SoupRewardsAppState extends State<SoupRewardsApp> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _ensureDevSetup();
  }

  /// 開発用セットアップ: 給油券テンプレートの存在保証
  Future<void> _ensureDevSetup() async {
    try {
      final functions = FirebaseFunctions.instanceFor(region: 'asia-northeast1');
      final result = await functions.httpsCallable('ensureFuelVoucherTemplate').call();
      final message = result.data['message'] ?? 'Template check complete';
      dev.log('Fuel voucher template: $message', name: 'dev_setup');
    } catch (e) {
      dev.log('Failed to ensure fuel voucher template: $e', name: 'dev_setup');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _navigateToBooking() {
    setState(() {
      _selectedIndex = 1; // Navigate to booking tab
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SOUP Rewards',
      theme: createAppTheme(),
      home: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            HomeScreen(onNavigateToBooking: _navigateToBooking),
            const BookingScreen(),
            const PointsScreen(),
            const CouponsScreen(),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: DesignTokens.card,
          selectedItemColor: DesignTokens.primary,
          unselectedItemColor: DesignTokens.textSecondary,
          selectedFontSize: DesignTokens.fontSizeSmall,
          unselectedFontSize: DesignTokens.fontSizeSmall,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.house),
              activeIcon: Icon(CupertinoIcons.house_fill),
              label: 'ホーム',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.calendar),
              activeIcon: Icon(CupertinoIcons.calendar_circle_fill),
              label: '予約',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.star),
              activeIcon: Icon(CupertinoIcons.star_fill),
              label: 'ポイント',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.ticket),
              activeIcon: Icon(CupertinoIcons.ticket_fill),
              label: 'クーポン',
            ),
          ],
        ),
      ),
    );
  }
}
