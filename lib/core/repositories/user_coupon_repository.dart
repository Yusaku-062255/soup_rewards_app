import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_coupon_model.dart';

/// ユーザークーポンリポジトリ
class UserCouponRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ユーザーが獲得したクーポンを作成
  Future<void> createUserCoupon(UserCouponModel userCoupon) async {
    try {
      await _firestore
          .collection('userCoupons')
          .doc(userCoupon.id)
          .set(userCoupon.toFirestore());
    } catch (e) {
      throw Exception('ユーザークーポンの作成に失敗しました: $e');
    }
  }

  /// ユーザーが獲得したクーポンを取得
  Future<List<UserCouponModel>> getUserCoupons(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('userCoupons')
          .where('userId', isEqualTo: userId)
          .orderBy('redeemedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => UserCouponModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('ユーザークーポンの取得に失敗しました: $e');
    }
  }

  /// ユーザーが獲得したクーポンをリアルタイムで監視
  Stream<List<UserCouponModel>> watchUserCoupons(String userId) {
    return _firestore
        .collection('userCoupons')
        .where('userId', isEqualTo: userId)
        .orderBy('redeemedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserCouponModel.fromFirestore(doc))
            .toList());
  }

  /// クーポンを使用済みにマーク
  Future<void> markAsUsed(String userCouponId) async {
    try {
      await _firestore.collection('userCoupons').doc(userCouponId).update({
        'usedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('クーポンの使用マークに失敗しました: $e');
    }
  }
}
