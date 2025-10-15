import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soup_rewards_app/features/home/presentation/pages/home_page.dart';

void main() {
  group('HomePage Widget Tests', () {
    setUp(() async {
      // SharedPreferencesのモックを初期化
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('ホームページが正常に表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomePage(),
          ),
        ),
      );

      // AppBarのタイトルを確認
      expect(find.text('SOUP Rewards'), findsOneWidget);

      // ウェルカムメッセージを確認
      expect(find.text('おかえりなさい！'), findsOneWidget);
      expect(find.text('SOUP Rewardsへようこそ'), findsOneWidget);

      // ポイント残高カードを確認
      expect(find.text('ポイント残高'), findsOneWidget);

      // マイカー情報カードを確認
      expect(find.text('マイカー登録'), findsOneWidget);

      // クイックアクションを確認
      expect(find.text('クイックアクション'), findsOneWidget);
      expect(find.text('QRスキャン'), findsOneWidget);
      expect(find.text('クーポン'), findsOneWidget);

      // お知らせセクションを確認
      expect(find.text('お知らせ'), findsOneWidget);
    });

    testWidgets('ローディング状態が正常に表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomePage(),
          ),
        ),
      );

      // 初期状態ではローディングが表示される可能性がある
      // pumpAndSettleで非同期処理の完了を待つ
      await tester.pumpAndSettle();

      // ローディング完了後の状態を確認
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('ポイント詳細画面への遷移', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomePage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // ポイント残高カードをタップ
      final pointsCard = find.text('ポイント残高');
      expect(pointsCard, findsOneWidget);

      await tester.tap(pointsCard);
      await tester.pumpAndSettle();

      // ポイント詳細画面に遷移することを確認
      expect(find.text('ポイント詳細'), findsOneWidget);
    });

    testWidgets('マイカー登録画面への遷移', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomePage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // マイカー登録カードをタップ
      final vehicleCard = find.text('マイカー登録');
      expect(vehicleCard, findsOneWidget);

      await tester.tap(vehicleCard);
      await tester.pumpAndSettle();

      // マイカー登録画面に遷移することを確認
      expect(find.text('マイカー登録'), findsWidgets);
    });

    testWidgets('クイックアクションボタンの動作', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomePage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // QRスキャンボタンをタップ
      final qrButton = find.text('QRスキャン');
      expect(qrButton, findsOneWidget);

      await tester.tap(qrButton);
      await tester.pumpAndSettle();

      // スナックバーが表示されることを確認
      expect(find.text('QRスキャン機能は今後実装予定です'), findsOneWidget);
    });

    testWidgets('プルトゥリフレッシュの動作', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomePage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // RefreshIndicatorを見つけてドラッグ
      final refreshIndicator = find.byType(RefreshIndicator);
      expect(refreshIndicator, findsOneWidget);

      await tester.drag(refreshIndicator, const Offset(0, 300));
      await tester.pumpAndSettle();

      // リフレッシュ後も正常に表示されることを確認
      expect(find.text('SOUP Rewards'), findsOneWidget);
    });

    testWidgets('車両情報がある場合の表示', (WidgetTester tester) async {
      // 車両情報をモックデータとして設定
      SharedPreferences.setMockInitialValues({
        'user_vehicle': '{"name":"プリウス","manufacturer":"トヨタ","year":2020,"isEv":false}',
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomePage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // マイカー情報が表示されることを確認
      expect(find.text('マイカー情報'), findsOneWidget);
      expect(find.text('トヨタ プリウス'), findsOneWidget);
      expect(find.text('2020年式'), findsOneWidget);
      expect(find.text('ガソリン車'), findsOneWidget);
    });

    testWidgets('EV車の場合の特典表示', (WidgetTester tester) async {
      // EV車の情報をモックデータとして設定
      SharedPreferences.setMockInitialValues({
        'user_vehicle': '{"name":"リーフ","manufacturer":"日産","year":2022,"isEv":true}',
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomePage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // EV特典の表示を確認
      expect(find.text('EV特典'), findsOneWidget);
      expect(find.text('日産 リーフ'), findsOneWidget);
      expect(find.text('EV'), findsOneWidget);
    });

    testWidgets('ポイント情報がある場合の表示', (WidgetTester tester) async {
      // ポイント情報をモックデータとして設定
      SharedPreferences.setMockInitialValues({
        'user_points': '1500',
        'total_earned_points': '2000',
        'last_login_date': DateTime.now().toIso8601String(),
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomePage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // ポイント残高が表示されることを確認
      expect(find.text('1500'), findsOneWidget);
      expect(find.text('pt'), findsWidgets);
    });

    testWidgets('お知らせセクションの表示', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomePage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // お知らせの項目を確認
      expect(find.text('SOUP Rewardsアプリリリース！'), findsOneWidget);
      expect(find.text('EV車特典開始'), findsOneWidget);
      expect(find.text('毎日ログインボーナス'), findsOneWidget);

      // 日付の表示を確認
      expect(find.text('2024/10/14'), findsNWidgets(3));
    });

    testWidgets('レスポンシブデザインの確認', (WidgetTester tester) async {
      // 小さい画面サイズでテスト
      await tester.binding.setSurfaceSize(const Size(320, 568));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomePage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 小さい画面でも正常に表示されることを確認
      expect(find.text('SOUP Rewards'), findsOneWidget);
      expect(find.text('おかえりなさい！'), findsOneWidget);

      // 大きい画面サイズでテスト
      await tester.binding.setSurfaceSize(const Size(414, 896));
      await tester.pumpAndSettle();

      // 大きい画面でも正常に表示されることを確認
      expect(find.text('SOUP Rewards'), findsOneWidget);
      expect(find.text('おかえりなさい！'), findsOneWidget);

      // サイズをリセット
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('アクセシビリティの確認', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomePage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // セマンティクスが適切に設定されているかを確認
      expect(tester.getSemantics(find.text('SOUP Rewards')), isNotNull);
      expect(tester.getSemantics(find.text('ポイント残高')), isNotNull);
      expect(tester.getSemantics(find.text('QRスキャン')), isNotNull);
      expect(tester.getSemantics(find.text('クーポン')), isNotNull);
    });

    testWidgets('エラー状態の処理', (WidgetTester tester) async {
      // 不正なデータを設定してエラー状態をシミュレート
      SharedPreferences.setMockInitialValues({
        'user_points': 'invalid_data',
        'user_vehicle': 'invalid_json',
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomePage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // エラーが発生してもアプリがクラッシュしないことを確認
      expect(find.text('SOUP Rewards'), findsOneWidget);
      expect(find.text('0'), findsOneWidget); // デフォルトのポイント値
      expect(find.text('マイカー登録'), findsOneWidget); // デフォルトの車両状態
    });
  });
}
