import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/coupon.dart';

final couponsRepositoryProvider = Provider<CouponsRepository>((ref) {
  return CouponsRepository(
    firestore: FirebaseFirestore.instance,
    functions: FirebaseFunctions.instanceFor(region: 'asia-northeast1'),
  );
});

class CouponsRepository {
  final FirebaseFirestore firestore;
  final FirebaseFunctions functions;

  CouponsRepository({
    required this.firestore,
    required this.functions,
  });

  /// Get fuel voucher template
  Future<CouponTemplate?> getFuelVoucherTemplate() async {
    final templateId = 'fuel_voucher_500yen';
    final snapshot = await firestore
        .collection('couponTemplates')
        .doc(templateId)
        .get();

    if (!snapshot.exists) {
      return null;
    }

    return CouponTemplate.fromFirestore(templateId, snapshot.data()!);
  }

  /// Redeem points for fuel voucher
  /// Returns the new coupon data
  Future<Map<String, dynamic>> redeemPointsForFuelVoucher(
      String templateId) async {
    final callable = functions.httpsCallable('redeemPointsForFuelVoucher');
    final result = await callable.call({'templateId': templateId});

    return result.data as Map<String, dynamic>;
  }

  /// Redeem fuel voucher at store with staff PIN
  Future<Map<String, dynamic>> redeemAtStore({
    required String couponId,
    required String centerId,
    required String staffPin,
  }) async {
    final callable = functions.httpsCallable('redeemFuelVoucherAtStore');
    final result = await callable.call({
      'couponId': couponId,
      'centerId': centerId,
      'staffPin': staffPin,
    });

    return result.data as Map<String, dynamic>;
  }

  /// Get user's coupons stream
  Stream<List<Coupon>> myCoupons(
    String userId, {
    int limit = 20,
  }) {
    return firestore
        .collection('users')
        .doc(userId)
        .collection('coupons')
        .orderBy('issuedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Coupon.fromFirestore(doc.id, doc.data());
      }).toList();
    });
  }

  /// Ensure fuel voucher template exists (dev helper)
  Future<void> ensureFuelVoucherTemplate() async {
    final callable = functions.httpsCallable('ensureFuelVoucherTemplate');
    await callable.call();
  }
}
