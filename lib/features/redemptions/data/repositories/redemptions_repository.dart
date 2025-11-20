import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../domain/models/redemption_model.dart';
import '../../../../core/models/transaction_model.dart';
import '../../../../core/repositories/transaction_repository.dart';
import '../../../../core/repositories/user_repository.dart';

/// 交換リポジトリ
///
/// Firestoreの`redemptions`コレクションと連携
class RedemptionsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TransactionRepository _transactionRepository = TransactionRepository();
  final UserRepository _userRepository = UserRepository();

  /// 交換リクエストを作成
  ///
  /// [userId] ユーザーID
  /// [type] 交換タイプ
  /// [pointsUsed] 使用ポイント
  ///
  /// 注意: このメソッドはポイントの減算も行います。
  /// 会員登録チェックは呼び出し側で行ってください。
  Future<RedemptionModel> createRedemption({
    required String userId,
    required RedemptionType type,
    required int pointsUsed,
    String? memberId,
  }) async {
    try {
      // 現在のユーザー情報を取得
      final user = await _userRepository.getUser(userId);
      if (user == null) {
        throw Exception('ユーザー情報が見つかりませんでした');
      }

      // ポイントが足りているかチェック
      if (user.points < pointsUsed) {
        throw Exception('ポイントが不足しています（現在: ${user.points}P、必要: ${pointsUsed}P）');
      }

      // 交換ドキュメントを作成
      final redemptionDocRef = _firestore.collection('redemptions').doc();
      final now = DateTime.now();

      final redemption = RedemptionModel(
        id: redemptionDocRef.id,
        userId: userId,
        memberId: memberId ?? user.memberId,
        type: type,
        pointsUsed: pointsUsed,
        status: RedemptionStatus.pending,
        createdAt: now,
        metadata: {
          'previousPoints': user.points,
          'newPoints': user.points - pointsUsed,
        },
      );

      // Firestoreに保存
      await redemptionDocRef.set(redemption.toFirestore());

      // ポイントを減算
      // 注意: 現時点ではクライアント側で順次実行していますが、
      // 将来的には Cloud Functions でトランザクション処理を行うことを推奨します。
      // これにより、redemptions作成とポイント減算の原子性を保証できます。
      await _userRepository.updatePoints(userId, user.points - pointsUsed);

      // 取引履歴を追加
      final transactionDocRef = _firestore.collection('transactions').doc();
      final transactionModel = TransactionModel(
        id: transactionDocRef.id,
        userId: userId,
        type: TransactionType.use,
        source: TransactionSource.redemption,
        points: pointsUsed,
        description: _getRedemptionDescription(type),
        timestamp: now,
        metadata: {
          'redemptionId': redemption.id,
          'redemptionType': type.toString().split('.').last,
        },
      );
      await _transactionRepository.createTransaction(transactionModel);

      if (kDebugMode) {
        print('[RedemptionsRepository] 交換リクエストを作成: ${redemption.id} (${pointsUsed}P使用)');
      }

      return redemption;
    } catch (e) {
      if (kDebugMode) {
        print('[RedemptionsRepository] 交換作成エラー: $e');
      }
      rethrow;
    }
  }

  /// 交換タイプに応じた説明文を取得
  String _getRedemptionDescription(RedemptionType type) {
    switch (type) {
      case RedemptionType.fullGasTicket:
        return 'フル給油券と交換';
    }
  }

  /// ユーザーの交換履歴を取得
  Future<List<RedemptionModel>> getUserRedemptions(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('redemptions')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => RedemptionModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('[RedemptionsRepository] 交換履歴取得エラー: $e');
      }
      throw Exception('交換履歴の取得に失敗しました: $e');
    }
  }

  /// ユーザーの交換履歴をリアルタイムで監視
  Stream<List<RedemptionModel>> watchUserRedemptions(String userId) {
    return _firestore
        .collection('redemptions')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RedemptionModel.fromFirestore(doc))
            .toList());
  }
}

