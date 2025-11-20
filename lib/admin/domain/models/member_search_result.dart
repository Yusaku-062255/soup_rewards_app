import '../../../core/models/user_model.dart';
import '../../../features/points/domain/models/rank.dart';

/// 会員検索結果モデル
class MemberSearchResult {
  final UserModel user;
  final Rank currentRank;
  final DateTime? lastVisitDate; // TODO: FirestoreのusersコレクションにlastVisitDateフィールドを追加

  MemberSearchResult({
    required this.user,
    required this.currentRank,
    this.lastVisitDate,
  });

  /// 会員ID（6桁表示用）
  String get displayId {
    // TODO: 実際の会員IDフォーマットに合わせて調整
    // 現時点ではuserIdの末尾6桁を表示
    if (user.id.length >= 6) {
      return user.id.substring(user.id.length - 6);
    }
    return user.id.padLeft(6, '0');
  }
}

