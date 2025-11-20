import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/reservation_model.dart';
import '../../../../core/repositories/user_repository.dart';

/// 予約リポジトリ
class ReservationsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserRepository _userRepository = UserRepository();

  /// 現在のユーザーIDを取得
  String? get currentUserId => _auth.currentUser?.uid;

  /// 予約リクエストを作成
  /// 
  /// [input] 予約入力データ
  /// 
  /// 現在ログイン中のユーザー情報を使用して予約を作成します。
  /// 未ログインの場合は例外を投げます。
  Future<void> createReservation(ReservationInput input) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('会員登録が必要です。ログインしてから予約リクエストを送信してください。');
    }

    try {
      // ユーザー情報を取得
      final user = await _userRepository.getUser(userId);
      if (user == null) {
        throw Exception('ユーザー情報が見つかりませんでした。');
      }

      // 予約日時を計算
      final scheduledDateTime = input.getScheduledDateTime();

      // 予約ドキュメントを作成
      final reservationDocRef = _firestore.collection('reservations').doc();
      final reservation = ReservationModel(
        id: reservationDocRef.id,
        userId: userId,
        name: user.name,
        phoneNumber: user.phoneNumber,
        menu: input.menu,
        status: '予約',
        scheduledDate: scheduledDateTime,
        notes: input.notes,
        createdAt: DateTime.now(),
      );

      await reservationDocRef.set(reservation.toFirestore());
    } catch (e) {
      throw Exception('予約リクエストの送信に失敗しました: $e');
    }
  }

  /// 自分の予約一覧をリアルタイムで監視
  ///
  /// ログイン済みユーザーの予約のみを取得します。
  /// scheduledDate の降順でソートされます。
  Stream<List<ReservationModel>> watchMyReservations() {
    final userId = currentUserId;
    if (userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('reservations')
        .where('userId', isEqualTo: userId)
        .orderBy('scheduledDate', descending: true)
        .snapshots()
        .map((snapshot) {
      final reservations = <ReservationModel>[];
      for (final doc in snapshot.docs) {
        try {
          reservations.add(ReservationModel.fromFirestore(doc));
        } catch (e) {
          // 個別の予約データの変換に失敗した場合は、その予約をスキップして続行
          // エラーをログに記録（本番環境ではSentryなどに送信）
          // デバッグビルドでのみログ出力
          assert(() {
            // ignore: avoid_print
            print('予約データの変換に失敗しました（ID: ${doc.id}）: $e');
            return true;
          }());
        }
      }
      return reservations;
    }).handleError((error) {
      // ストリーム全体のエラーをキャッチ
      // デバッグビルドでのみログ出力
      assert(() {
        // ignore: avoid_print
        print('予約データの取得に失敗しました: $error');
        return true;
      }());
      // エラー時は空のリストを返す代わりにエラーを再スロー
      throw Exception('予約データの読み込みに失敗しました。ネットワーク接続を確認してください。');
    });
  }
}

