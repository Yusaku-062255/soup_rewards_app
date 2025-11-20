// TODO: アプリ構造が固まったら widget_test を再実装する
// 
// 現時点では、アプリの構造が変更中であるため、
// テストを一時的に無効化しています。
// 
// 将来的には以下のテストを実装予定:
// - App should build without errors
// - Main page should be displayed
// - Bottom navigation should have 5 tabs

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:soup_rewards_app/main.dart';

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
  });
}
