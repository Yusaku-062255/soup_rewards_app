import 'package:cloud_firestore/cloud_firestore.dart';

/// Slot model - represents an available time slot
class Slot {
  final String id;
  final String time; // "09:00"
  final String serviceType; // "wash" | "coating"
  final int capacity;
  final int reservedCount;
  final int available;
  final int version;

  Slot({
    required this.id,
    required this.time,
    required this.serviceType,
    required this.capacity,
    required this.reservedCount,
    required this.available,
    required this.version,
  });

  factory Slot.fromJson(Map<String, dynamic> json) {
    return Slot(
      id: json['id'] as String,
      time: json['time'] as String,
      serviceType: json['serviceType'] as String,
      capacity: json['capacity'] as int? ?? 0,
      reservedCount: json['reservedCount'] as int? ?? 0,
      available: json['available'] as int? ?? 0,
      version: json['version'] as int? ?? 1,
    );
  }

  bool get isAvailable => available > 0;

  String get serviceTypeLabel {
    switch (serviceType) {
      case 'wash':
        return '洗車';
      case 'coating':
        return 'コーティング';
      default:
        return serviceType;
    }
  }
}

/// Booking model - represents a user's booking
class Booking {
  final String id;
  final String userId;
  final String centerId;
  final String slotId;
  final String date; // "20250115"
  final String time; // "09:00"
  final String serviceType;
  final String status; // "confirmed" | "cancelled"
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? cancelledAt;

  Booking({
    required this.id,
    required this.userId,
    required this.centerId,
    required this.slotId,
    required this.date,
    required this.time,
    required this.serviceType,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.cancelledAt,
  });

  factory Booking.fromFirestore(String id, Map<String, dynamic> data) {
    return Booking(
      id: id,
      userId: data['userId'] as String,
      centerId: data['centerId'] as String,
      slotId: data['slotId'] as String,
      date: data['date'] as String,
      time: data['time'] as String,
      serviceType: data['serviceType'] as String,
      status: data['status'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      cancelledAt: data['cancelledAt'] != null
          ? (data['cancelledAt'] as Timestamp).toDate()
          : null,
    );
  }

  bool get isConfirmed => status == 'confirmed';
  bool get isCancelled => status == 'cancelled';

  String get serviceTypeLabel {
    switch (serviceType) {
      case 'wash':
        return '洗車';
      case 'coating':
        return 'コーティング';
      default:
        return serviceType;
    }
  }

  /// Format date as YYYY/MM/DD
  String get formattedDate {
    if (date.length != 8) return date;
    final year = date.substring(0, 4);
    final month = date.substring(4, 6);
    final day = date.substring(6, 8);
    return '$year/$month/$day';
  }

  /// Format date and time as YYYY/MM/DD HH:mm
  String get formattedDateTime {
    return '$formattedDate $time';
  }
}
