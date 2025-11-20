import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/transaction_model.dart';

/// 管理画面用ポイントリポジトリ
/// 
/// スタッフがポイントを付与するための機能を提供
/// 
/// 注意: このリポジトリは管理画面専用です。
/// モバイルアプリ側のFirestorePointsRepositoryとは独立して動作します。
/// 
/// データフロー（Admin側）:
/// 1. Staff searches member → selects service menu
/// 2. AdminPointsRepository.grantPoints(userId, points, description, shopId)
/// 3. Firestore (トランザクション内で原子的に実行):
///    - users/{userId}.points += M
///    - users/{userId}.lastVisitDate = now
///    - users/{userId}.visitCount += 1
///    - users/{userId}.updatedAt = now
///    - transactions に1件追加 (type: earn, description: サービス名)
class AdminPointsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ユーザードキュメントの参照を取得
  DocumentReference _getUserDoc(String userId) {
    return _firestore.collection('users').doc(userId);
  }

  /// ポイントを付与（トランザクション処理）
  /// 
  /// [userId] ユーザーID
  /// [points] 付与するポイント数
  /// [description] 付与理由（例：「洗車ライト」）
  /// [shopId] 店舗ID（デフォルト: 'soup'）
  /// 
  /// トランザクション内で以下を原子的に実行:
  /// 1. users/{userId} の points フィールドを加算
  /// 2. lastVisitDate を更新（今回の付与時間）
  /// 3. visitCount を +1
  /// 4. transactions コレクションに取引履歴を追加
  /// 
  /// エラー時は例外を投げ、UI側でエラー表示できるようにする
  Future<void> grantPoints({
    required String userId,
    required int points,
    required String description,
    String shopId = 'soup',
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // 1. ユーザードキュメントを取得
        final userDocRef = _getUserDoc(userId);
        final userDoc = await transaction.get(userDocRef);

        if (!userDoc.exists) {
          throw Exception('ユーザーが見つかりませんでした');
        }

        final userData = userDoc.data() as Map<String, dynamic>;
        
        // 2. 現在のポイントを取得
        final currentPoints = (userData['points'] as int?) ?? 0;
        final newPoints = currentPoints + points;

        // 3. 現在の来店回数を取得
        final currentVisitCount = (userData['visitCount'] as int?) ?? 0;
        final newVisitCount = currentVisitCount + 1;

        // 4. 現在時刻を取得（トランザクション内で一貫性を保つ）
        final now = FieldValue.serverTimestamp();

        // 5. ユーザードキュメントを更新
        transaction.update(userDocRef, {
          'points': newPoints,
          'lastVisitDate': now,
          'visitCount': newVisitCount,
          'updatedAt': now,
        });

        // 6. 取引履歴を追加
        final transactionDocRef = _firestore.collection('transactions').doc();
        final transactionModel = TransactionModel(
          id: transactionDocRef.id,
          userId: userId,
          type: TransactionType.earn,
          source: TransactionSource.admin,
          points: points,
          description: description,
          timestamp: DateTime.now(),
          metadata: {
            'shopId': shopId,
          },
        );

        transaction.set(transactionDocRef, transactionModel.toFirestore());
      });
    } on FirebaseException catch (e) {
      throw Exception('ポイント付与に失敗しました: ${e.message}');
    } catch (e) {
      throw Exception('ポイント付与に失敗しました: $e');
    }
  }

  /// 現在のポイントを取得
  /// 
  /// 注意: このメソッドは管理画面用です。
  /// モバイルアプリ側のFirestorePointsRepositoryとは独立しています。
  Future<int> getCurrentPoints({
    required String userId,
    String shopId = 'soup',
  }) async {
    try {
      final userDoc = await _getUserDoc(userId).get();
      
      if (!userDoc.exists) {
        return 0;
      }

      final data = userDoc.data() as Map<String, dynamic>?;
      return data?['points'] as int? ?? 0;
    } catch (e) {
      throw Exception('ポイントの取得に失敗しました: $e');
    }
  }
}
