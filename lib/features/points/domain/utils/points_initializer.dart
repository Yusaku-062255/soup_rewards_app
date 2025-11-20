import '../repositories/points_repository.dart';

/// ポイント初期化ユーティリティ
/// FirestoreとMockの両方で統一された初期化処理を提供
class PointsInitializer {
  /// 初期のDailyDrawStateを生成
  /// 
  /// 初回起動時やドキュメントが存在しない場合に使用
  static DailyDrawState createInitialState() {
    return DailyDrawState(
      hasDrawnToday: false,
      lastDrawDate: null,
      todayResult: null,
    );
  }

  /// 初期のポイント値を取得
  /// 
  /// 初回起動時は常に0ポイントから開始
  static int getInitialPoints() {
    return 0;
  }

  /// 初期ドキュメントデータを作成
  /// 
  /// Firestore用の初期データ構造を返す
  static Map<String, dynamic> createInitialDocumentData({
    required String shopId,
  }) {
    return {
      'shopId': shopId,
      'points': getInitialPoints(),
      'lastDailyDrawAt': null,
      'todayDrawPoints': null,
    };
  }
}

