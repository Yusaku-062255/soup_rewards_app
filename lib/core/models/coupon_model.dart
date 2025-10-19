import 'dart:convert';

class CouponModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String discountType;
  final double discountValue;
  final DateTime expiryDate;
  final bool isUsed;
  final int? cost;

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

  // 互換ゲッター
  bool get isRedeemed => isUsed; // 互換エイリアス
  DateTime? get expiresAtCompat => expiryDate;

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
    final String id = json['id'] ?? json['couponId'] ?? '';
    final String title = json['title'] ?? json['couponName'] ?? '';
    final String description = json['description'] ?? json['detail'] ?? '';
    final String category = json['category'] ?? json['type'] ?? 'other';
    final String discountType = json['discountType'] ?? (json['percent'] != null ? 'percent' : 'fixed');
    final double discountValue = (json['discountValue'] ?? json['value'] ?? json['percent'] ?? 0).toDouble();
    
    DateTime expiryDate;
    if (json['expiryDate'] != null) {
      expiryDate = DateTime.tryParse(json['expiryDate']) ?? DateTime.now().add(const Duration(days: 30));
    } else if (json['expiresAt'] != null) {
      expiryDate = DateTime.tryParse(json['expiresAt']) ?? DateTime.now().add(const Duration(days: 30));
    } else {
      expiryDate = DateTime.now().add(const Duration(days: 30));
    }

    final bool isUsed = json['isUsed'] ?? json['isRedeemed'] ?? false;
    final int? cost = (json['cost'] ?? json['requiredPoints']) is num ? (json['cost'] ?? json['requiredPoints']).toInt() : null;

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

  // 有効期限チェック
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

  // デフォルトクーポンファクトリー
  static CouponModel createFuelCoupon() => CouponModel(
    id: 'fuel_coupon_500',
    title: 'ガソリン500円引き',
    description: 'ポイント交換クーポン',
    category: 'fuel',
    discountType: 'fixed',
    discountValue: 500,
    expiryDate: DateTime.now().add(const Duration(days: 90)),
    isUsed: false,
    cost: 500,
  );
}

