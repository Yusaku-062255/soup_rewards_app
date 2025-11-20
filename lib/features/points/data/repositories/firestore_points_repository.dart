import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../domain/models/daily_draw_result.dart';
import '../../domain/models/rank.dart';
import '../../domain/repositories/points_repository.dart';
import '../../domain/utils/points_initializer.dart';
import '../../../../core/models/transaction_model.dart';
import '../../../../core/repositories/transaction_repository.dart';

/// Firestore実装のポイントリポジトリ
/// 
/// Firestoreスキーマ:
/// - コレクション: `users/{userId}`
///   - fields:
///     - `shopId: string`
///     - `points: number`
///     - `lastDailyDrawAt: Timestamp` (最後にくじを引いた日時)
///     - `todayDrawPoints: number` (本日のくじ結果、任意)
/// - コレクション: `transactions/{transactionId}`
///   - 日次くじやポイント付与の履歴を記録
/// 
/// データフロー（モバイル側）:
/// 1. User opens Points tab
/// 2. Daily draw → pointsRepository.drawToday(userId, shopId)
/// 3. Firestore: 
///    - users/{userId}.points += N
///    - users/{userId}.lastDailyDrawAt = now
///    - users/{userId}.todayDrawPoints = N
///    - transactions に1件追加 (type: earn, description: "日次くじ")
class FirestorePointsRepository implements PointsRepository {
  final FirebaseFirestore _firestore;
  final TransactionRepository _transactionRepository = TransactionRepository();

  FirestorePointsRepository(this._firestore);

  /// ユーザードキュメントの参照を取得
  DocumentReference _getUserDoc(String userId) {
    return _firestore.collection('users').doc(userId);
  }

  /// 日付が同じかどうかを判定（日付部分のみ比較）
  bool _isSameDay(DateTime? date1, DateTime date2) {
    if (date1 == null) return false;
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  /// ドキュメントが存在しない場合に初期ドキュメントを作成
  Future<void> _ensureDocumentExists({
    required String userId,
    required String shopId,
  }) async {
    try {
      final doc = await _getUserDoc(userId).get();
      if (!doc.exists) {
        final initialData = PointsInitializer.createInitialDocumentData(
          shopId: shopId,
        );
        await _getUserDoc(userId).set(initialData);
        if (kDebugMode) {
          print('[FirestorePointsRepository] 初期ドキュメントを作成: users/$userId');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[FirestorePointsRepository] ドキュメント作成エラー: $e');
      }
      rethrow;
    }
  }

  /// 認証済みかどうかをチェック
  /// 
  /// 匿名認証も「認証済み」として扱います。
  /// 未認証時は例外を投げます。
  void _checkAuthentication(String userId) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('認証が必要です。アプリを再起動してください。');
    }
    // userIdがFirebase Authのuidと一致することを確認
    if (userId != currentUser.uid) {
      throw Exception('ユーザーIDが一致しません。');
    }
  }

  @override
  Future<int> getCurrentPoints({
    required String userId,
    required String shopId,
  }) async {
    try {
      // ログイン済みかチェック
      _checkAuthentication(userId);
      
      // ドキュメントが存在しない場合は初期値で作成
      await _ensureDocumentExists(userId: userId, shopId: shopId);
      
      final doc = await _getUserDoc(userId).get();
      
      if (!doc.exists) {
        // 念のため再確認（レースコンディション対策）
        return PointsInitializer.getInitialPoints();
      }

      final data = doc.data() as Map<String, dynamic>?;
      final points = data?['points'] as int?;
      
      if (points == null) {
        if (kDebugMode) {
          print('[FirestorePointsRepository] pointsフィールドがnull、初期値0を返します');
        }
        return PointsInitializer.getInitialPoints();
      }
      
      return points;
    } catch (e) {
      if (kDebugMode) {
        print('[FirestorePointsRepository] getCurrentPoints エラー: $e');
      }
      throw Exception('ポイントの取得に失敗しました: $e');
    }
  }

