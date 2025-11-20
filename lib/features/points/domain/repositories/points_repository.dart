import '../models/daily_draw_result.dart';

/// 日次くじの状態
class DailyDrawState {
  final bool hasDrawnToday;
  final DateTime? lastDrawDate;
  final DailyDrawResult? todayResult;

  DailyDrawState({
    required this.hasDrawnToday,
    this.lastDrawDate,
    this.todayResult,
  });
}

/// ポイントリポジトリのインターフェース
/// TODO: FirestorePointsRepository 実装に差し替える予定
///
/// 将来の本番運用では以下の要件を想定：
/// - Firestore + 匿名認証
/// - マルチ店舗対応（shopId）
/// - ユーザーごとのポイント管理（userId）
abstract class PointsRepository {
  /// 現在のポイントを取得
  ///
  /// [userId] ユーザーID（匿名認証のUIDなど）
  /// [shopId] 店舗ID（将来的にマルチ店舗対応）
  Future<int> getCurrentPoints({
    required String userId,
    required String shopId,
  });

  /// 日次くじの状態を取得
  ///
  /// [userId] ユーザーID
  /// [shopId] 店舗ID
  Future<DailyDrawState> getDailyDrawState({
    required String userId,
    required String shopId,
  });

  /// 今日のくじを引く
  ///
  /// [userId] ユーザーID
  /// [shopId] 店舗ID
  ///
  /// 戻り値: くじ結果（ポイントが自動的に追加される）
  Future<DailyDrawResult> drawToday({
    required String userId,
    required String shopId,
  });

  /// ポイントを追加（将来的に他の獲得方法に対応）
  ///
  /// [userId] ユーザーID
  /// [shopId] 店舗ID
  /// [points] 追加するポイント数
  Future<void> addPoints({
    required String userId,
    required String shopId,
    required int points,
  });
}
