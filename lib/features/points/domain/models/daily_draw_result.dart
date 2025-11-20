/// 日次くじの結果モデル
class DailyDrawResult {
  final int points;
  final DateTime drawnAt;

  DailyDrawResult({
    required this.points,
    required this.drawnAt,
  });
}

/// 日次くじの可能なポイント値
class DailyDrawPoints {
  static const List<int> possiblePoints = [5, 10, 20, 50, 100];

  /// ランダムなポイントを取得
  static int getRandomPoints() {
    final random =
        DateTime.now().millisecondsSinceEpoch % possiblePoints.length;
    return possiblePoints[random];
  }
}
