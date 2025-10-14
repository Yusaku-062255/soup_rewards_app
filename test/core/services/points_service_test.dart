// ポイントサービステスト（四捨五入・交換・残高分離）
import 'package:flutter_test/flutter_test.dart';
import '../../../lib/core/services/points_service.dart';

void main() {
  group('PointsService Tests', () {
    late PointsState initialState;

    setUp(() {
      initialState = const PointsState(
        balance: 1000,
        totalEarned: 1500,
        history: [],
      );
    });

    group('Point Granting', () {
      test('should grant points with correct rounding', () {
        // 100 * 1.1 = 110.0 → 110 (四捨五入)
        final result = PointsService.grant(
          initialState,
          basePoint: 100,
          multiplier: 1.1,
          title: 'Test Bonus',
        );

        expect(result.balance, equals(1110)); // 1000 + 110
        expect(result.totalEarned, equals(1610)); // 1500 + 110
        expect(result.history.length, equals(1));
        expect(result.history.first.delta, equals(110));
        expect(result.history.first.title, equals('Test Bonus'));
      });

      test('should handle decimal rounding correctly', () {
        // 100 * 1.15 = 115.0 → 115
        final result1 = PointsService.grant(
          initialState,
          basePoint: 100,
          multiplier: 1.15,
          title: 'Test 1',
        );
        expect(result1.history.first.delta, equals(115));

        // 100 * 1.14 = 114.0 → 114
        final result2 = PointsService.grant(
          initialState,
          basePoint: 100,
          multiplier: 1.14,
          title: 'Test 2',
        );
        expect(result2.history.first.delta, equals(114));

        // 100 * 1.16 = 116.0 → 116
        final result3 = PointsService.grant(
          initialState,
          basePoint: 100,
          multiplier: 1.16,
          title: 'Test 3',
        );
        expect(result3.history.first.delta, equals(116));
      });

      test('should add history entry with correct timestamp', () {
        final beforeGrant = DateTime.now();
        
        final result = PointsService.grant(
          initialState,
          basePoint: 50,
          multiplier: 1.0,
          title: 'Timestamp Test',
          note: 'Test note',
        );

        final afterGrant = DateTime.now();
        final entry = result.history.first;

        expect(entry.date.isAfter(beforeGrant) || entry.date.isAtSameMomentAs(beforeGrant), isTrue);
        expect(entry.date.isBefore(afterGrant) || entry.date.isAtSameMomentAs(afterGrant), isTrue);
        expect(entry.note, equals('Test note'));
      });
    });

    group('Point Exchange', () {
      test('should exchange points successfully when sufficient balance', () {
        final result = PointsService.exchange(
          initialState,
          cost: 500,
          title: 'Fuel Voucher Exchange',
        );

        expect(result, isNotNull);
        expect(result!.balance, equals(500)); // 1000 - 500
        expect(result.totalEarned, equals(1500)); // 累計は変更されない
        expect(result.history.length, equals(1));
        expect(result.history.first.delta, equals(-500));
        expect(result.history.first.title, equals('Fuel Voucher Exchange'));
      });

      test('should fail exchange when insufficient balance', () {
        final result = PointsService.exchange(
          initialState,
          cost: 1500, // 残高1000より多い
          title: 'Expensive Item',
        );

        expect(result, isNull);
      });

      test('should not modify totalEarned during exchange', () {
        final originalTotalEarned = initialState.totalEarned;
        
        final result = PointsService.exchange(
          initialState,
          cost: 100,
          title: 'Test Exchange',
        );

        expect(result, isNotNull);
        expect(result!.totalEarned, equals(originalTotalEarned));
      });
    });

    group('Exchange Validation', () {
      test('canExchange should return correct values', () {
        expect(PointsService.canExchange(initialState, 500), isTrue);
        expect(PointsService.canExchange(initialState, 1000), isTrue);
        expect(PointsService.canExchange(initialState, 1001), isFalse);
        expect(PointsService.canExchange(initialState, 2000), isFalse);
      });
    });

    group('Statistics', () {
      test('should calculate stats correctly', () {
        // 履歴付きの状態を作成
        final stateWithHistory = initialState.copyWith(
          history: [
            PointEntry(
              date: DateTime.now(),
              delta: 100,
              title: 'Earned',
            ),
            PointEntry(
              date: DateTime.now(),
              delta: -50,
              title: 'Spent',
            ),
            PointEntry(
              date: DateTime.now(),
              delta: 25,
              title: 'Earned Again',
            ),
          ],
        );

        final stats = PointsService.getStats(stateWithHistory);

        expect(stats['balance'], equals(1000));
        expect(stats['totalEarned'], equals(1500));
        expect(stats['totalSpent'], equals(50));
        expect(stats['transactionCount'], equals(3));
        expect(stats['earnedTransactions'], equals(2));
        expect(stats['spentTransactions'], equals(1));
      });
    });

    group('JSON Serialization', () {
      test('PointsState should serialize and deserialize correctly', () {
        final originalState = PointsState(
          balance: 1000,
          totalEarned: 1500,
          history: [
            PointEntry(
              date: DateTime.parse('2024-01-01T12:00:00Z'),
              delta: 100,
              title: 'Test Entry',
              note: 'Test note',
            ),
          ],
        );

        final json = originalState.toJson();
        final deserializedState = PointsState.fromJson(json);

        expect(deserializedState.balance, equals(originalState.balance));
        expect(deserializedState.totalEarned, equals(originalState.totalEarned));
        expect(deserializedState.history.length, equals(originalState.history.length));
        expect(deserializedState.history.first.delta, equals(originalState.history.first.delta));
        expect(deserializedState.history.first.title, equals(originalState.history.first.title));
        expect(deserializedState.history.first.note, equals(originalState.history.first.note));
      });

      test('PointEntry should serialize and deserialize correctly', () {
        final originalEntry = PointEntry(
          date: DateTime.parse('2024-01-01T12:00:00Z'),
          delta: -500,
          title: 'Exchange Test',
          note: 'Exchange note',
        );

        final json = originalEntry.toJson();
        final deserializedEntry = PointEntry.fromJson(json);

        expect(deserializedEntry.date, equals(originalEntry.date));
        expect(deserializedEntry.delta, equals(originalEntry.delta));
        expect(deserializedEntry.title, equals(originalEntry.title));
        expect(deserializedEntry.note, equals(originalEntry.note));
      });
    });
  });
}
