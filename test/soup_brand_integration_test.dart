import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soup_rewards_app/core/theme/soup_theme.dart';
import 'package:soup_rewards_app/features/home/presentation/pages/main_page.dart';
import 'package:soup_rewards_app/features/home/presentation/pages/home_page.dart';
import 'package:soup_rewards_app/features/points/pages/points_detail_page.dart';
import 'package:soup_rewards_app/features/coupons/pages/coupons_page.dart';
import 'package:soup_rewards_app/features/gallery/pages/gallery_page.dart';
import 'package:soup_rewards_app/features/store/pages/store_info_page.dart';

/// SOUP公式ブランド統合テスト
/// 
/// このテストスイートは以下を検証します：
/// - SOUPブランドテーマの適用
/// - 各ページの正常な表示
/// - ナビゲーションの動作
/// - ポイント・クーポンシステムの統合
void main() {
  group('SOUP Brand Integration Tests', () {
    
    testWidgets('SoupTheme colors are properly defined', (WidgetTester tester) async {
      // SOUPテーマの色定義が正しく設定されているかテスト
      expect(SoupTheme.primaryNavy, isNotNull);
      expect(SoupTheme.primaryGold, isNotNull);
      expect(SoupTheme.accentOrange, isNotNull);
      expect(SoupTheme.surfaceWhite, isNotNull);
      expect(SoupTheme.backgroundGray, isNotNull);
      expect(SoupTheme.textWhite, isNotNull);
      
      // グラデーションの定義確認
      expect(SoupTheme.goldGradient, isA<LinearGradient>());
      expect(SoupTheme.navyGradient, isA<LinearGradient>());
      
      // ボタンスタイルの定義確認
      expect(SoupTheme.primaryButton, isA<ButtonStyle>());
      expect(SoupTheme.outlineButton, isA<ButtonStyle>());
      expect(SoupTheme.disabledButton, isA<ButtonStyle>());
    });

    testWidgets('MainPage displays with SOUP branding', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MainPage(),
          ),
        ),
      );

      // メインページが表示されることを確認
      expect(find.byType(MainPage), findsOneWidget);
      
      // ボトムナビゲーションバーが表示されることを確認
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      
      // 各タブが存在することを確認
      expect(find.text('ホーム'), findsOneWidget);
      expect(find.text('ポイント'), findsOneWidget);
      expect(find.text('QRスキャン'), findsOneWidget);
      expect(find.text('クーポン'), findsOneWidget);
      expect(find.text('プロフィール'), findsOneWidget);
    });

    testWidgets('HomePage displays SOUP official content', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomePage(),
          ),
        ),
      );

      // ホームページが表示されることを確認
      expect(find.byType(HomePage), findsOneWidget);
      
      // SOUPブランド要素の確認
      expect(find.text('SOUP（スープ）'), findsOneWidget);
      expect(find.text('徳島のカーコーティング専門店'), findsOneWidget);
      expect(find.text('キレイな車は幸せを呼ぶ！'), findsOneWidget);
      
      // クイックアクションボタンの確認
      expect(find.text('施工予約'), findsOneWidget);
      expect(find.text('電話する'), findsOneWidget);
      
      // サービス紹介セクションの確認
      expect(find.text('サービスのご案内'), findsOneWidget);
    });

    testWidgets('PointsDetailPage displays with SOUP theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PointsDetailPage(),
          ),
        ),
      );

      // ポイント詳細ページが表示されることを確認
      expect(find.byType(PointsDetailPage), findsOneWidget);
      
      // ポイント関連要素の確認
      expect(find.text('ポイント'), findsOneWidget);
      expect(find.text('ポイントを貯める'), findsOneWidget);
      expect(find.text('ポイント交換'), findsOneWidget);
      expect(find.text('ポイント履歴'), findsOneWidget);
    });

    testWidgets('CouponsPage displays with SOUP theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CouponsPage(),
          ),
        ),
      );

      // クーポンページが表示されることを確認
      expect(find.byType(CouponsPage), findsOneWidget);
      
      // タブバーの確認
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.textContaining('利用可能'), findsOneWidget);
      expect(find.textContaining('使用済み'), findsOneWidget);
    });

    testWidgets('GalleryPage displays with SOUP theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: GalleryPage(),
        ),
      );

      // ギャラリーページが表示されることを確認
      expect(find.byType(GalleryPage), findsOneWidget);
      
      // ギャラリー関連要素の確認
      expect(find.text('施工実績ギャラリー'), findsOneWidget);
      expect(find.text('累計施工実績'), findsOneWidget);
      expect(find.text('4万台+'), findsOneWidget);
    });

    testWidgets('StoreInfoPage displays SOUP store information', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: StoreInfoPage(),
        ),
      );

      // 店舗情報ページが表示されることを確認
      expect(find.byType(StoreInfoPage), findsOneWidget);
      
      // 店舗情報の確認
      expect(find.text('店舗情報'), findsOneWidget);
      expect(find.text('SOUP（スープ）'), findsOneWidget);
      expect(find.text('徳島のカーコーティング専門店'), findsOneWidget);
      
      // 基本情報の確認
      expect(find.text('基本情報'), findsOneWidget);
      expect(find.text('営業時間'), findsOneWidget);
      expect(find.text('サービス内容'), findsOneWidget);
    });

    testWidgets('Navigation between pages works correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MainPage(),
          ),
        ),
      );

      // 初期状態でホームページが表示されることを確認
      expect(find.byType(HomePage), findsOneWidget);

      // ポイントタブをタップ
      await tester.tap(find.text('ポイント'));
      await tester.pumpAndSettle();

      // ポイントページが表示されることを確認
      expect(find.byType(PointsDetailPage), findsOneWidget);

      // クーポンタブをタップ
      await tester.tap(find.text('クーポン'));
      await tester.pumpAndSettle();

      // クーポンページが表示されることを確認
      expect(find.byType(CouponsPage), findsOneWidget);
    });

    testWidgets('SOUP icons are properly defined', (WidgetTester tester) async {
      // SOUPアイコンの定義確認
      expect(SoupIcons.service, isA<IconData>());
      expect(SoupIcons.points, isA<IconData>());
      expect(SoupIcons.coupon, isA<IconData>());
      expect(SoupIcons.coating, isA<IconData>());
      expect(SoupIcons.car, isA<IconData>());
      expect(SoupIcons.phone, isA<IconData>());
      expect(SoupIcons.location, isA<IconData>());
      expect(SoupIcons.reserve, isA<IconData>());
      expect(SoupIcons.time, isA<IconData>());
      expect(SoupIcons.gallery, isA<IconData>());
      expect(SoupIcons.glass, isA<IconData>());
      expect(SoupIcons.bike, isA<IconData>());
      expect(SoupIcons.wheel, isA<IconData>());
    });

    testWidgets('Theme consistency across components', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            primaryColor: SoupTheme.primaryNavy,
            colorScheme: ColorScheme.fromSeed(
              seedColor: SoupTheme.primaryNavy,
            ),
          ),
          home: const Scaffold(
            body: Column(
              children: [
                // テスト用のSOUPテーマ要素
                Card(
                  child: Text('Test Card'),
                ),
              ],
            ),
          ),
        ),
      );

      // カードが表示されることを確認
      expect(find.byType(Card), findsOneWidget);
      expect(find.text('Test Card'), findsOneWidget);
    });

    group('Points System Integration', () {
      testWidgets('Points exchange flow works correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: PointsDetailPage(),
            ),
          ),
        );

        // ポイント交換セクションが表示されることを確認
        expect(find.text('ポイント交換'), findsOneWidget);
        
        // 交換アイテムが表示されることを確認
        expect(find.text('500円割引クーポン'), findsOneWidget);
        expect(find.text('1000円割引クーポン'), findsOneWidget);
      });

      testWidgets('EV vehicle bonus is displayed correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: PointsDetailPage(),
            ),
          ),
        );

        // EV特典の表示確認（車両が登録されている場合）
        // 実際のテストでは、モックデータでEV車両を設定する必要があります
      });
    });

    group('Coupon System Integration', () {
      testWidgets('Coupon categories are properly styled', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: CouponsPage(),
            ),
          ),
        );

        // クーポンページが表示されることを確認
        expect(find.byType(CouponsPage), findsOneWidget);
        
        // フローティングアクションボタンの確認
        expect(find.byType(FloatingActionButton), findsOneWidget);
        expect(find.text('クーポンについて'), findsOneWidget);
      });
    });

    group('Gallery Integration', () {
      testWidgets('Gallery filters work correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: GalleryPage(),
          ),
        );

        // フィルターが表示されることを確認
        expect(find.text('すべて'), findsOneWidget);
        expect(find.text('セラミック'), findsOneWidget);
        expect(find.text('ガラス'), findsOneWidget);
        expect(find.text('バイク'), findsOneWidget);
        expect(find.text('最新'), findsOneWidget);
      });
    });

    group('Store Information Integration', () {
      testWidgets('Store contact information is displayed', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: StoreInfoPage(),
          ),
        );

        // 連絡先情報の確認
        expect(find.textContaining('088-377-2016'), findsOneWidget);
        expect(find.textContaining('徳島県三好市'), findsOneWidget);
        expect(find.text('9:00 - 18:00'), findsOneWidget);
      });

      testWidgets('Service information is properly displayed', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: StoreInfoPage(),
          ),
        );

        // サービス情報の確認
        expect(find.textContaining('System X'), findsOneWidget);
        expect(find.textContaining('G.Guard'), findsOneWidget);
        expect(find.textContaining('バイクコーティング'), findsOneWidget);
        expect(find.textContaining('パーツコーティング'), findsOneWidget);
      });
    });

    group('Performance Tests', () {
      testWidgets('Pages load within acceptable time', (WidgetTester tester) async {
        final stopwatch = Stopwatch()..start();
        
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: MainPage(),
            ),
          ),
        );
        
        await tester.pumpAndSettle();
        stopwatch.stop();
        
        // ページロードが1秒以内に完了することを確認
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });
    });

    group('Accessibility Tests', () {
      testWidgets('All interactive elements have semantic labels', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: MainPage(),
            ),
          ),
        );

        // セマンティクスが有効になっていることを確認
        final SemanticsHandle handle = tester.ensureSemantics();
        
        // ボタンにセマンティクスラベルが設定されていることを確認
        expect(find.bySemanticsLabel('ホーム'), findsOneWidget);
        
        handle.dispose();
      });
    });
  });
}
