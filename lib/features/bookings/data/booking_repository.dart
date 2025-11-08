import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/booking.dart';

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

  /// List available slots for a given date and service type
  ///
  /// [centerId] - Service center ID (default: "default")
  /// [date] - Date in YYYYMMDD format (e.g., "20250115")
  /// [serviceType] - Service type ("wash" or "coating")
  Future<List<Slot>> listAvailableSlots({
    required String centerId,
    required String date,
    required String serviceType,
  }) async {
    final callable = functions.httpsCallable('listAvailableSlots');
    final result = await callable.call({
      'centerId': centerId,
      'date': date,
      'serviceType': serviceType,
    });

    final data = result.data as Map<String, dynamic>;
    final slots = data['slots'] as List<dynamic>;

    return slots.map((slot) => Slot.fromJson(slot as Map<String, dynamic>)).toList();
  }

  /// Create a new booking
  ///
  /// [centerId] - Service center ID
  /// [slotId] - Slot ID
  /// [date] - Date in YYYYMMDD format
  /// [serviceType] - Service type ("wash" or "coating")
  ///
  /// Returns the booking ID on success
  Future<String> createBooking({
    required String centerId,
    required String slotId,
    required String date,
    required String serviceType,
  }) async {
    final callable = functions.httpsCallable('createBooking');
    final result = await callable.call({
      'centerId': centerId,
      'slotId': slotId,
      'date': date,
      'serviceType': serviceType,
    });

    final data = result.data as Map<String, dynamic>;
    return data['bookingId'] as String;
  }

  /// Cancel a booking
  ///
  /// [bookingId] - Booking ID to cancel
  Future<void> cancelBooking({
    required String bookingId,
  }) async {
    final callable = functions.httpsCallable('cancelBooking');
    await callable.call({
      'bookingId': bookingId,
    });
  }

  /// Stream user's bookings (most recent first)
  Stream<List<Booking>> userBookings(String userId) {
    return firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Booking.fromFirestore(doc.id, doc.data());
      }).toList();
    });
  }

  /// Format DateTime to YYYYMMDD string
  static String formatDateYYYYMMDD(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year$month$day';
  }

  /// Parse YYYYMMDD string to DateTime
  static DateTime parseDateYYYYMMDD(String yyyymmdd) {
    if (yyyymmdd.length != 8) {
      throw ArgumentError('Invalid date format: $yyyymmdd');
    }
    final year = int.parse(yyyymmdd.substring(0, 4));
    final month = int.parse(yyyymmdd.substring(4, 6));
    final day = int.parse(yyyymmdd.substring(6, 8));
    return DateTime(year, month, day);
  }
}
