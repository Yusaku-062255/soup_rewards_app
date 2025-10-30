import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/booking_repository.dart';
import '../domain/booking.dart';

/// 予約リポジトリ実装
class BookingRepositoryImpl implements BookingRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  BookingRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String get _userId {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return user.uid;
  }

  CollectionReference get _bookingsCollection {
    return _firestore.collection('bookings');
  }

  @override
  Future<List<Booking>> getBookings() async {
    final snapshot = await _bookingsCollection
        .where('userId', isEqualTo: _userId)
        .orderBy('scheduledAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList();
  }

  @override
  Future<Booking?> getBooking(String bookingId) async {
    final doc = await _bookingsCollection.doc(bookingId).get();
    if (!doc.exists) return null;
    return Booking.fromFirestore(doc);
  }

  @override
  Future<String> createBooking(Booking booking) async {
    final bookingData = booking.toJson();
    bookingData['createdAt'] = FieldValue.serverTimestamp();

    final docRef = await _bookingsCollection.add(bookingData);
    return docRef.id;
  }

  @override
  Future<void> updateBooking(Booking booking) async {
    final bookingData = booking.toJson();
    await _bookingsCollection.doc(booking.id).update(bookingData);
  }

  @override
  Future<void> cancelBooking(String bookingId) async {
    await _bookingsCollection.doc(bookingId).update({
      'status': BookingStatus.cancelled.name,
      'cancelledAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<List<Booking>> watchBookings() {
    return _bookingsCollection
        .where('userId', isEqualTo: _userId)
        .orderBy('scheduledAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList());
  }

  @override
  Future<List<TimeSlot>> getAvailableTimeSlots(
    DateTime date,
    BookingService service,
  ) async {
    // 営業時間: 9:00-18:00
    final slots = <TimeSlot>[];
    final startHour = 9;
    final endHour = 18;

    // サービス時間に応じてスロット生成
    final slotDuration = service.duration;
    final totalMinutes = (endHour - startHour) * 60;
    final slotCount = totalMinutes ~/ slotDuration.inMinutes;

    // 当日の予約を取得
    final dayStart = DateTime(date.year, date.month, date.day, 0, 0);
    final dayEnd = DateTime(date.year, date.month, date.day, 23, 59);

    final existingBookings = await _bookingsCollection
        .where('scheduledAt', isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
        .where('scheduledAt', isLessThanOrEqualTo: Timestamp.fromDate(dayEnd))
        .where('status', isEqualTo: BookingStatus.pending.name)
        .get();

    final bookedTimes = existingBookings.docs
        .map((doc) => Booking.fromFirestore(doc))
        .map((b) => b.scheduledAt)
        .toSet();

    // スロット生成
    for (int i = 0; i < slotCount; i++) {
      final minutes = startHour * 60 + (i * slotDuration.inMinutes);
      final hour = minutes ~/ 60;
      final minute = minutes % 60;

      final slotTime = DateTime(date.year, date.month, date.day, hour, minute);

      // 過去の時間はスキップ
      if (slotTime.isBefore(DateTime.now())) {
        continue;
      }

      // 既に予約されているか確認
      final isBooked = bookedTimes.any((bookedTime) {
        final diff = slotTime.difference(bookedTime).abs();
        return diff.inMinutes < slotDuration.inMinutes;
      });

      slots.add(TimeSlot(
        dateTime: slotTime,
        isAvailable: !isBooked,
      ));
    }

    return slots;
  }

  @override
  Future<List<Booking>> getUpcomingBookings() async {
    final now = DateTime.now();
    final snapshot = await _bookingsCollection
        .where('userId', isEqualTo: _userId)
        .where('scheduledAt', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .where('status', whereIn: [
          BookingStatus.pending.name,
          BookingStatus.confirmed.name
        ])
        .orderBy('scheduledAt')
        .get();

    return snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList();
  }

  @override
  Future<List<Booking>> getPastBookings() async {
    final now = DateTime.now();
    final snapshot = await _bookingsCollection
        .where('userId', isEqualTo: _userId)
        .where('scheduledAt', isLessThan: Timestamp.fromDate(now))
        .orderBy('scheduledAt', descending: true)
        .limit(20)
        .get();

    return snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList();
  }
}
