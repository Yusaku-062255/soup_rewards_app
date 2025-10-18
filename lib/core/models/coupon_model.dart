import 'dart:convert';

class CouponModel {
  final String id;
  final String title;
  final String description;
  final String category; // 例: 'points_exchange', 'service_completion', 'campaign', 'birthday'
  final String discountType; // 例: 'fixed', 'percentage'
  final double discountValue; // 例: 500.0 (固定割引), 10.0 (10%割引)
  final DateTime expiryDate;
  final bool isUsed; // isRedeemedをisUsedに改名
  final int? cost; // ポイント交換に必要なコスト

  const CouponModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.discountType,
    required this.discountValue,
    required this.expiryDate,
    this.isUsed = false,
    this.cost,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'discountType': discountType,
      'discountValue': discountValue,
      'expiryDate': expiryDate.toIso8601String(),
      'isUsed': isUsed,
      'cost': cost,
    };
  }

  factory CouponModel.fromJson(Map<String, dynamic> json) {
    // 既存のキーとの互換性を保ちつつ、新しいフィールドに対応
    final String id = json['id'] ?? json['couponId'] ?? 'unknown_id';
    final String title = json['title'] ?? json['couponName'] ?? 'Unknown Coupon';
    final String description = json['description'] ?? json['details'] ?? 'No description available.';
    final String category = json['category'] ?? 'general';
    final String discountType = json['discountType'] ?? (json['value'] != null && json['value'] is int ? 'fixed' : 'percentage');
    final double discountValue = (json['discountValue'] ?? json['value'] ?? 0).toDouble();
    
    DateTime expiryDate;
    if (json['expiryDate'] != null) {
      expiryDate = DateTime.parse(json['expiryDate']);
    } else if (json['expiresAt'] != null) {
      expiryDate = DateTime.parse(json['expiresAt']);
    } else {
      // デフォルトで1年後の期限を設定
      expiryDate = DateTime.now().add(const Duration(days: 365));
    }

    final bool isUsed = json['isUsed'] ?? json['isRedeemed'] ?? false;
    final int? cost = json['cost'] ?? json['requiredPoints'];

    return CouponModel(
      id: id,
      title: title,
      description: description,
      category: category,
      discountType: discountType,
      discountValue: discountValue,
      expiryDate: expiryDate,
      isUsed: isUsed,
      cost: cost,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory CouponModel.fromJsonString(String jsonString) {
    return CouponModel.fromJson(jsonDecode(jsonString));
  }

  CouponModel copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? discountType,
    double? discountValue,
    DateTime? expiryDate,
    bool? isUsed,
    int? cost,
  }) {
    return CouponModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      expiryDate: expiryDate ?? this.expiryDate,
      isUsed: isUsed ?? this.isUsed,
      cost: cost ?? this.cost,
    );
  }

  CouponModel use() {
    return copyWith(
      isUsed: true,
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiryDate);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CouponModel &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.category == category &&
        other.discountType == discountType &&
        other.discountValue == discountValue &&
        other.expiryDate == expiryDate &&
        other.isUsed == isUsed &&
        other.cost == cost;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      description,
      category,
      discountType,
      discountValue,
      expiryDate,
      isUsed,
      cost,
    );
  }

  @override
  String toString() {
    return 'CouponModel(id: $id, title: $title, category: $category, value: $discountValue, isUsed: $isUsed, expired: $isExpired)';
  }
}

