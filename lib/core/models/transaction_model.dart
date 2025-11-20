import 'package:cloud_firestore/cloud_firestore.dart';

/// 取引タイプ
enum TransactionType {
  earn, // 獲得
  use, // 使用
}

/// 取引ソース
enum TransactionSource {
  dailyDraw, // デイリーくじ
  qrScan, // QRスキャン
  redemption, // 交換
  admin, // 管理者操作
}

/// 取引履歴モデル
class TransactionModel {
  final String id;
  final String userId;
  final TransactionType type;
  final TransactionSource source;
  final int points;
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata; // 追加情報（QRコードID、交換タイプなど）

  TransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.source,
    required this.points,
    required this.description,
    required this.timestamp,
    this.metadata,
  });

  /// Firestoreドキュメントから作成
  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      userId: data['userId'] as String,
      type: TransactionType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'] as String,
        orElse: () => TransactionType.earn,
      ),
      source: TransactionSource.values.firstWhere(
        (e) => e.toString().split('.').last == data['source'] as String,
        orElse: () => TransactionSource.admin,
      ),
      points: data['points'] as int,
      description: data['description'] as String,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Firestore用のMapに変換
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.toString().split('.').last,
      'source': source.toString().split('.').last,
      'points': points,
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
      if (metadata != null) 'metadata': metadata,
    };
  }
}
