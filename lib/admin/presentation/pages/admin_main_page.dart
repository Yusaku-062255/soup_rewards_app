import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'points_admin_page.dart';
import 'reservations_admin_page.dart';
import 'members_admin_page.dart';

/// 管理画面のメインページ
/// 左サイドバー + メインコンテンツエリアのレイアウト
class AdminMainPage extends StatefulWidget {
  const AdminMainPage({super.key});

  @override
  State<AdminMainPage> createState() => _AdminMainPageState();
}

class _AdminMainPageState extends State<AdminMainPage> {
  int _selectedIndex = 0;

  final List<AdminPageItem> _pages = const [
    AdminPageItem(
      title: 'ポイント付与',
      icon: Icons.stars,
      page: PointsAdminPage(),
    ),
    AdminPageItem(
      title: '予約一覧',
      icon: Icons.calendar_today,
      page: ReservationsAdminPage(),
    ),
    AdminPageItem(
      title: '会員検索',
      icon: Icons.person_search,
      page: MembersAdminPage(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 左サイドバー
          Container(
            width: 250,
            decoration: const BoxDecoration(
              color: AppColors.white,
              border: Border(
                right: BorderSide(
                  color: AppColors.grey200,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                // ヘッダー
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SOUP Admin',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '管理画面',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.white.withValues(alpha: 0.9),
                            ),
                      ),
                    ],
                  ),
                ),
                // メニューリスト
                Expanded(
                  child: ListView.builder(
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      final item = _pages[index];
                      final isSelected = _selectedIndex == index;
                      return ListTile(
                        selected: isSelected,
                        leading: Icon(
                          item.icon,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.grey600,
                        ),
                        title: Text(
                          item.title,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textMain,
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            _selectedIndex = index;
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // メインコンテンツエリア
          Expanded(
            child: _pages[_selectedIndex].page,
          ),
        ],
      ),
    );
  }
}

/// 管理画面のページアイテム
class AdminPageItem {
  final String title;
  final IconData icon;
  final Widget page;

  const AdminPageItem({
    required this.title,
    required this.icon,
    required this.page,
  });
}
