import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../domain/models/qr_code_model.dart';

/// QRコードリポジトリ
///
/// Firestoreの`qr_codes`コレクションと連携
class QrCodeRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// QRコードを取得して検証
  ///
  /// [code] QRコードのID（スキャン結果の文字列）
  ///
  /// 戻り値: 有効なQRコードモデル、またはnull（無効な場合）
  ///
  /// 例外: Firestoreアクセスエラー時
  Future<QrCodeModel?> getQrCode(String code) async {
    try {
      final doc = await _firestore.collection('qr_codes').doc(code).get();

      if (!doc.exists) {
        if (kDebugMode) {
          print('[QrCodeRepository] QRコードが見つかりません: $code');
        }
        return null;
      }

      final qrCode = QrCodeModel.fromFirestore(doc);

      if (!qrCode.isValid) {
        if (kDebugMode) {
          print('[QrCodeRepository] QRコードが無効です: $code (enabled: ${qrCode.enabled}, expiresAt: ${qrCode.expiresAt})');
        }
        return null;
      }

      return qrCode;
    } catch (e) {
      if (kDebugMode) {
        print('[QrCodeRepository] QRコード取得エラー: $e');
      }
      throw Exception('QRコードの取得に失敗しました: $e');
    }
  }
}

