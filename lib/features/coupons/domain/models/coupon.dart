import 'package:cloud_firestore/cloud_firestore.dart';

/// Coupon model
class Coupon {
  final String id;
  final String templateId;
  final String code;
  final String status; // 'active', 'redeemed', 'expired'
  final DateTime issuedAt;
  final DateTime expiresAt;
  final DateTime? redeemedAt;
  final Map<String, dynamic>? redeemedBy; // { centerId, staffId }
  final CouponMeta meta;

  Coupon({
    required this.id,
    required this.templateId,
    required this.code,
    required this.status,
    required this.issuedAt,
    required this.expiresAt,
    this.redeemedAt,
    this.redeemedBy,
    required this.meta,
  });

  factory Coupon.fromFirestore(String id, Map<String, dynamic> data) {
    return Coupon(
      id: id,
      templateId: data['templateId'] as String,
      code: data['code'] as String,
      status: data['status'] as String,
      issuedAt: (data['issuedAt'] as Timestamp).toDate(),
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
      redeemedAt: data['redeemedAt'] != null
          ? (data['redeemedAt'] as Timestamp).toDate()
          : null,
      redeemedBy: data['redeemedBy'] as Map<String, dynamic>?,
      meta: CouponMeta.fromMap(data['meta'] as Map<String, dynamic>),
    );
  }

  bool get isActive => status == 'active';
  bool get isRedeemed => status == 'redeemed';
  bool get isExpired => status == 'expired' || DateTime.now().isAfter(expiresAt);
}

/// Coupon metadata
class CouponMeta {
  final int discountValueYen;
  final String type; // 'flat_yen'
  final String title;

  CouponMeta({
    required this.discountValueYen,
    required this.type,
    required this.title,
  });

  factory CouponMeta.fromMap(Map<String, dynamic> data) {
    return CouponMeta(
      discountValueYen: data['discountValueYen'] as int,
      type: data['type'] as String,
      title: data['title'] as String,
    );
  }
}

/// Coupon template model
class CouponTemplate {
  final String id;
  final String title;
  final String type;
  final int discountValueYen;
  final int pointsCost;
  final int validityDays;
  final bool active;

  CouponTemplate({
    required this.id,
    required this.title,
    required this.type,
    required this.discountValueYen,
    required this.pointsCost,
    required this.validityDays,
    required this.active,
  });

  factory CouponTemplate.fromFirestore(String id, Map<String, dynamic> data) {
    return CouponTemplate(
      id: id,
      title: data['title'] as String,
      type: data['type'] as String,
      discountValueYen: data['discountValueYen'] as int,
      pointsCost: data['pointsCost'] as int,
      validityDays: data['validityDays'] as int,
      active: data['active'] as bool? ?? true,
    );
  }
}
