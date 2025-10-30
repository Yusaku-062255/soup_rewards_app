import 'booking.dart';

/// 予約リポジトリ
abstract class BookingRepository {
  /// 予約一覧取得
  Future<List<Booking>> getBookings();

  /// 予約詳細取得
  Future<Booking?> getBooking(String bookingId);

  /// 予約作成
  Future<String> createBooking(Booking booking);

  /// 予約更新
  Future<void> updateBooking(Booking booking);

  /// 予約キャンセル
  Future<void> cancelBooking(String bookingId);

  /// 予約監視
  Stream<List<Booking>> watchBookings();

  /// 利用可能な時間スロット取得
  Future<List<TimeSlot>> getAvailableTimeSlots(DateTime date, BookingService service);

  /// 今後の予約取得
  Future<List<Booking>> getUpcomingBookings();

  /// 過去の予約取得
  Future<List<Booking>> getPastBookings();
}
