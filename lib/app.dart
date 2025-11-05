import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'design/theme.dart';
import 'features/home/home_screen.dart';
import 'features/booking/booking_screen.dart';
import 'features/points/points_screen.dart';
import 'features/coupons/coupons_screen.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/profile_page.dart';
import 'features/auth/presentation/providers/auth_state_provider.dart';

class SoupRewardsApp extends ConsumerWidget {
  const SoupRewardsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'SOUP Rewards',
      theme: createAppTheme(),
      home: authState.when(
        data: (user) {
          if (user == null) {
            return const LoginPage();
          }
          return const MainNavigator();
        },
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (error, stack) => Scaffold(
          body: Center(
            child: Text('エラー: $error'),
          ),
        ),
      ),
    );
  }
}

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _selectedIndex = 0;

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
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          HomeScreen(onNavigateToBooking: _navigateToBooking),
          const BookingScreen(),
          const PointsScreen(),
          const CouponsScreen(),
          const ProfilePage(),
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
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person),
            activeIcon: Icon(CupertinoIcons.person_fill),
            label: 'プロフィール',
          ),
        ],
      ),
    );
  }
}
