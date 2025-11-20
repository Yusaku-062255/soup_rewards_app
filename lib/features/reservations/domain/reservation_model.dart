import 'package:cloud_firestore/cloud_firestore.dart';

/// 予約モデル
class ReservationModel {
  final String id;
  final String userId; // Firebase Auth の uid
  final String name; // ユーザー名
  final String? phoneNumber; // 電話番号（任意）
  final String menu; // メニュー名（例: "洗車ライト"）
  final String status; // "予約" | "施工中" | "完了" | "キャンセル"
  final DateTime scheduledDate; // 希望日時
  final String? notes; // メモ（任意）
  final DateTime createdAt;
  final DateTime? updatedAt;

  ReservationModel({
    required this.id,
    required this.userId,
    required this.name,
    this.phoneNumber,
    required this.menu,
    required this.status,
    required this.scheduledDate,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  /// Firestoreから作成
  factory ReservationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    // データが存在しない場合のエラーハンドリング
    if (data == null) {
      throw Exception('予約データが見つかりませんでした（ドキュメントID: ${doc.id}）');
    }

    // 必須フィールドのバリデーション
    if (!data.containsKey('userId') || data['userId'] == null) {
      throw Exception('ユーザーIDが見つかりませんでした（予約ID: ${doc.id}）');
    }
    if (!data.containsKey('name') || data['name'] == null) {
      throw Exception('ユーザー名が見つかりませんでした（予約ID: ${doc.id}）');
    }
    if (!data.containsKey('menu') || data['menu'] == null) {
      throw Exception('メニュー情報が見つかりませんでした（予約ID: ${doc.id}）');
    }
    if (!data.containsKey('scheduledDate') || data['scheduledDate'] == null) {
      throw Exception('予約日時が見つかりませんでした（予約ID: ${doc.id}）');
    }
    if (!data.containsKey('createdAt') || data['createdAt'] == null) {
      throw Exception('作成日時が見つかりませんでした（予約ID: ${doc.id}）');
    }

    return ReservationModel(
      id: doc.id,
      userId: data['userId'] as String,
      name: data['name'] as String,
      phoneNumber: data['phoneNumber'] as String?,
      menu: data['menu'] as String,
      status: data['status'] as String? ?? '予約',
      scheduledDate: (data['scheduledDate'] as Timestamp).toDate(),
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Firestore用に変換
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      'menu': menu,
      'status': status,
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      if (notes != null) 'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  /// コピーを作成
  ReservationModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? phoneNumber,
    String? menu,
    String? status,
    DateTime? scheduledDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReservationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      menu: menu ?? this.menu,
      status: status ?? this.status,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// 予約入力データ
class ReservationInput {
  final DateTime scheduledDate;
  final String timeSlot; // "午前" | "午後" | "夕方"
  final String menu;
  final String? notes;

  ReservationInput({
    required this.scheduledDate,
    required this.timeSlot,
    required this.menu,
    this.notes,
  });

  /// 時間帯から実際の時刻を計算
  /// scheduledDate の日付に、timeSlot に応じた時刻を設定
  DateTime getScheduledDateTime() {
    int hour;
    switch (timeSlot) {
      case '午前':
        hour = 10; // 10時（9-12時の中央）
        break;
      case '午後':
        hour = 13; // 13時（12-15時の中央）
        break;
      case '夕方':
        hour = 16; // 16時（15-18時の中央）
        break;
      default:
        hour = 10;
    }
    return DateTime(
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
      hour,
      0, // 分は0分固定
    );
  }
}

