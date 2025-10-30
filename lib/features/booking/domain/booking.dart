import 'package:cloud_firestore/cloud_firestore.dart';

/// 予約情報モデル
class Booking {
  final String id;
  final String userId;
  final String? vehicleId;
  final BookingService service;
  final DateTime scheduledAt;
  final BookingStatus status;
  final String? notes;
  final String? vehicleName;
  final DateTime createdAt;
  final DateTime? cancelledAt;

  const Booking({
    required this.id,
    required this.userId,
    this.vehicleId,
    required this.service,
    required this.scheduledAt,
    required this.status,
    this.notes,
    this.vehicleName,
    required this.createdAt,
    this.cancelledAt,
  });

  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Booking.fromJson(data, doc.id);
  }

  factory Booking.fromJson(Map<String, dynamic> json, String id) {
    return Booking(
      id: id,
      userId: json['userId'] as String,
      vehicleId: json['vehicleId'] as String?,
      service: BookingService.values.firstWhere(
        (e) => e.name == json['service'],
        orElse: () => BookingService.coating,
      ),
      scheduledAt: (json['scheduledAt'] as Timestamp).toDate(),
      status: BookingStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => BookingStatus.pending,
      ),
      notes: json['notes'] as String?,
      vehicleName: json['vehicleName'] as String?,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      cancelledAt: json['cancelledAt'] != null
          ? (json['cancelledAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      if (vehicleId != null) 'vehicleId': vehicleId,
      'service': service.name,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'status': status.name,
      if (notes != null) 'notes': notes,
      if (vehicleName != null) 'vehicleName': vehicleName,
      'createdAt': Timestamp.fromDate(createdAt),
      if (cancelledAt != null) 'cancelledAt': Timestamp.fromDate(cancelledAt!),
    };
  }

  /// 予約が今日か
  bool get isToday {
    final now = DateTime.now();
    return scheduledAt.year == now.year &&
        scheduledAt.month == now.month &&
        scheduledAt.day == now.day;
  }

  /// 予約が過去か
  bool get isPast {
    return scheduledAt.isBefore(DateTime.now());
  }

  /// 予約が未来か
  bool get isFuture {
    return scheduledAt.isAfter(DateTime.now());
  }

  /// キャンセル可能か
  bool get canCancel {
    return status == BookingStatus.pending && isFuture;
  }

  Booking copyWith({
    String? vehicleId,
    BookingService? service,
    DateTime? scheduledAt,
    BookingStatus? status,
    String? notes,
    String? vehicleName,
    DateTime? cancelledAt,
  }) {
    return Booking(
      id: id,
      userId: userId,
      vehicleId: vehicleId ?? this.vehicleId,
      service: service ?? this.service,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      vehicleName: vehicleName ?? this.vehicleName,
      createdAt: createdAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
    );
  }

  @override
  String toString() {
    return 'Booking(id: $id, service: ${service.displayName}, scheduledAt: $scheduledAt, status: ${status.displayName})';
  }
}

/// 予約サービス種別
enum BookingService {
  coating('コーティング', Duration(hours: 3), 15000),
  wash('洗車', Duration(hours: 1), 3000),
  maintenance('メンテナンス', Duration(hours: 2), 8000),
  inspection('点検', Duration(hours: 1), 5000);

  final String displayName;
  final Duration duration;
  final int basePrice;

  const BookingService(this.displayName, this.duration, this.basePrice);
}

/// 予約ステータス
enum BookingStatus {
  pending('予約確定'),
  confirmed('確認済み'),
  completed('完了'),
  cancelled('キャンセル');

  final String displayName;

  const BookingStatus(this.displayName);
}

/// 予約可能時間スロット
class TimeSlot {
  final DateTime dateTime;
  final bool isAvailable;

  const TimeSlot({
    required this.dateTime,
    required this.isAvailable,
  });

  /// 時間表示（HH:mm形式）
  String get timeLabel {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  String toString() {
    return 'TimeSlot($timeLabel, available: $isAvailable)';
  }
}