  @override
  Future<DailyDrawState> getDailyDrawState({
    required String userId,
    required String shopId,
  }) async {
    try {
      // ログイン済みかチェック
      _checkAuthentication(userId);
      
      // ドキュメントが存在しない場合は初期状態を返す
      final doc = await _getUserDoc(userId).get();
      
      if (!doc.exists) {
        if (kDebugMode) {
          print('[FirestorePointsRepository] ドキュメントが存在しない、初期状態を返します');
        }
        return PointsInitializer.createInitialState();
      }

      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) {
        if (kDebugMode) {
          print('[FirestorePointsRepository] データがnull、初期状態を返します');
        }
        return PointsInitializer.createInitialState();
      }

      // lastDailyDrawAtを取得
      final lastDrawTimestamp = data['lastDailyDrawAt'] as Timestamp?;
      final lastDrawDate = lastDrawTimestamp?.toDate();
      
      // 今日引いたかどうかを判定
      final hasDrawnToday = _isSameDay(lastDrawDate, DateTime.now());
      
      // 今日のくじ結果を取得
      DailyDrawResult? todayResult;
      if (hasDrawnToday && lastDrawDate != null) {
        final todayDrawPoints = data['todayDrawPoints'] as int?;
        if (todayDrawPoints != null) {
          todayResult = DailyDrawResult(
            points: todayDrawPoints,
            drawnAt: lastDrawDate,
          );
        }
      }

      return DailyDrawState(
        hasDrawnToday: hasDrawnToday,
        lastDrawDate: lastDrawDate,
        todayResult: todayResult,
      );
    } catch (e) {
      if (kDebugMode) {
        print('[FirestorePointsRepository] getDailyDrawState エラー: $e');
      }
      // エラー時は初期状態を返す（アプリがクラッシュしないように）
      return PointsInitializer.createInitialState();
    }
  }

  @override
  Future<DailyDrawResult> drawToday({
    required String userId,
    required String shopId,
  }) async {
    try {
      // ログイン済みかチェック
      _checkAuthentication(userId);
      
      // TODO: 将来的には Cloud Functions でトランザクション処理を行う
      // 現時点ではクライアント側で日付チェックを行う簡易版

      // ドキュメントが存在しない場合は作成
      await _ensureDocumentExists(userId: userId, shopId: shopId);
      
      // 既に今日引いているかチェック
      final currentState = await getDailyDrawState(
        userId: userId,
        shopId: shopId,
      );
      if (currentState.hasDrawnToday) {
        throw Exception('今日は既にくじを引いています');
      }

      // ランダムなポイントを取得（ベースポイント）
      final basePoints = DailyDrawPoints.getRandomPoints();
      final now = DateTime.now();

      // 現在のポイントを取得（ランク判定に使用）
      final currentPoints = await getCurrentPoints(
        userId: userId,
        shopId: shopId,
      );

      // ランク倍率を適用して最終ポイントを計算
      // ゲスト利用時はBRONZE扱い（1.0倍）
      final finalPoints = RankCalculator.applyRankMultiplier(basePoints, currentPoints);

      // ドキュメントを更新
      await _getUserDoc(userId).update({
        'points': currentPoints + finalPoints,
        'lastDailyDrawAt': Timestamp.fromDate(now),
        'todayDrawPoints': finalPoints, // 倍率適用後のポイントを保存
      });

      // 取引履歴を追加（Admin側と整合性を保つため）
      final transactionDocRef = _firestore.collection('transactions').doc();
      final transactionModel = TransactionModel(
        id: transactionDocRef.id,
        userId: userId,
        type: TransactionType.earn,
        source: TransactionSource.dailyDraw,
        points: finalPoints, // 倍率適用後のポイント
        description: '日次くじ',
        timestamp: now,
        metadata: {
          'shopId': shopId,
          'basePoints': basePoints, // ベースポイントも記録
          'multiplier': RankCalculator.getMultiplier(RankCalculator.calculate(currentPoints)),
        },
      );
      await _transactionRepository.createTransaction(transactionModel);

      if (kDebugMode) {
        print('[FirestorePointsRepository] くじを実行: ベース${basePoints}P → 倍率適用後${finalPoints}P (合計: ${currentPoints + finalPoints}P)');
      }

      return DailyDrawResult(
        points: finalPoints, // 倍率適用後のポイントを返す
        drawnAt: now,
      );
    } catch (e) {
      if (e.toString().contains('既にくじを引いています')) {
        rethrow;
      }
      if (kDebugMode) {
        print('[FirestorePointsRepository] drawToday エラー: $e');
      }
      throw Exception('くじの実行に失敗しました: $e');
    }
  }

  @override
  Future<void> addPoints({
    required String userId,
    required String shopId,
    required int points,
  }) async {
    try {
      // ログイン済みかチェック
      _checkAuthentication(userId);
      
      // ドキュメントが存在しない場合は作成
      await _ensureDocumentExists(userId: userId, shopId: shopId);
      
      // 現在のポイントを取得
      final currentPoints = await getCurrentPoints(
        userId: userId,
        shopId: shopId,
      );
      
      // ポイントを更新
      await _getUserDoc(userId).update({
        'points': currentPoints + points,
      });

      if (kDebugMode) {
        print('[FirestorePointsRepository] ポイント追加: +${points}P (合計: ${currentPoints + points}P)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[FirestorePointsRepository] addPoints エラー: $e');
      }
      throw Exception('ポイントの追加に失敗しました: $e');
    }
  }
}
