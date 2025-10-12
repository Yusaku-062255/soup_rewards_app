import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SoupFloatingActionButtons extends StatelessWidget {
  const SoupFloatingActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 予約ボタン
        FloatingActionButton.extended(
          onPressed: () => _onBookingTap(context),
          backgroundColor: const Color(0xFFEF4444),
          foregroundColor: Colors.white,
          icon: const Icon(Icons.calendar_today),
          label: const Text(
            '予約',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          heroTag: 'booking_fab',
        ),
        const SizedBox(height: 12),
        // 電話ボタン
        FloatingActionButton.extended(
          onPressed: () => _onPhoneTap(context),
          backgroundColor: const Color(0xFF10B981),
          foregroundColor: Colors.white,
          icon: const Icon(Icons.phone),
          label: const Text(
            '電話',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          heroTag: 'phone_fab',
        ),
      ],
    );
  }

  Future<void> _onBookingTap(BuildContext context) async {
    // TODO: Analytics logging
    // await analytics.logButtonTap('fab_booking');
    
    const bookingUrl = 'https://soup.tokushima.jp/reserve';
    final uri = Uri.parse(bookingUrl);
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showErrorSnackBar(context, '予約ページを開けませんでした');
      }
    } catch (e) {
      _showErrorSnackBar(context, '予約ページを開けませんでした');
    }
  }

  Future<void> _onPhoneTap(BuildContext context) async {
    // TODO: Analytics logging
    // await analytics.logPhoneCall('0883-22-8655');
    
    // 電話前の確認ダイアログを表示
    final shouldCall = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('電話をかけますか？'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SOUP カーケアサービス'),
              SizedBox(height: 8),
              Text(
                '0883-22-8655',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              SizedBox(height: 16),
              Text(
                '作業中のご相談・空き時間確認はこちら',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
              ),
              child: const Text('電話をかける'),
            ),
          ],
        );
      },
    );

    if (shouldCall == true) {
      const phoneNumber = 'tel:0883-22-8655';
      final uri = Uri.parse(phoneNumber);
      
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          _showErrorSnackBar(context, '電話をかけることができませんでした');
        }
      } catch (e) {
        _showErrorSnackBar(context, '電話をかけることができませんでした');
      }
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
