import 'package:flutter/material.dart';
import '../../domain/gacha_result.dart';
import '../gacha_provider.dart';

/// ガチャ実行ボタン
class GachaButton extends StatelessWidget {
  final GachaState state;
  final VoidCallback onPressed;

  const GachaButton({
    super.key,
    required this.state,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = state.isLoading || state.isAlreadyClaimed;

    return FilledButton(
      onPressed: isDisabled ? null : onPressed,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: _getButtonColor(context),
      ),
      child: _buildButtonContent(context),
    );
  }

  Color _getButtonColor(BuildContext context) {
    if (state.isAlreadyClaimed) {
      return Theme.of(context).colorScheme.surfaceVariant;
    }
    return Theme.of(context).colorScheme.primary;
  }

  Widget _buildButtonContent(BuildContext context) {
    if (state.isLoading) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'ガチャ実行中...',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      );
    }

    if (state.isAlreadyClaimed) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            '本日実行済み',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.card_giftcard,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
        const SizedBox(width: 8),
        Text(
          'ガチャを回す',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}
