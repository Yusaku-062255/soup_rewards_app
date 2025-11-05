import 'package:flutter_test/flutter_test.dart';
import 'package:soup_rewards_app/features/points/points_repository.dart';

void main() {
  group('PointsRepository', () {
    test('PointEntry should include balance field', () {
      final entry = PointEntry(
        id: 'test123',
        type: 'gacha',
        delta: 10,
        balance: 110,
        note: 'デイリーガチャ',
        createdAt: DateTime.now(),
      );

      expect(entry.id, 'test123');
      expect(entry.type, 'gacha');
      expect(entry.delta, 10);
      expect(entry.balance, 110);
      expect(entry.note, 'デイリーガチャ');
    });

    test('GachaResult should parse from JSON correctly', () {
      final json = {
        'ok': true,
        'reward': {'type': 'points', 'amount': 10},
        'resetInSeconds': 82800,
        'dayId': '20250105',
      };

      final result = GachaResult.fromJson(json);

      expect(result.ok, true);
      expect(result.reward, isNotNull);
      expect(result.reward?['amount'], 10);
      expect(result.resetInSeconds, 82800);
      expect(result.dayId, '20250105');
    });

    test('GachaResult should handle already-claimed scenario', () {
      final json = {
        'ok': false,
        'reason': 'already_claimed',
        'resetInSeconds': 43200,
        'dayId': '20250105',
      };

      final result = GachaResult.fromJson(json);

      expect(result.ok, false);
      expect(result.reason, 'already_claimed');
      expect(result.resetInSeconds, 43200);
    });
  });
}
