import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'booking_models.dart';

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository(
    firestore: FirebaseFirestore.instance,
    functions: FirebaseFunctions.instanceFor(region: 'asia-northeast1'),
  );
});

class BookingRepository {
  final FirebaseFirestore firestore;
  final FirebaseFunctions functions;

  BookingRepository({
    required this.firestore,
    required this.functions,
  });

  /// Fetch time slots for a specific date
  Future<List<TimeSlot>> fetchSlots(DateTime date) async {
    final yyyymmdd = _formatDateYYYYMMDD(date);
    final slotsRef = firestore
        .collection('serviceCenters')
        .doc('default')
        .collection('days')
        .doc(yyyymmdd)
        .collection('slots');

    final snapshot = await slotsRef.get();
    if (snapshot.docs.isEmpty) {
      return [];
    }

    return snapshot.docs.map((doc) {
      return TimeSlot.fromFirestore(doc.id, doc.data());
    }).toList();
  }

  /// Create a booking using Cloud Function
  Future<String> createBooking({
    required DateTime date,
    required String slotId,
    required String serviceType,
    required String vehicleId,
  }) async {
    final callable = functions.httpsCallable('createBooking');
    final result = await callable.call({
      'date': _formatDateYYYYDashMMDashDD(date),
      'slotId': slotId,
      'serviceType': serviceType,
      'vehicleId': vehicleId,
    });

    final data = result.data as Map<String, dynamic>;
    if (data['ok'] != true) {
      throw Exception(data['error'] ?? 'Booking failed');
    }

    return data['bookingId'] as String;
  }

  /// Get user's bookings stream
  Stream<List<Booking>> getUserBookings(String userId) {
    return firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Booking.fromFirestore(doc.id, doc.data());
      }).toList();
    });
  }

  /// Get today's booking for a user
  Future<Booking?> getTodayBooking(String userId) async {
    final today = _formatDateYYYYDashMMDashDD(DateTime.now());
    final snapshot = await firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .where('date', isEqualTo: today)
        .where('status', isEqualTo: 'confirmed')
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    return Booking.fromFirestore(snapshot.docs.first.id, snapshot.docs.first.data());
  }

  String _formatDateYYYYMMDD(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDateYYYYDashMMDashDD(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
