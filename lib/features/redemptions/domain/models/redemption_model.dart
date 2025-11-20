import 'package:cloud_firestore/cloud_firestore.dart';

/// 交換タイプ
enum RedemptionType {
  fullGasTicket, // フル給油券
}

/// 交換ステータス
enum RedemptionStatus {
  pending, // 処理中
  completed, // 完了
  cancelled, // キャンセル
}

/// 交換モデル
///
/// Firestoreの`redemptions/{redemptionId}`ドキュメントに対応
///
/// ## Firestoreスキーマ
/// ```
/// redemptions/{redemptionId}
///   - id: string (ドキュメントID)
///   - userId: string (Firebase Auth の uid)
///   - memberId: string? (会員ID、本会員登録済みの場合のみ)
///   - type: string (交換タイプ、例: 'full_gas_ticket')
///   - pointsUsed: int (使用したポイント数)
///   - status: string (ステータス: 'pending' | 'completed' | 'cancelled')
///   - createdAt: Timestamp (作成日時)
///   - completedAt: Timestamp? (完了日時、完了時のみ)
///   - metadata: Map<string, dynamic>? (追加情報、例: previousPoints, newPoints)
/// ```
///
/// ## ポイント減算の順番
/// 1. ユーザー情報を取得してポイント残高を確認
/// 2. ポイントが足りている場合のみ、以下を実行:
///    - `redemptions` ドキュメントを作成（status: 'pending'）
///    - `users/{userId}.points` を減算
///    - `transactions` コレクションに記録（type: 'use', source: 'redemption'）
///
/// 注意: 現時点ではクライアント側で順次実行していますが、
/// 将来的には Cloud Functions でトランザクション処理を行うことを推奨します。
class RedemptionModel {
  final String id;
  final String userId;
  final String? memberId; // 会員ID（本会員登録済みの場合）
  final RedemptionType type;
  final int pointsUsed;
  final RedemptionStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final Map<String, dynamic>? metadata; // 追加情報（クーポンIDなど）

  RedemptionModel({
    required this.id,
    required this.userId,
    this.memberId,
    required this.type,
    required this.pointsUsed,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.metadata,
  });

  /// Firestoreから作成
  factory RedemptionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) {
      throw Exception('交換データが見つかりませんでした（ID: ${doc.id}）');
    }

    return RedemptionModel(
      id: doc.id,
      userId: data['userId'] as String,
      memberId: data['memberId'] as String?,
      type: RedemptionType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'] as String,
        orElse: () => RedemptionType.fullGasTicket,
      ),
      pointsUsed: data['pointsUsed'] as int? ?? 0,
      status: RedemptionStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'] as String,
        orElse: () => RedemptionStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Firestore用に変換
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      if (memberId != null) 'memberId': memberId,
      'type': type.toString().split('.').last,
      'pointsUsed': pointsUsed,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      if (completedAt != null) 'completedAt': Timestamp.fromDate(completedAt!),
      if (metadata != null) 'metadata': metadata,
    };
  }

  /// コピーを作成
  RedemptionModel copyWith({
    String? id,
    String? userId,
    String? memberId,
    RedemptionType? type,
    int? pointsUsed,
    RedemptionStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
    Map<String, dynamic>? metadata,
  }) {
    return RedemptionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      memberId: memberId ?? this.memberId,
      type: type ?? this.type,
      pointsUsed: pointsUsed ?? this.pointsUsed,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}

