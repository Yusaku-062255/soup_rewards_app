import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/coupon_model.dart';

/// クーポンリポジトリ
class CouponRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// すべてのアクティブなクーポンを取得
  Future<List<CouponModel>> getActiveCoupons() async {
    try {
      final snapshot = await _firestore
          .collection('coupons')
          .where('isActive', isEqualTo: true)
          .orderBy('pointsCost')
          .get();

      return snapshot.docs
          .map((doc) => CouponModel.fromFirestore(doc))
          .where((coupon) => coupon.isAvailable)
          .toList();
    } catch (e) {
      throw Exception('クーポンの取得に失敗しました: $e');
    }
  }

  /// クーポンをIDで取得
  Future<CouponModel?> getCoupon(String couponId) async {
    try {
      final doc = await _firestore.collection('coupons').doc(couponId).get();
      if (!doc.exists) return null;
      return CouponModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('クーポンの取得に失敗しました: $e');
    }
  }

  /// アクティブなクーポンをリアルタイムで監視
  Stream<List<CouponModel>> watchActiveCoupons() {
    return _firestore
        .collection('coupons')
        .where('isActive', isEqualTo: true)
        .orderBy('pointsCost')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CouponModel.fromFirestore(doc))
            .where((coupon) => coupon.isAvailable)
            .toList());
  }
}
