import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/booking_repository.dart';
import '../domain/booking.dart';
import '../data/booking_repository_impl.dart';

/// 予約リポジトリプロバイダー
final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepositoryImpl();
});

/// 予約一覧プロバイダー
final bookingsProvider = StreamProvider<List<Booking>>((ref) {
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.watchBookings();
});

/// 今後の予約プロバイダー
final upcomingBookingsProvider = FutureProvider<List<Booking>>((ref) async {
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.getUpcomingBookings();
});

/// 過去の予約プロバイダー
final pastBookingsProvider = FutureProvider<List<Booking>>((ref) async {
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.getPastBookings();
});

/// 特定の予約プロバイダー
final bookingProvider =
    FutureProvider.family<Booking?, String>((ref, bookingId) async {
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.getBooking(bookingId);
});

/// 利用可能時間スロットプロバイダー
final availableTimeSlotsProvider = FutureProvider.family<List<TimeSlot>,
    ({DateTime date, BookingService service})>((ref, params) async {
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.getAvailableTimeSlots(params.date, params.service);
});
