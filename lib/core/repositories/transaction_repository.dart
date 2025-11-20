import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_model.dart';

/// 取引リポジトリ
class TransactionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 取引を作成
  Future<void> createTransaction(TransactionModel transaction) async {
    try {
      await _firestore
          .collection('transactions')
          .doc(transaction.id)
          .set(transaction.toFirestore());
    } catch (e) {
      throw Exception('取引の作成に失敗しました: $e');
    }
  }

  /// ユーザーの取引履歴を取得
  Future<List<TransactionModel>> getUserTransactions(
    String userId, {
    int? limit,
  }) async {
    try {
      Query query = _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => TransactionModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('取引履歴の取得に失敗しました: $e');
    }
  }

  /// ユーザーの取引履歴をリアルタイムで監視
  Stream<List<TransactionModel>> watchUserTransactions(
    String userId, {
    int? limit,
  }) {
    Query query = _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => TransactionModel.fromFirestore(doc))
        .toList());
  }
}
