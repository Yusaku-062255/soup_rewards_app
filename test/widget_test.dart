import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:soup_rewards/main.dart';

void main() {
  group('SOUP Rewards App Tests', () {
    testWidgets('App should build without errors', (WidgetTester tester) async {
      // アプリをビルドしてフレームをトリガー
      await tester.pumpWidget(
        const ProviderScope(
          child: SoupRewardsApp(),
        ),
      );

      // アプリが正常にビルドされることを確認
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Main page should be displayed', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: SoupRewardsApp(),
        ),
      );

      // MaterialAppが表示されることを確認
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Bottom navigation should have 5 tabs', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: SoupRewardsApp(),
        ),
      );

      // BottomNavigationBarが存在することを確認
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      
      // 5つのタブが存在することを確認
      final bottomNavBar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bottomNavBar.items.length, equals(5));
    });
  });
}
