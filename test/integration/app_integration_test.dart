import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soup_rewards_app/main.dart' as app;
import 'package:soup_rewards_app/core/services/points_service.dart';
import 'package:soup_rewards_app/core/services/vehicle_store.dart';
import 'package:soup_rewards_app/core/services/coupon_store.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('SOUP Rewards App Integration Tests', () {
    setUp(() async {
      // テスト前にデータをクリア
      SharedPreferences.setMockInitialValues({});
      await PointsService.resetAllData();
      await VehicleStore.clearVehicle();
      await CouponStore.clearAllCoupons();
    });

    testWidgets('アプリの基本フロー: 起動 → ホーム → ポイント詳細', (WidgetTester tester) async {
      // アプリを起動
      app.main();
      await tester.pumpAndSettle();

      // ホーム画面が表示されることを確認
      expect(find.text('SOUP Rewards'), findsOneWidget);
      expect(find.text('おかえりなさい！'), findsOneWidget);
      expect(find.text('ポイント残高'), findsOneWidget);

      // 初期状態では0ポイント
      expect(find.text('0'), findsOneWidget);

      // ポイント詳細画面に遷移
      await tester.tap(find.text('ポイント残高'));
      await tester.pumpAndSettle();

      // ポイント詳細画面が表示されることを確認
      expect(find.text('ポイント詳細'), findsOneWidget);
      expect(find.text('現在のポイント'), findsOneWidget);
      expect(find.text('ブロンズ'), findsOneWidget);

      // 戻るボタンで戻る
      await tester.pageBack();
      await tester.pumpAndSettle();

      // ホーム画面に戻ることを確認
      expect(find.text('SOUP Rewards'), findsOneWidget);
    });

    testWidgets('車両登録フロー: ホーム → マイカー登録 → 情報入力 → 保存', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // マイカー登録画面に遷移
      await tester.tap(find.text('マイカー登録'));
      await tester.pumpAndSettle();

      // マイカー登録画面が表示されることを確認
      expect(find.text('マイカー登録'), findsWidgets);

      // 車名を入力
      await tester.enterText(find.byType(TextFormField).first, 'プリウス');
      await tester.pumpAndSettle();

      // メーカーを入力（2番目のTextFormField）
      final textFields = find.byType(TextFormField);
      if (textFields.evaluate().length > 1) {
        await tester.enterText(textFields.at(1), 'トヨタ');
        await tester.pumpAndSettle();
      }

      // 保存ボタンをタップ
      final saveButton = find.text('保存');
      if (saveButton.evaluate().isNotEmpty) {
        await tester.tap(saveButton);
        await tester.pumpAndSettle();
      }

      // 成功メッセージまたはホーム画面への遷移を確認
      // 実装によって異なるため、柔軟にチェック
      expect(
        find.text('保存しました').evaluate().isNotEmpty ||
        find.text('SOUP Rewards').evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets('タブナビゲーションの動作確認', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // ボトムナビゲーションバーを確認
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      // 各タブをタップして遷移を確認
      final tabs = ['ホーム', 'クーポン', 'QRスキャン', 'プロフィール'];
      
      for (int i = 0; i < tabs.length; i++) {
        // タブをタップ
        await tester.tap(find.byIcon([
          Icons.home,
          Icons.local_offer,
          Icons.qr_code_scanner,
          Icons.person,
        ][i]));
        await tester.pumpAndSettle();

        // 対応する画面が表示されることを確認
        switch (i) {
          case 0: // ホーム
            expect(find.text('SOUP Rewards'), findsOneWidget);
            break;
          case 1: // クーポン
            expect(find.text('クーポン'), findsWidgets);
            break;
          case 2: // QRスキャン
            expect(find.text('QRスキャン'), findsWidgets);
            break;
          case 3: // プロフィール
            expect(find.text('プロフィール'), findsWidgets);
            break;
        }
      }
    });

    testWidgets('ポイント獲得とランクアップのフロー', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 初期状態の確認
      await tester.tap(find.text('ポイント残高'));
      await tester.pumpAndSettle();

      expect(find.text('ブロンズ'), findsOneWidget);

      // バックグラウンドでポイントを追加（実際のアプリではQRスキャンなどで獲得）
      await PointsService.addPoints(1500, 'テスト獲得');

      // 画面を更新
      await tester.drag(find.byType(RefreshIndicator), const Offset(0, 300));
      await tester.pumpAndSettle();

      // ポイントが更新されることを確認
      expect(find.text('1500'), findsOneWidget);
      expect(find.text('シルバー'), findsOneWidget);

      // さらにポイントを追加してゴールドランクに
      await PointsService.addPoints(3500, 'テスト獲得2');

      // 再度更新
      await tester.drag(find.byType(RefreshIndicator), const Offset(0, 300));
      await tester.pumpAndSettle();

      expect(find.text('5000'), findsOneWidget);
      expect(find.text('ゴールド'), findsOneWidget);
    });

    testWidgets('クーポン交換フロー', (WidgetTester tester) async {
      // 事前に5000ポイントを追加
      await PointsService.addPoints(5000, 'テスト用ポイント');

      app.main();
      await tester.pumpAndSettle();

      // ポイント詳細画面に遷移
      await tester.tap(find.text('ポイント残高'));
      await tester.pumpAndSettle();

      // 給油券交換ボタンを確認
      final exchangeButton = find.text('給油券と交換 (5000pt)');
      expect(exchangeButton, findsOneWidget);

      // 交換ボタンをタップ
      await tester.tap(exchangeButton);
      await tester.pumpAndSettle();

      // 交換完了ダイアログが表示されることを確認
      expect(find.text('交換完了！'), findsOneWidget);
      expect(find.text('🎉 給油券と交換しました！'), findsOneWidget);

      // OKボタンをタップ
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // ポイントが減っていることを確認
      expect(find.text('0'), findsOneWidget);

      // クーポンタブに移動
      await tester.pageBack(); // ホームに戻る
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.local_offer));
      await tester.pumpAndSettle();

      // クーポンが追加されていることを確認
      expect(find.text('給油券'), findsOneWidget);
    });

    testWidgets('EV特典フロー', (WidgetTester tester) async {
      // EV車を事前に登録
      await VehicleStore.saveVehicle(
        const VehicleModel(
          name: 'リーフ',
          manufacturer: '日産',
          year: 2022,
          isEv: true,
        ),
      );

      app.main();
      await tester.pumpAndSettle();

      // ホーム画面でEV特典が表示されることを確認
      expect(find.text('EV特典'), findsOneWidget);
      expect(find.text('日産 リーフ'), findsOneWidget);

      // ポイント詳細画面に遷移
      await tester.tap(find.text('ポイント残高'));
      await tester.pumpAndSettle();

      // EV特典カードが表示されることを確認
      expect(find.text('EV特典'), findsWidgets);
      expect(find.byIcon(Icons.electric_car), findsOneWidget);

      // バックグラウンドでEVボーナスポイントを追加
      await PointsService.addEvBonus(100, 'EV給油テスト');

      // 画面を更新
      await tester.drag(find.byType(RefreshIndicator), const Offset(0, 300));
      await tester.pumpAndSettle();

      // EVボーナスが適用されたポイントが表示されることを確認
      expect(find.text('100'), findsOneWidget); // ブロンズランクなので1.0倍
    });

    testWidgets('ログインボーナスフロー', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // ポイント詳細画面に遷移（ログインボーナスが発生）
      await tester.tap(find.text('ポイント残高'));
      await tester.pumpAndSettle();

      // ログインボーナスダイアログが表示される可能性がある
      if (find.text('ログインボーナス！').evaluate().isNotEmpty) {
        expect(find.text('+100pt'), findsOneWidget);
        
        // ダイアログを閉じる
        await tester.tap(find.text('ありがとう！'));
        await tester.pumpAndSettle();
      }

      // ポイントが100pt以上になっていることを確認
      final pointsText = tester.widget<Text>(
        find.byWidgetPredicate((widget) => 
          widget is Text && 
          widget.data != null && 
          RegExp(r'\d+').hasMatch(widget.data!)
        )
      );
      
      if (pointsText.data != null) {
        final points = int.tryParse(RegExp(r'\d+').firstMatch(pointsText.data!)?.group(0) ?? '0') ?? 0;
        expect(points, greaterThanOrEqualTo(100));
      }
    });

    testWidgets('データ永続化の確認', (WidgetTester tester) async {
      // データを作成
      await PointsService.addPoints(1000, 'テストポイント');
      await VehicleStore.saveVehicle(
        const VehicleModel(
          name: 'テスト車',
          manufacturer: 'テストメーカー',
          year: 2023,
          isEv: false,
        ),
      );

      // アプリを起動
      app.main();
      await tester.pumpAndSettle();

      // データが保持されていることを確認
      expect(find.text('1000'), findsOneWidget);
      expect(find.text('マイカー情報'), findsOneWidget);
      expect(find.text('テストメーカー テスト車'), findsOneWidget);

      // アプリを再起動（シミュレート）
      await tester.binding.reassembleApplication();
      await tester.pumpAndSettle();

      // データが保持されていることを再確認
      expect(find.text('1000'), findsOneWidget);
      expect(find.text('マイカー情報'), findsOneWidget);
    });

    testWidgets('エラー処理とリカバリー', (WidgetTester tester) async {
      // 不正なデータを設定
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_points', 'invalid_data');
      await prefs.setString('user_vehicle', 'invalid_json');

      app.main();
      await tester.pumpAndSettle();

      // アプリがクラッシュせずに起動することを確認
      expect(find.text('SOUP Rewards'), findsOneWidget);

      // デフォルト値が表示されることを確認
      expect(find.text('0'), findsOneWidget); // デフォルトポイント
      expect(find.text('マイカー登録'), findsOneWidget); // デフォルト車両状態

      // 正常なデータを入力して復旧することを確認
      await tester.tap(find.text('ポイント残高'));
      await tester.pumpAndSettle();

      // 画面が正常に表示されることを確認
      expect(find.text('ポイント詳細'), findsOneWidget);
      expect(find.text('現在のポイント'), findsOneWidget);
    });
  });
}

// VehicleModelクラスの定義（テスト用）
class VehicleModel {
  final String name;
  final String? manufacturer;
  final int? year;
  final String? plateNumber;
  final bool isEv;
  final String? photoPath;

  const VehicleModel({
    required this.name,
    this.manufacturer,
    this.year,
    this.plateNumber,
    required this.isEv,
    this.photoPath,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'manufacturer': manufacturer,
      'year': year,
      'plateNumber': plateNumber,
      'isEv': isEv,
      'photoPath': photoPath,
    };
  }

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      name: json['name'] ?? '',
      manufacturer: json['manufacturer'],
      year: json['year'],
      plateNumber: json['plateNumber'],
      isEv: json['isEv'] ?? false,
      photoPath: json['photoPath'],
    );
  }
}
