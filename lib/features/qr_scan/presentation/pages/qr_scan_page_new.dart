import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/user_id_resolver.dart';
import '../../../../core/models/transaction_model.dart';
import '../../../../core/repositories/transaction_repository.dart';
import '../../data/repositories/qr_code_repository.dart';
import '../../../points/application/points_controller.dart';
import '../../../points/domain/models/rank.dart';

/// QRスキャンページ
///
/// 店舗に掲示されたQRコードをスキャンしてポイントを付与します。
///
/// ## 処理フロー
/// 1. QRコードをスキャン
/// 2. スキャン結果の文字列を `qr_codes/{code}` のドキュメントIDとして使用
/// 3. FirestoreからQRコード情報を取得・検証
///    - ドキュメントが存在しない → エラー表示
///    - `enabled == false` → エラー表示
///    - `expiresAt < now` → エラー表示
/// 4. 有効な場合のみ、ポイントを付与
/// 5. `transactions` コレクションに記録（type: 'earn', source: 'qrScan'）
///
/// ## エラーメッセージ
/// - 無効なQRコード: 「無効なQRコードです。このQRコードは使用できません。店舗スタッフにご確認ください。」
/// - ポイント付与失敗: 「エラーが発生しました。ポイントの付与に失敗しました: {エラー詳細}」
class QrScanPageNew extends ConsumerStatefulWidget {
  const QrScanPageNew({super.key});

  @override
  ConsumerState<QrScanPageNew> createState() => _QrScanPageNewState();
}

class _QrScanPageNewState extends ConsumerState<QrScanPageNew> {
  final GlobalKey _qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? _controller;
  bool _isProcessing = false;
  final QrCodeRepository _qrCodeRepository = QrCodeRepository();
  final TransactionRepository _transactionRepository = TransactionRepository();

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _onQRViewCreated(QRViewController controller) async {
    setState(() {
      _controller = controller;
    });

    controller.scannedDataStream.listen((scanData) async {
      if (_isProcessing) return;
      if (scanData.code == null || scanData.code!.isEmpty) return;

      await _handleQrCode(scanData.code!);
    });
  }

  Future<void> _handleQrCode(String code) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // QRコードを取得して検証
      final qrCode = await _qrCodeRepository.getQrCode(code);

      if (qrCode == null) {
        if (mounted) {
          _showErrorDialog('無効なQRコードです', 'このQRコードは使用できません。店舗スタッフにご確認ください。');
        }
        return;
      }

      // ユーザーIDを解決（匿名認証を含む）
      final userId = await UserIdResolver.resolveAsync();

      // 現在のポイントを取得（ランク判定に使用）
      final pointsState = ref.read(pointsNotifierProvider);
      final currentPoints = pointsState.currentPoints;

      // ランク倍率を適用して最終ポイントを計算
      // ゲスト利用時はBRONZE扱い（1.0倍）
      final basePoints = qrCode.points;
      final finalPoints = RankCalculator.applyRankMultiplier(basePoints, currentPoints);

      // ポイントを付与（倍率適用後のポイント）
      await ref.read(pointsNotifierProvider.notifier).addPoints(finalPoints);

      // 取引履歴を追加
      // TransactionModelの整合性:
      // - type: 'earn' (獲得)
      // - source: 'qrScan' (QRスキャン)
      // - metadata: QRコードIDとタイプを保存（Admin側での追跡用）
      final transactionDocRef = FirebaseFirestore.instance.collection('transactions').doc();
      final transactionModel = TransactionModel(
        id: transactionDocRef.id,
        userId: userId,
        type: TransactionType.earn,
        source: TransactionSource.qrScan,
        points: finalPoints, // 倍率適用後のポイント
        description: 'QRスキャン（${qrCode.type}）',
        timestamp: DateTime.now(),
        metadata: {
          'qrCodeId': qrCode.id,
          'qrCodeType': qrCode.type,
          'basePoints': basePoints, // ベースポイントも記録
          'multiplier': RankCalculator.getMultiplier(RankCalculator.calculate(currentPoints)),
        },
      );
      await _transactionRepository.createTransaction(transactionModel);

      // 成功ダイアログを表示（倍率適用後のポイント）
      if (mounted) {
        await _showSuccessDialog(finalPoints);
      }

      // カメラを再開
      await _controller?.resumeCamera();
    } catch (e) {
      if (mounted) {
        _showErrorDialog('エラーが発生しました', 'ポイントの付与に失敗しました: $e');
      }
      await _controller?.resumeCamera();
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _showSuccessDialog(int points) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: AppColors.success),
            SizedBox(width: 8),
            Text('ポイント付与完了'),
          ],
        ),
        content: Text('${points}Pが付与されました。'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // ダイアログを閉じる
              Navigator.of(context).pop(); // QRスキャン画面を閉じる（ポイントタブに戻る）
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QRスキャン'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textMain,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textMain),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // 説明セクション
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppColors.grey50,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '店舗スタッフから案内されたQRコードをスキャンすると、来店ポイントが付与されます。',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    softWrap: true,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // QRスキャナー
          Expanded(
            child: Stack(
              children: [
                QRView(
                  key: _qrKey,
                  onQRViewCreated: _onQRViewCreated,
                  overlay: QrScannerOverlayShape(
                    borderColor: AppColors.primary,
                    borderRadius: 16,
                    borderLength: 30,
                    borderWidth: 8,
                    cutOutSize: 250,
                  ),
                ),
                if (_isProcessing)
                  Container(
                    color: AppColors.black.withValues(alpha: 0.5),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

