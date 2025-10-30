import 'package:cloud_firestore/cloud_firestore.dart';

/// 施工・サービス履歴モデル
class ServiceHistory {
  final String id;
  final String vehicleId;
  final ServiceType serviceType;
  final String courseName;
  final DateTime servicedAt;
  final int amount;
  final String? technician;
  final String? notes;
  final List<String> photos;
  final DateTime? warrantyExpiresAt;
  final DateTime createdAt;

  const ServiceHistory({
    required this.id,
    required this.vehicleId,
    required this.serviceType,
    required this.courseName,
    required this.servicedAt,
    required this.amount,
    this.technician,
    this.notes,
    this.photos = const [],
    this.warrantyExpiresAt,
    required this.createdAt,
  });

  factory ServiceHistory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ServiceHistory.fromJson(data, doc.id);
  }

  factory ServiceHistory.fromJson(Map<String, dynamic> json, String id) {
    return ServiceHistory(
      id: id,
      vehicleId: json['vehicleId'] as String,
      serviceType: ServiceType.values.firstWhere(
        (e) => e.name == json['serviceType'],
        orElse: () => ServiceType.other,
      ),
      courseName: json['courseName'] as String,
      servicedAt: (json['servicedAt'] as Timestamp).toDate(),
      amount: json['amount'] as int,
      technician: json['technician'] as String?,
      notes: json['notes'] as String?,
      photos: (json['photos'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      warrantyExpiresAt: json['warrantyExpiresAt'] != null
          ? (json['warrantyExpiresAt'] as Timestamp).toDate()
          : null,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicleId': vehicleId,
      'serviceType': serviceType.name,
      'courseName': courseName,
      'servicedAt': Timestamp.fromDate(servicedAt),
      'amount': amount,
      if (technician != null) 'technician': technician,
      if (notes != null) 'notes': notes,
      'photos': photos,
      if (warrantyExpiresAt != null)
        'warrantyExpiresAt': Timestamp.fromDate(warrantyExpiresAt!),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// 保証が有効か
  bool get isWarrantyActive {
    if (warrantyExpiresAt == null) return false;
    return DateTime.now().isBefore(warrantyExpiresAt!);
  }

  /// 保証期限までの日数
  int? get daysUntilWarrantyExpires {
    if (warrantyExpiresAt == null) return null;
    return warrantyExpiresAt!.difference(DateTime.now()).inDays;
  }

  @override
  String toString() {
    return 'ServiceHistory(id: $id, courseName: $courseName, servicedAt: $servicedAt)';
  }
}

/// サービス種別
enum ServiceType {
  coating('コーティング', '🛡️'),
  wash('洗車', '🚿'),
  maintenance('メンテナンス', '🔧'),
  repair('修理', '🛠️'),
  inspection('点検', '📋'),
  other('その他', '📦');

  final String displayName;
  final String emoji;

  const ServiceType(this.displayName, this.emoji);
}

/// ワランティ情報（施工保証）
class WarrantyInfo {
  final String id;
  final String vehicleId;
  final String serviceName;
  final DateTime startDate;
  final DateTime expiresAt;
  final String? coverageDetails;
  final bool isActive;

  const WarrantyInfo({
    required this.id,
    required this.vehicleId,
    required this.serviceName,
    required this.startDate,
    required this.expiresAt,
    this.coverageDetails,
    required this.isActive,
  });

  factory WarrantyInfo.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WarrantyInfo.fromJson(data, doc.id);
  }

  factory WarrantyInfo.fromJson(Map<String, dynamic> json, String id) {
    return WarrantyInfo(
      id: id,
      vehicleId: json['vehicleId'] as String,
      serviceName: json['serviceName'] as String,
      startDate: (json['startDate'] as Timestamp).toDate(),
      expiresAt: (json['expiresAt'] as Timestamp).toDate(),
      coverageDetails: json['coverageDetails'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicleId': vehicleId,
      'serviceName': serviceName,
      'startDate': Timestamp.fromDate(startDate),
      'expiresAt': Timestamp.fromDate(expiresAt),
      if (coverageDetails != null) 'coverageDetails': coverageDetails,
      'isActive': isActive,
    };
  }

  /// 保証期限までの日数
  int get daysRemaining {
    return expiresAt.difference(DateTime.now()).inDays;
  }

  /// 保証が期限切れか
  bool get isExpired {
    return daysRemaining < 0;
  }

  /// 保証期限が近いか（30日以内）
  bool get isExpiringSoon {
    return daysRemaining <= 30 && daysRemaining >= 0;
  }

  @override
  String toString() {
    return 'WarrantyInfo(id: $id, serviceName: $serviceName, expiresAt: $expiresAt)';
  }
}
