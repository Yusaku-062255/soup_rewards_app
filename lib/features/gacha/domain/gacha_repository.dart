import 'gacha_result.dart';

/// ガチャリポジトリインターフェース
abstract class GachaRepository {
  /// 毎日ガチャを実行
  Future<GachaResult> claimDailyGacha();

  /// 最終実行日時を取得
  Future<DateTime?> getLastClaimAt();

  /// 次回実行可能日時を取得
  Future<DateTime> getNextClaimAt();

  /// 本日実行済みか確認
  Future<bool> isClaimedToday();

  /// 連続ログイン日数を取得
  Future<int> getStreak();
}
