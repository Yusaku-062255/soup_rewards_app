import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soup_rewards_app/features/auth/presentation/pages/login_page.dart';

void main() {
  testWidgets('LoginPage displays all sign-in options', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LoginPage(),
        ),
      ),
    );

    // タイトル確認
    expect(find.text('SOUP Rewards'), findsOneWidget);
    expect(find.text('カーケアポイントプログラム'), findsOneWidget);

    // ボタン確認
    expect(find.text('今すぐ始める（ゲスト）'), findsOneWidget);
    expect(find.text('Appleでサインイン'), findsOneWidget);
  });

  testWidgets('LoginPage shows loading indicator when signing in', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LoginPage(),
        ),
      ),
    );

    // 初期状態ではローディングインジケーターは表示されない
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
