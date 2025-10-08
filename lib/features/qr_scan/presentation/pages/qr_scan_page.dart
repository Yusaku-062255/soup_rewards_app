import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';

class QrScanPage extends ConsumerWidget {
  const QrScanPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QRスキャン'),
        backgroundColor: AppColors.white,
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'QRスキャンページ\n（VS Code開発時に実装）',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
