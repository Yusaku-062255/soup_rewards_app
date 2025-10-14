// クーポンモデル
import 'dart:convert';

class CouponModel {
  final String id;
  final String title;
  final String description;
  final int cost;              // 必要ポイント
  final bool isRedeemed;       // 交換済みかどうか
  final DateTime issuedAt;     // 発行日時
  final DateTime? redeemedAt;  // 交換日時

  const CouponModel({
    required this.id,
    required this.title,
    required this.description,
    required this.cost,
    this.isRedeemed = false,
    required this.issuedAt,
    this.redeemedAt,
  });

  // JSON変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'cost': cost,
      'isRedeemed': isRedeemed,
      'issuedAt': issuedAt.toIso8601String(),
      'redeemedAt': redeemedAt?.toIso8601String(),
    };
  }

  factory CouponModel.fromJson(Map<String, dynamic> json) {
    return CouponModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      cost: json['cost'],
      isRedeemed: json['isRedeemed'] ?? false,
      issuedAt: DateTime.parse(json['issuedAt']),
      redeemedAt: json['redeemedAt'] != null 
          ? DateTime.parse(json['redeemedAt']) 
          : null,
    );
  }

  // JSON文字列変換
  String toJsonString() => jsonEncode(toJson());

  factory CouponModel.fromJsonString(String jsonString) {
    return CouponModel.fromJson(jsonDecode(jsonString));
  }

  // コピー作成
  CouponModel copyWith({
    String? id,
    String? title,
    String? description,
    int? cost,
    bool? isRedeemed,
    DateTime? issuedAt,
    DateTime? redeemedAt,
  }) {
    return CouponModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      cost: cost ?? this.cost,
      isRedeemed: isRedeemed ?? this.isRedeemed,
      issuedAt: issuedAt ?? this.issuedAt,
      redeemedAt: redeemedAt ?? this.redeemedAt,
    );
  }

  // 交換済みにする
  CouponModel redeem() {
    return copyWith(
      isRedeemed: true,
      redeemedAt: DateTime.now(),
    );
  }

  // 表示用の状態
  String get statusText {
    return isRedeemed ? '使用済み' : '使用可能';
  }

  // 表示用の日付
  String get displayIssuedDate {
    return '${issuedAt.year}/${issuedAt.month.toString().padLeft(2, '0')}/${issuedAt.day.toString().padLeft(2, '0')}';
  }

  String get displayRedeemedDate {
    if (redeemedAt == null) return '';
    return '${redeemedAt!.year}/${redeemedAt!.month.toString().padLeft(2, '0')}/${redeemedAt!.day.toString().padLeft(2, '0')}';
  }

  // 有効期限チェック（将来拡張用）
  bool get isExpired {
    // 現在は無期限だが、将来的に有効期限を追加可能
    return false;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CouponModel &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.cost == cost &&
        other.isRedeemed == isRedeemed &&
        other.issuedAt == issuedAt &&
        other.redeemedAt == redeemedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      description,
      cost,
      isRedeemed,
      issuedAt,
      redeemedAt,
    );
  }

  @override
  String toString() {
    return 'CouponModel(id: $id, title: $title, cost: ${cost}pt, isRedeemed: $isRedeemed)';
  }

  // デフォルトクーポンファクトリー
  static CouponModel createFuelCoupon() {
    return CouponModel(
      id: 'fuel_coupon_5000',
      title: '給油券',
      description: '¥5000相当の給油券（店頭渡し）',
      cost: 5000,
      issuedAt: DateTime.now(),
    );
  }
}
