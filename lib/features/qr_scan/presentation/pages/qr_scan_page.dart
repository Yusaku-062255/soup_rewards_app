import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'qr_scan_page_new.dart';

/// QRスキャンページ（エクスポート用のエイリアス）
///
/// 他のファイルから `QRScanPage` として参照される場合のエイリアス。
/// 実際の実装は `QrScanPageNew` を使用します。
class QRScanPage extends ConsumerWidget {
  const QRScanPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const QrScanPageNew();
  }
}

