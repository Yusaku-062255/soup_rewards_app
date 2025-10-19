import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soup_rewards_app/core/services/points_service.dart';

void main() {
  group('PointsService', () {
    setUp(() async {
      // SharedPreferencesのモックを初期化
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() async {
      // テスト後にデータをクリア
      await PointsService.resetAllData();
    });

    group('ポイント残高管理', () {
      test('初期状態では0ポイント', () async {
        final currentPoints = await PointsService.getCurrentPoints();
        expect(currentPoints, equals(0));
      });

      test('ポイント追加が正常に動作する', () async {
        final success = await PointsService.addPoints(100, 'テスト獲得');
        expect(success, isTrue);

        final currentPoints = await PointsService.getCurrentPoints();
        expect(currentPoints, equals(100));
      });

      test('ポイント使用が正常に動作する', () async {
        // 先にポイントを追加
        await PointsService.addPoints(500, 'テスト獲得');

        final success = await PointsService.spendPoints(200, 'テスト使用');
        expect(success, isTrue);

        final currentPoints = await PointsService.getCurrentPoints();
        expect(currentPoints, equals(300));
      });

      test('残高不足の場合はポイント使用が失敗する', () async {
        await PointsService.addPoints(100, 'テスト獲得');

        final success = await PointsService.spendPoints(200, 'テスト使用');
        expect(success, isFalse);

        final currentPoints = await PointsService.getCurrentPoints();
        expect(currentPoints, equals(100)); // 変更されない
      });
    });

    group('累計獲得ポイント管理', () {
      test('初期状態では0ポイント', () async {
        final totalEarned = await PointsService.getTotalEarnedPoints();
        expect(totalEarned, equals(0));
      });

      test('ポイント獲得時に累計が増加する', () async {
        await PointsService.addPoints(100, 'テスト獲得1');
        await PointsService.addPoints(200, 'テスト獲得2');

        final totalEarned = await PointsService.getTotalEarnedPoints();
        expect(totalEarned, equals(300));
      });

      test('ポイント使用時は累計が変わらない', () async {
        await PointsService.addPoints(500, 'テスト獲得');
        await PointsService.spendPoints(200, 'テスト使用');

        final totalEarned = await PointsService.getTotalEarnedPoints();
        expect(totalEarned, equals(500)); // 使用しても累計は変わらない
      });

      test('ボーナスポイントも累計に含まれる', () async {
        await PointsService.addPoints(100, 'テスト獲得', type: PointTransactionType.earn);
        await PointsService.addPoints(50, 'ボーナス', type: PointTransactionType.bonus);

        final totalEarned = await PointsService.getTotalEarnedPoints();
        expect(totalEarned, equals(150));
      });
    });

    group('ランクシステム', () {
      test('0ポイントではブロンズランク', () async {
        final rank = await PointsService.getCurrentRank();
        expect(rank.name, equals('ブロンズ'));
        expect(rank.minPoints, equals(0));
      });

      test('1000ポイントでシルバーランク', () async {
        await PointsService.addPoints(1000, 'テスト獲得');
        final rank = await PointsService.getCurrentRank();
        expect(rank.name, equals('シルバー'));
      });

      test('5000ポイントでゴールドランク', () async {
        await PointsService.addPoints(5000, 'テスト獲得');
        final rank = await PointsService.getCurrentRank();
        expect(rank.name, equals('ゴールド'));
      });

      test('次のランク情報が正しく取得できる', () async {
        await PointsService.addPoints(500, 'テスト獲得');
        
        final nextRank = await PointsService.getNextRank();
        expect(nextRank?.name, equals('シルバー'));
        
        final pointsToNext = await PointsService.getPointsToNextRank();
        expect(pointsToNext, equals(500)); // 1000 - 500 = 500
      });

      test('最高ランクでは次のランクがnull', () async {
        await PointsService.addPoints(50000, 'テスト獲得');
        
        final nextRank = await PointsService.getNextRank();
        expect(nextRank, isNull);
        
        final pointsToNext = await PointsService.getPointsToNextRank();
        expect(pointsToNext, equals(0));
      });

      test('ランク進捗が正しく計算される', () async {
        await PointsService.addPoints(1500, 'テスト獲得'); // シルバーランク内
        
        final progress = await PointsService.getRankProgress();
        // シルバーは1000-4999なので、1500は (1500-1000)/(4999-1000) = 500/3999 ≈ 0.125
        expect(progress, greaterThan(0.1));
        expect(progress, lessThan(0.2));
      });
    });

    group('取引履歴', () {
      test('初期状態では履歴が空', () async {
        final history = await PointsService.getTransactionHistory();
        expect(history, isEmpty);
      });

      test('取引履歴が正しく記録される', () async {
        await PointsService.addPoints(100, 'テスト獲得');
        await PointsService.spendPoints(50, 'テスト使用');

        final history = await PointsService.getTransactionHistory();
        expect(history.length, equals(2));
        
        // 新しい順でソートされている
        expect(history[0].description, equals('テスト使用'));
        expect(history[0].amount, equals(-50));
        expect(history[1].description, equals('テスト獲得'));
        expect(history[1].amount, equals(100));
      });

      test('履歴の件数制限が機能する', () async {
        // 多数の取引を作成
        for (int i = 0; i < 60; i++) {
          await PointsService.addPoints(10, 'テスト$i');
        }

        final history = await PointsService.getTransactionHistory(limit: 10);
        expect(history.length, equals(10));
      });
    });

    group('ログインボーナス', () {
      test('初回ログインでボーナスが付与される', () async {
        final result = await PointsService.checkLoginBonus();
        
        expect(result['isFirstLogin'], isTrue);
        expect(result['bonusAmount'], equals(100));
        
        final currentPoints = await PointsService.getCurrentPoints();
        expect(currentPoints, equals(100));
      });

      test('同日2回目のログインではボーナスなし', () async {
        // 1回目
        await PointsService.checkLoginBonus();
        
        // 2回目
        final result = await PointsService.checkLoginBonus();
        
        expect(result['isFirstLogin'], isFalse);
        expect(result['bonusAmount'], equals(0));
        
        final currentPoints = await PointsService.getCurrentPoints();
        expect(currentPoints, equals(100)); // 1回目の分のみ
      });
    });

    group('EV特典', () {
      test('EV特典ポイントが正しく計算される', () async {
        // ゴールドランク（1.5倍）でテスト
        await PointsService.addPoints(5000, 'ランクアップ用');
        
        final success = await PointsService.addEvBonus(100, 'EV給油');
        expect(success, isTrue);
        
        final currentPoints = await PointsService.getCurrentPoints();
        expect(currentPoints, equals(5000 + 150)); // 100 * 1.5 = 150
      });

      test('EV特典の取引履歴が正しく記録される', () async {
        await PointsService.addEvBonus(100, 'EV給油');
        
        final history = await PointsService.getTransactionHistory();
        expect(history.length, equals(1));
        expect(history[0].type, equals(PointTransactionType.evBonus));
        expect(history[0].description, contains('EV特典'));
      });
    });

    group('統計情報', () {
      test('統計情報が正しく取得できる', () async {
        await PointsService.addPoints(1500, 'テスト獲得');
        await PointsService.spendPoints(500, 'テスト使用');
        
        final stats = await PointsService.getPointsStats();
        
        expect(stats['currentPoints'], equals(1000));
        expect(stats['totalEarned'], equals(1500));
        expect(stats['currentRank']['name'], equals('シルバー'));
        expect(stats['nextRank']['name'], equals('ゴールド'));
        expect(stats['recentTransactions'], isNotEmpty);
      });

      test('エラー時でも統計情報が取得できる', () async {
        final stats = await PointsService.getPointsStats();
        
        expect(stats, isNotEmpty);
        expect(stats['currentPoints'], equals(0));
        expect(stats['totalEarned'], equals(0));
      });
    });

    group('データリセット', () {
      test('データリセットが正常に動作する', () async {
        // データを作成
        await PointsService.addPoints(1000, 'テスト');
        await PointsService.checkLoginBonus();
        
        // リセット実行
        final success = await PointsService.resetAllData();
        expect(success, isTrue);
        
        // データがクリアされていることを確認
        final currentPoints = await PointsService.getCurrentPoints();
        final totalEarned = await PointsService.getTotalEarnedPoints();
        final history = await PointsService.getTransactionHistory();
        
        expect(currentPoints, equals(0));
        expect(totalEarned, equals(0));
        expect(history, isEmpty);
      });
    });
  });
}
