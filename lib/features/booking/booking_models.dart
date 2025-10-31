import 'package:cloud_firestore/cloud_firestore.dart';

/// Time slot model
class TimeSlot {
  final String slotId;
  final DateTime startAt;
  final DateTime endAt;
  final int capacity;
  final int reservedCount;

  TimeSlot({
    required this.slotId,
    required this.startAt,
    required this.endAt,
    required this.capacity,
    required this.reservedCount,
  });

  int get availableCount => capacity - reservedCount;
  bool get isFull => reservedCount >= capacity;

  factory TimeSlot.fromFirestore(String slotId, Map<String, dynamic> data) {
    return TimeSlot(
      slotId: slotId,
      startAt: (data['startAt'] as Timestamp).toDate(),
      endAt: (data['endAt'] as Timestamp).toDate(),
      capacity: data['capacity'] as int? ?? 0,
      reservedCount: data['reservedCount'] as int? ?? 0,
    );
  }
}

/// Booking model
class Booking {
  final String id;
  final String userId;
  final String vehicleId;
  final String serviceType;
  final String date;
  final String slotId;
  final String centerId;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Booking({
    required this.id,
    required this.userId,
    required this.vehicleId,
    required this.serviceType,
    required this.date,
    required this.slotId,
    required this.centerId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Booking.fromFirestore(String id, Map<String, dynamic> data) {
    return Booking(
      id: id,
      userId: data['userId'] as String,
      vehicleId: data['vehicleId'] as String,
      serviceType: data['serviceType'] as String,
      date: data['date'] as String,
      slotId: data['slotId'] as String,
      centerId: data['centerId'] as String? ?? 'default',
      status: data['status'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }
}
