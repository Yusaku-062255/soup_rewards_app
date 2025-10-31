import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final couponsRepositoryProvider = Provider<CouponsRepository>((ref) {
  return CouponsRepository(
    firestore: FirebaseFirestore.instance,
    functions: FirebaseFunctions.instanceFor(region: 'asia-northeast1'),
  );
});

/// Coupon model
class Coupon {
  final String id;
  final String title;
  final String description;
  final String? code;
  final String status; // 'active', 'redeemed', 'expired'
  final DateTime issuedAt;
  final DateTime expiresAt;
  final DateTime? redeemedAt;
  final bool singleUse;

  Coupon({
    required this.id,
    required this.title,
    required this.description,
    this.code,
    required this.status,
    required this.issuedAt,
    required this.expiresAt,
    this.redeemedAt,
    required this.singleUse,
  });

  bool get isActive => status == 'active' && expiresAt.isAfter(DateTime.now());
  bool get isExpired => status == 'expired' || expiresAt.isBefore(DateTime.now());
  bool get isRedeemed => status == 'redeemed';

  factory Coupon.fromFirestore(String id, Map<String, dynamic> data) {
    return Coupon(
      id: id,
      title: data['title'] as String,
      description: data['description'] as String,
      code: data['code'] as String?,
      status: data['status'] as String,
      issuedAt: (data['issuedAt'] as Timestamp).toDate(),
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
      redeemedAt: data['redeemedAt'] != null
          ? (data['redeemedAt'] as Timestamp).toDate()
          : null,
      singleUse: data['singleUse'] as bool? ?? true,
    );
  }
}

enum CouponFilter { all, active, redeemed, expired }

class CouponsRepository {
  final FirebaseFirestore firestore;
  final FirebaseFunctions functions;

  CouponsRepository({
    required this.firestore,
    required this.functions,
  });

  /// Get user's coupons stream
  Stream<List<Coupon>> myCoupons(String userId, {CouponFilter filter = CouponFilter.all}) {
    Query<Map<String, dynamic>> query = firestore
        .collection('users')
        .doc(userId)
        .collection('coupons')
        .orderBy('issuedAt', descending: true);

    // Note: Status filtering is done in-memory because Firestore status
    // doesn't account for expired vs active based on expiresAt timestamp
    return query.snapshots().map((snapshot) {
      final coupons = snapshot.docs.map((doc) {
        return Coupon.fromFirestore(doc.id, doc.data());
      }).toList();

      // Apply filter
      switch (filter) {
        case CouponFilter.active:
          return coupons.where((c) => c.isActive).toList();
        case CouponFilter.redeemed:
          return coupons.where((c) => c.isRedeemed).toList();
        case CouponFilter.expired:
          return coupons.where((c) => c.isExpired && !c.isRedeemed).toList();
        case CouponFilter.all:
          return coupons;
      }
    });
  }

  /// Redeem a coupon
  Future<void> redeem(String couponId) async {
    final callable = functions.httpsCallable('redeemCoupon');
    final result = await callable.call({'couponId': couponId});

    final data = result.data as Map<String, dynamic>;
    if (data['ok'] != true) {
      throw Exception(data['error'] ?? 'Redeem failed');
    }
  }
}
