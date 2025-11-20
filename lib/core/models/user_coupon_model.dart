import 'package:cloud_firestore/cloud_firestore.dart';

/// ユーザーが獲得したクーポンモデル
class UserCouponModel {
  final String id;
  final String userId;
  final String couponId;
  final DateTime redeemedAt;
  final DateTime? usedAt;
  final String? qrCode;

  UserCouponModel({
    required this.id,
    required this.userId,
    required this.couponId,
    required this.redeemedAt,
    this.usedAt,
    this.qrCode,
  });

  /// Firestoreから作成
  factory UserCouponModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserCouponModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      couponId: data['couponId'] ?? '',
      redeemedAt:
          (data['redeemedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      usedAt: (data['usedAt'] as Timestamp?)?.toDate(),
      qrCode: data['qrCode'],
    );
  }

  /// Firestore用に変換
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'couponId': couponId,
      'redeemedAt': Timestamp.fromDate(redeemedAt),
      if (usedAt != null) 'usedAt': Timestamp.fromDate(usedAt!),
      if (qrCode != null) 'qrCode': qrCode,
    };
  }

  /// 使用済みか
  bool get isUsed => usedAt != null;
}
