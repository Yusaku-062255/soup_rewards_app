import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/gacha_repository.dart';
import '../domain/gacha_result.dart';

/// ガチャリポジトリ実装（Firebase Functions連携）
class GachaRepositoryImpl implements GachaRepository {
  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  GachaRepositoryImpl({
    FirebaseFunctions? functions,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _functions = functions ?? FirebaseFunctions.instanceFor(region: 'asia-northeast1'),
        _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  @override
  Future<GachaResult> claimDailyGacha() async {
    try {
      // 認証チェック
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Cloud Functions呼び出し
      final callable = _functions.httpsCallable('claimDailyGacha');
      final result = await callable.call();

      // 結果をパース
      final data = result.data as Map<String, dynamic>;
      return GachaResult.fromJson(data);
    } on FirebaseFunctionsException catch (e) {
      // Functions固有エラー
      if (e.code == 'failed-precondition') {
        throw GachaAlreadyClaimedException('本日は既に実行済みです');
      }
      throw GachaException('ガチャの実行に失敗しました: ${e.message}');
    } catch (e) {
      throw GachaException('予期しないエラーが発生しました: $e');
    }
  }

  @override
  Future<DateTime?> getLastClaimAt() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return null;

      final data = doc.data();
      final timestamp = data?['lastClaimAt'] as Timestamp?;
      return timestamp?.toDate();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<DateTime> getNextClaimAt() async {
    final lastClaim = await getLastClaimAt();
    if (lastClaim == null) {
      return DateTime.now();
    }

    // JST 00:00にリセット
    final jstLastClaim = lastClaim.add(const Duration(hours: 9)); // UTC+9
    final nextClaim = DateTime(
      jstLastClaim.year,
      jstLastClaim.month,
      jstLastClaim.day + 1,
    ).subtract(const Duration(hours: 9)); // UTC戻し

    return nextClaim;
  }

  @override
  Future<bool> isClaimedToday() async {
    final lastClaim = await getLastClaimAt();
    if (lastClaim == null) return false;

    final now = DateTime.now();
    final jstNow = now.add(const Duration(hours: 9));
    final jstLastClaim = lastClaim.add(const Duration(hours: 9));

    return jstNow.year == jstLastClaim.year &&
        jstNow.month == jstLastClaim.month &&
        jstNow.day == jstLastClaim.day;
  }

  @override
  Future<int> getStreak() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return 0;

      final data = doc.data();
      return data?['streak'] as int? ?? 0;
    } catch (e) {
      return 0;
    }
  }
}

/// ガチャ関連の例外
class GachaException implements Exception {
  final String message;

  GachaException(this.message);

  @override
  String toString() => message;
}

/// 既に実行済みの例外
class GachaAlreadyClaimedException extends GachaException {
  GachaAlreadyClaimedException(super.message);
}
