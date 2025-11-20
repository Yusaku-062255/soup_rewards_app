import 'package:cloud_firestore/cloud_firestore.dart';

/// QRコードモデル
///
/// Firestoreの`qr_codes/{code}`ドキュメントに対応
///
/// ## Firestoreスキーマ
/// ```
/// qr_codes/{code}
///   - id: string (ドキュメントID = QRコードの文字列)
///   - points: int (付与ポイント数)
///   - type: string (QRコードのタイプ、例: 'coating_visit')
///   - enabled: bool (有効フラグ、falseの場合は無効)
///   - expiresAt: Timestamp? (有効期限、nullの場合は無期限)
/// ```
///
/// ## バリデーション
/// - `enabled == false` の場合: 無効
/// - `expiresAt != null && expiresAt < now` の場合: 期限切れで無効
/// - 上記以外: 有効
///
/// ## エラーハンドリング
/// - ドキュメントが存在しない場合: `getQrCode()` は `null` を返す
/// - 無効なQRコードの場合: `getQrCode()` は `null` を返す
/// - UI側では「無効なQRコードです。店舗スタッフにご確認ください。」と表示
class QrCodeModel {
  final String id; // QRコードのID（ドキュメントID）
  final int points; // 付与ポイント
  final String type; // QRコードのタイプ（例: 'coating_visit'）
  final bool enabled; // 有効フラグ
  final DateTime? expiresAt; // 有効期限（nullの場合は無期限）

  QrCodeModel({
    required this.id,
    required this.points,
    required this.type,
    required this.enabled,
    this.expiresAt,
  });

  /// Firestoreから作成
  factory QrCodeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) {
      throw Exception('QRコードデータが見つかりませんでした（ID: ${doc.id}）');
    }

    return QrCodeModel(
      id: doc.id,
      points: data['points'] as int? ?? 0,
      type: data['type'] as String? ?? 'unknown',
      enabled: data['enabled'] as bool? ?? false,
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
    );
  }

  /// 有効かどうかを判定
  bool get isValid {
    if (!enabled) return false;
    if (expiresAt != null && expiresAt!.isBefore(DateTime.now())) {
      return false;
    }
    return true;
  }
}

