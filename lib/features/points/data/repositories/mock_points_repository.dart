import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/daily_draw_result.dart';
import '../../domain/repositories/points_repository.dart';
import '../../domain/utils/points_initializer.dart';

/// モック実装（SharedPreferencesを使用）
/// TODO: 本番環境では Firestore 実装に置き換える
///
/// 注意: 現在は userId と shopId を内部で無視してローカルのみで動作します。
/// 将来 FirestorePointsRepository に差し替える際は、これらのパラメータを
/// 使用してユーザーごと・店舗ごとのデータを管理します。
class MockPointsRepository implements PointsRepository {
  static const String _pointsKey = 'points_current';
  static const String _lastDrawDateKey = 'points_last_draw_date';
  static const String _todayDrawResultKey = 'points_today_draw_result';

  final SharedPreferences _prefs;

  MockPointsRepository(this._prefs);

  @override
  Future<int> getCurrentPoints({
    required String userId,
    required String shopId,
  }) async {
    // TODO: 将来的には userId と shopId を使って Firestore から取得
    // 現在はローカルのみ
    final points = _prefs.getInt(_pointsKey);
    return points ?? PointsInitializer.getInitialPoints();
  }

  @override
  Future<DailyDrawState> getDailyDrawState({
    required String userId,
    required String shopId,
  }) async {
    // TODO: 将来的には userId と shopId を使って Firestore から取得
    // 現在はローカルのみ
    final lastDrawDate = await _getLastDrawDate();

    if (lastDrawDate == null) {
      // 初回起動時は初期状態を返す
      return PointsInitializer.createInitialState();
    }

    final hasDrawnToday = await _hasDrawnToday(lastDrawDate);
    final todayResult = hasDrawnToday ? await _getTodayDrawResult() : null;

    return DailyDrawState(
      hasDrawnToday: hasDrawnToday,
      lastDrawDate: lastDrawDate,
      todayResult: todayResult,
    );
  }

  @override
  Future<DailyDrawResult> drawToday({
    required String userId,
    required String shopId,
  }) async {
    // TODO: 将来的には userId と shopId を使って Firestore に保存
    // 現在はローカルのみ

    // 既に今日引いているかチェック
    final state = await getDailyDrawState(userId: userId, shopId: shopId);
    if (state.hasDrawnToday) {
      throw Exception('今日は既にくじを引いています');
    }

    // ランダムなポイントを取得
    // DailyDrawPointsはdaily_draw_result.dartに定義されている
    final points = DailyDrawPoints.getRandomPoints();
    final result = DailyDrawResult(
      points: points,
      drawnAt: DateTime.now(),
    );

    // 保存
    await _saveTodayDraw(result);

    // ポイントを追加
    await addPoints(userId: userId, shopId: shopId, points: points);

    return result;
  }

  @override
  Future<void> addPoints({
    required String userId,
    required String shopId,
    required int points,
  }) async {
    // TODO: 将来的には userId と shopId を使って Firestore に保存
    // 現在はローカルのみ
    final currentPoints =
        await getCurrentPoints(userId: userId, shopId: shopId);
    await _updatePoints(currentPoints + points);
  }

  // プライベートメソッド

  Future<bool> _hasDrawnToday(DateTime? lastDrawDate) async {
    if (lastDrawDate == null) return false;

    final now = DateTime.now();
    return lastDrawDate.year == now.year &&
        lastDrawDate.month == now.month &&
        lastDrawDate.day == now.day;
  }

  Future<DateTime?> _getLastDrawDate() async {
    final timestamp = _prefs.getInt(_lastDrawDateKey);
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  Future<void> _saveTodayDraw(DailyDrawResult result) async {
    final now = DateTime.now();
    await _prefs.setInt(_lastDrawDateKey, now.millisecondsSinceEpoch);

    final resultJson = jsonEncode({
      'points': result.points,
      'drawnAt': result.drawnAt.millisecondsSinceEpoch,
    });
    await _prefs.setString(_todayDrawResultKey, resultJson);
  }

  Future<DailyDrawResult?> _getTodayDrawResult() async {
    final resultJson = _prefs.getString(_todayDrawResultKey);
    if (resultJson == null) return null;

    final map = jsonDecode(resultJson) as Map<String, dynamic>;
    final lastDrawDate = await _getLastDrawDate();

    // 今日の結果かどうか確認
    if (lastDrawDate == null) return null;
    final now = DateTime.now();
    final isToday = lastDrawDate.year == now.year &&
        lastDrawDate.month == now.month &&
        lastDrawDate.day == now.day;

    if (!isToday) return null;

    return DailyDrawResult(
      points: map['points'] as int,
      drawnAt: DateTime.fromMillisecondsSinceEpoch(map['drawnAt'] as int),
    );
  }

  Future<void> _updatePoints(int newPoints) async {
    await _prefs.setInt(_pointsKey, newPoints);
  }
}
