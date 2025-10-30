import 'package:cloud_firestore/cloud_firestore.dart';

/// 車両情報モデル
class Vehicle {
  final String id;
  final String name;
  final String? licensePlate;
  final String? make;
  final String? model;
  final int? year;
  final DateTime coatedAt;
  final int intervalMonths;
  final DateTime nextMaintenanceAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Vehicle({
    required this.id,
    required this.name,
    this.licensePlate,
    this.make,
    this.model,
    this.year,
    required this.coatedAt,
    required this.intervalMonths,
    required this.nextMaintenanceAt,
    required this.createdAt,
    this.updatedAt,
  });

  factory Vehicle.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Vehicle.fromJson(data, doc.id);
  }

  factory Vehicle.fromJson(Map<String, dynamic> json, String id) {
    return Vehicle(
      id: id,
      name: json['name'] as String,
      licensePlate: json['licensePlate'] as String?,
      make: json['make'] as String?,
      model: json['model'] as String?,
      year: json['year'] as int?,
      coatedAt: (json['coatedAt'] as Timestamp).toDate(),
      intervalMonths: json['intervalMonths'] as int? ?? 12,
      nextMaintenanceAt: (json['nextMaintenanceAt'] as Timestamp).toDate(),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (licensePlate != null) 'licensePlate': licensePlate,
      if (make != null) 'make': make,
      if (model != null) 'model': model,
      if (year != null) 'year': year,
      'coatedAt': Timestamp.fromDate(coatedAt),
      'intervalMonths': intervalMonths,
      'nextMaintenanceAt': Timestamp.fromDate(nextMaintenanceAt),
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  /// 次回メンテナンスまでの日数
  int get daysUntilMaintenance {
    final now = DateTime.now();
    return nextMaintenanceAt.difference(now).inDays;
  }

  /// メンテナンス期限が近いか（30日以内）
  bool get isMaintenanceSoon {
    return daysUntilMaintenance <= 30 && daysUntilMaintenance >= 0;
  }

  /// メンテナンス期限切れか
  bool get isMaintenanceOverdue {
    return daysUntilMaintenance < 0;
  }

  /// メンテナンス状態
  MaintenanceStatus get maintenanceStatus {
    if (isMaintenanceOverdue) return MaintenanceStatus.overdue;
    if (isMaintenanceSoon) return MaintenanceStatus.soon;
    return MaintenanceStatus.ok;
  }

  Vehicle copyWith({
    String? name,
    String? licensePlate,
    String? make,
    String? model,
    int? year,
    DateTime? coatedAt,
    int? intervalMonths,
    DateTime? nextMaintenanceAt,
    DateTime? updatedAt,
  }) {
    return Vehicle(
      id: id,
      name: name ?? this.name,
      licensePlate: licensePlate ?? this.licensePlate,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      coatedAt: coatedAt ?? this.coatedAt,
      intervalMonths: intervalMonths ?? this.intervalMonths,
      nextMaintenanceAt: nextMaintenanceAt ?? this.nextMaintenanceAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'Vehicle(id: $id, name: $name, nextMaintenanceAt: $nextMaintenanceAt)';
  }
}

/// メンテナンス状態
enum MaintenanceStatus {
  ok('正常', '次回メンテナンスまで十分な期間があります'),
  soon('要注意', 'メンテナンス期限が近づいています'),
  overdue('期限切れ', 'メンテナンス期限を過ぎています');

  final String displayName;
  final String description;

  const MaintenanceStatus(this.displayName, this.description);
}
