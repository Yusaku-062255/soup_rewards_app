// ランクサービステスト（EV優遇・倍率計算）
import 'package:flutter_test/flutter_test.dart';
import '../../../lib/core/services/rank_service.dart';

void main() {
  group('RankService Tests', () {
    group('Rank Calculation', () {
      test('should calculate correct rank based on total earned points', () {
        expect(RankService.calculateRank(0), equals(MemberRank.bronze));
        expect(RankService.calculateRank(50), equals(MemberRank.bronze));
        expect(RankService.calculateRank(99), equals(MemberRank.bronze));
        
        expect(RankService.calculateRank(100), equals(MemberRank.silver));
        expect(RankService.calculateRank(200), equals(MemberRank.silver));
        expect(RankService.calculateRank(299), equals(MemberRank.silver));
        
        expect(RankService.calculateRank(300), equals(MemberRank.gold));
        expect(RankService.calculateRank(400), equals(MemberRank.gold));
        expect(RankService.calculateRank(599), equals(MemberRank.gold));
        
        expect(RankService.calculateRank(600), equals(MemberRank.platinum));
        expect(RankService.calculateRank(800), equals(MemberRank.platinum));
        expect(RankService.calculateRank(999), equals(MemberRank.platinum));
        
        expect(RankService.calculateRank(1000), equals(MemberRank.evElite));
        expect(RankService.calculateRank(2000), equals(MemberRank.evElite));
      });
    });

    group('Effective Multiplier', () {
      test('should calculate base multiplier without EV', () {
        expect(RankService.effectiveMultiplier(0, hasEv: false), equals(1.0)); // Bronze
        expect(RankService.effectiveMultiplier(100, hasEv: false), equals(1.1)); // Silver
        expect(RankService.effectiveMultiplier(300, hasEv: false), equals(1.2)); // Gold
        expect(RankService.effectiveMultiplier(600, hasEv: false), equals(1.3)); // Platinum
        expect(RankService.effectiveMultiplier(1000, hasEv: false), equals(1.5)); // EV Elite
      });

      test('should add EV bonus when hasEv is true', () {
        expect(RankService.effectiveMultiplier(0, hasEv: true), closeTo(1.1, 0.001)); // Bronze + EV
        expect(RankService.effectiveMultiplier(100, hasEv: true), closeTo(1.2, 0.001)); // Silver + EV
        expect(RankService.effectiveMultiplier(300, hasEv: true), closeTo(1.3, 0.001)); // Gold + EV
        expect(RankService.effectiveMultiplier(600, hasEv: true), closeTo(1.4, 0.001)); // Platinum + EV
        expect(RankService.effectiveMultiplier(1000, hasEv: true), closeTo(1.6, 0.001)); // EV Elite + EV
      });
    });

    group('Points to Next Rank', () {
      test('should calculate points needed for next rank', () {
        expect(RankService.pointsToNextRank(0), equals(100)); // Bronze → Silver
        expect(RankService.pointsToNextRank(50), equals(50)); // Bronze → Silver
        expect(RankService.pointsToNextRank(99), equals(1)); // Bronze → Silver
        
        expect(RankService.pointsToNextRank(100), equals(200)); // Silver → Gold
        expect(RankService.pointsToNextRank(200), equals(100)); // Silver → Gold
        expect(RankService.pointsToNextRank(299), equals(1)); // Silver → Gold
        
        expect(RankService.pointsToNextRank(300), equals(300)); // Gold → Platinum
        expect(RankService.pointsToNextRank(450), equals(150)); // Gold → Platinum
        
        expect(RankService.pointsToNextRank(600), equals(400)); // Platinum → EV Elite
        expect(RankService.pointsToNextRank(800), equals(200)); // Platinum → EV Elite
        
        expect(RankService.pointsToNextRank(1000), equals(0)); // EV Elite (最高ランク)
        expect(RankService.pointsToNextRank(2000), equals(0)); // EV Elite (最高ランク)
      });
    });

    group('Rank Progress', () {
      test('should calculate progress within current rank', () {
        // Bronze (0-99): 50/100 = 0.5
        expect(RankService.rankProgress(50), closeTo(0.5, 0.01));
        
        // Silver (100-299): 150 = 100 + 50, 50/200 = 0.25
        expect(RankService.rankProgress(150), closeTo(0.25, 0.01));
        
        // Gold (300-599): 450 = 300 + 150, 150/300 = 0.5
        expect(RankService.rankProgress(450), closeTo(0.5, 0.01));
        
        // Platinum (600-999): 800 = 600 + 200, 200/400 = 0.5
        expect(RankService.rankProgress(800), closeTo(0.5, 0.01));
        
        // EV Elite (最高ランク): 1.0
        expect(RankService.rankProgress(1000), equals(1.0));
        expect(RankService.rankProgress(2000), equals(1.0));
      });

      test('should handle edge cases for progress calculation', () {
        // ランクの開始点
        expect(RankService.rankProgress(0), equals(0.0)); // Bronze開始
        expect(RankService.rankProgress(100), equals(0.0)); // Silver開始
        expect(RankService.rankProgress(300), equals(0.0)); // Gold開始
        expect(RankService.rankProgress(600), equals(0.0)); // Platinum開始
        
        // ランクの終了点
        expect(RankService.rankProgress(99), closeTo(0.99, 0.01)); // Bronze終了直前
        expect(RankService.rankProgress(299), closeTo(0.995, 0.01)); // Silver終了直前
      });
    });

    group('Next Rank Name', () {
      test('should return correct next rank name', () {
        expect(RankService.nextRankName(0), equals('Silver'));
        expect(RankService.nextRankName(100), equals('Gold'));
        expect(RankService.nextRankName(300), equals('Platinum'));
        expect(RankService.nextRankName(600), equals('EV Elite'));
        expect(RankService.nextRankName(1000), isNull); // 最高ランク
      });
    });

    group('Rank Up Detection', () {
      test('should detect rank up correctly', () {
        // Bronze → Silver
        expect(RankService.isRankUp(99, 100), isTrue);
        expect(RankService.isRankUp(50, 99), isFalse);
        
        // Silver → Gold
        expect(RankService.isRankUp(299, 300), isTrue);
        expect(RankService.isRankUp(200, 299), isFalse);
        
        // Gold → Platinum
        expect(RankService.isRankUp(599, 600), isTrue);
        
        // Platinum → EV Elite
        expect(RankService.isRankUp(999, 1000), isTrue);
        
        // 同じランク内
        expect(RankService.isRankUp(1000, 1500), isFalse);
      });
    });

    group('Rank Colors', () {
      test('should return correct color codes for each rank', () {
        final bronzeColors = RankService.getRankColors(MemberRank.bronze);
        expect(bronzeColors.length, equals(2));
        expect(bronzeColors[0], equals(0xFF8D6E63));
        expect(bronzeColors[1], equals(0xFFBCAAA4));
        
        final silverColors = RankService.getRankColors(MemberRank.silver);
        expect(silverColors.length, equals(2));
        expect(silverColors[0], equals(0xFF90A4AE));
        
        final evEliteColors = RankService.getRankColors(MemberRank.evElite);
        expect(evEliteColors.length, equals(2));
        expect(evEliteColors[0], equals(0xFFFF6F00));
        expect(evEliteColors[1], equals(0xFFFFD54F));
      });
    });

    group('Debug Info', () {
      test('should provide comprehensive debug information', () {
        final debugInfo = RankService.getDebugInfo(450, hasEv: true);
        
        expect(debugInfo['totalEarned'], equals(450));
        expect(debugInfo['currentRank'], equals('Gold'));
        expect(debugInfo['rankIndex'], equals(MemberRank.gold.index));
        expect(debugInfo['baseMultiplier'], equals(1.2));
        expect(debugInfo['hasEv'], isTrue);
        expect(debugInfo['effectiveMultiplier'], equals(1.3)); // 1.2 + 0.1
        expect(debugInfo['pointsToNext'], equals(150)); // 600 - 450
        expect(debugInfo['progress'], closeTo(0.5, 0.01)); // 150/300
        expect(debugInfo['nextRank'], equals('Platinum'));
      });

      test('should handle max rank debug info', () {
        final debugInfo = RankService.getDebugInfo(1500, hasEv: false);
        
        expect(debugInfo['currentRank'], equals('EV Elite'));
        expect(debugInfo['pointsToNext'], equals(0));
        expect(debugInfo['progress'], equals(1.0));
        expect(debugInfo['nextRank'], isNull);
      });
    });
  });
}
