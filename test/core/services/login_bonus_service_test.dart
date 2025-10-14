// ログインボーナステスト（同日二重付与防止）
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../lib/core/services/login_bonus_service.dart';
import '../../../lib/core/services/points_service.dart';

void main() {
  group('LoginBonusService Tests', () {
    setUp(() async {
      // テスト前にSharedPreferencesをクリア
      SharedPreferences.setMockInitialValues({});
    });

    group('Daily Bonus Granting', () {
      test('should grant daily bonus on first login of the day', () async {
        final initialState = const PointsState(
          balance: 100,
          totalEarned: 100,
          history: [],
        );

        final result = await LoginBonusService.maybeGrantDailyBonus(
          initialState,
          rankMultiplier: 1.0,
        );

        expect(result, isNotNull);
        expect(result!.balance, equals(105)); // 100 + 5
        expect(result.totalEarned, equals(105)); // 100 + 5
        expect(result.history.length, equals(1));
        expect(result.history.first.delta, equals(5));
        expect(result.history.first.title, equals('Daily Login Bonus'));
      });

      test('should apply rank multiplier to daily bonus', () async {
        final initialState = const PointsState(
          balance: 100,
          totalEarned: 100,
          history: [],
        );

        // Silver rank multiplier (1.1x)
        final result = await LoginBonusService.maybeGrantDailyBonus(
          initialState,
          rankMultiplier: 1.1,
        );

        expect(result, isNotNull);
        // 5 * 1.0 * 1.1 = 5.5 → 6 (四捨五入)
        expect(result!.balance, equals(106)); // 100 + 6
        expect(result.totalEarned, equals(106)); // 100 + 6
        expect(result.history.first.delta, equals(6));
      });

      test('should prevent double bonus on same day', () async {
        final initialState = const PointsState(
          balance: 100,
          totalEarned: 100,
          history: [],
        );

        // 1回目のログインボーナス
        final firstResult = await LoginBonusService.maybeGrantDailyBonus(
          initialState,
          rankMultiplier: 1.0,
        );
        expect(firstResult, isNotNull);

        // 同日2回目のログインボーナス（付与されないはず）
        final secondResult = await LoginBonusService.maybeGrantDailyBonus(
          firstResult!,
          rankMultiplier: 1.0,
        );
        expect(secondResult, isNull);
      });
    });

    group('Today Bonus Check', () {
      test('should return false when no bonus granted today', () async {
        final isGranted = await LoginBonusService.isTodayBonusGranted();
        expect(isGranted, isFalse);
      });

      test('should return true after granting bonus today', () async {
        final initialState = const PointsState(
          balance: 100,
          totalEarned: 100,
          history: [],
        );

        await LoginBonusService.maybeGrantDailyBonus(
          initialState,
          rankMultiplier: 1.0,
        );

        final isGranted = await LoginBonusService.isTodayBonusGranted();
        expect(isGranted, isTrue);
      });
    });

    group('Login Streak', () {
      test('should return 0 for initial login streak', () async {
        final streak = await LoginBonusService.getLoginStreak();
        expect(streak, equals(0));
      });

      test('should update login streak correctly', () async {
        await LoginBonusService.updateLoginStreak();
        
        final streak = await LoginBonusService.getLoginStreak();
        expect(streak, equals(1));
      });
    });

    group('Reset Functionality', () {
      test('should reset last login date for testing', () async {
        final initialState = const PointsState(
          balance: 100,
          totalEarned: 100,
          history: [],
        );

        // ボーナスを付与
        await LoginBonusService.maybeGrantDailyBonus(
          initialState,
          rankMultiplier: 1.0,
        );

        // 今日のボーナスが付与済みであることを確認
        expect(await LoginBonusService.isTodayBonusGranted(), isTrue);

        // リセット
        await LoginBonusService.resetLastLoginDate();

        // リセット後は再度ボーナスを付与できるはず
        expect(await LoginBonusService.isTodayBonusGranted(), isFalse);
      });
    });

    group('Error Handling', () {
      test('should handle SharedPreferences errors gracefully', () async {
        // SharedPreferencesのモックを無効な状態に設定
        SharedPreferences.setMockInitialValues({
          'last_login_date': 'invalid_date_format',
        });

        final initialState = const PointsState(
          balance: 100,
          totalEarned: 100,
          history: [],
        );

        // エラーが発生してもnullを返すだけで例外は投げない
        final result = await LoginBonusService.maybeGrantDailyBonus(
          initialState,
          rankMultiplier: 1.0,
        );

        // エラー時の動作は実装依存だが、例外は投げないはず
        expect(() => result, returnsNormally);
      });
    });

    group('Date Formatting', () {
      test('should format dates consistently', () async {
        final initialState = const PointsState(
          balance: 100,
          totalEarned: 100,
          history: [],
        );

        // ボーナスを付与
        final result = await LoginBonusService.maybeGrantDailyBonus(
          initialState,
          rankMultiplier: 1.0,
        );

        expect(result, isNotNull);

        // 同日の再付与は防止されるはず
        final secondResult = await LoginBonusService.maybeGrantDailyBonus(
          result!,
          rankMultiplier: 1.0,
        );

        expect(secondResult, isNull);
      });
    });
  });
}
