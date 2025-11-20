import 'package:cloud_firestore/cloud_firestore.dart';

/// クーポンモデル
class CouponModel {
  final String id;
  final String title;
  final String description;
  final int pointsCost;
  final DateTime? validUntil;
  final String? imageUrl;
  final bool isActive;

  CouponModel({
    required this.id,
    required this.title,
    required this.description,
    required this.pointsCost,
    this.validUntil,
    this.imageUrl,
    this.isActive = true,
  });

  /// Firestoreから作成
  factory CouponModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CouponModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      pointsCost: data['pointsCost'] ?? 0,
      validUntil: (data['validUntil'] as Timestamp?)?.toDate(),
      imageUrl: data['imageUrl'],
      isActive: data['isActive'] ?? true,
    );
  }

  /// Firestore用に変換
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'pointsCost': pointsCost,
      if (validUntil != null) 'validUntil': Timestamp.fromDate(validUntil!),
      if (imageUrl != null) 'imageUrl': imageUrl,
      'isActive': isActive,
    };
  }

  /// 有効期限が切れているか
  bool get isExpired {
    if (validUntil == null) return false;
    return DateTime.now().isAfter(validUntil!);
  }

  /// 利用可能か
  bool get isAvailable => isActive && !isExpired;
}
