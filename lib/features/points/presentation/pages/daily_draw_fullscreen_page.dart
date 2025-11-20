import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../application/points_controller.dart';
import '../../domain/models/daily_draw_result.dart';

/// デイリーくじのフルスクリーン表示ページ
///
/// アプリ起動時に、その日のくじが未実行の場合に自動表示されます。
class DailyDrawFullscreenPage extends ConsumerStatefulWidget {
  const DailyDrawFullscreenPage({super.key});

  @override
  ConsumerState<DailyDrawFullscreenPage> createState() =>
      _DailyDrawFullscreenPageState();
}

class _DailyDrawFullscreenPageState
    extends ConsumerState<DailyDrawFullscreenPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _isDrawing = false;
  DailyDrawResult? _drawResult;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    // アニメーション開始
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleDraw() async {
    if (_isDrawing) return;

    setState(() {
      _isDrawing = true;
    });

    try {
      final result = await ref.read(dailyDrawNotifierProvider.notifier).draw();

      // ポイントをリフレッシュ
      await ref.read(pointsNotifierProvider.notifier).refresh();

      setState(() {
        _drawResult = result;
      });

      // 結果表示後に少し待ってから閉じる
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      setState(() {
        _isDrawing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // contextをローカル変数に保存（非同期処理後の使用を安全にするため）
    final navigator = Navigator.of(context);
    final drawState = ref.watch(dailyDrawNotifierProvider);
    
    // 今日すでにくじを引いている場合
    final hasDrawnToday = drawState.hasDrawnToday;
    final todayResult = drawState.todayResult;
    
    return PopScope(
      canPop: _isDrawing || _drawResult != null,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        // バックボタンで閉じることを許可（ただし、くじを引いていない場合は警告）
        if (!_isDrawing && _drawResult == null) {
          final shouldClose = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('くじを引きますか？'),
              content: const Text(
                '今日のポイントを受け取るには、くじを引く必要があります。\n\n'
                '後でポイントタブからも受け取れます。',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('くじを引く'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('閉じる'),
                ),
              ],
            ),
          );
          if (shouldClose == true && mounted) {
            navigator.pop();
          }
        } else if (mounted) {
          navigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                ),
              );
            },
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // アイコン
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.stars,
                        size: 64,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // タイトル
                    Text(
                      '今日のSOUPデイリーチャンス',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // 説明
                    Text(
                      '1日1回、来店前でもアプリを開くだけでポイントが貯まります。',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),

                    // 今日すでにくじを引いている場合の表示
                    if (hasDrawnToday && todayResult != null && _drawResult == null) ...[
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.grey50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.grey300,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              size: 64,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '今日はもう受け取り済みです',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${todayResult.points}Pを受け取りました',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('閉じる'),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // くじ結果表示（今引いたばかりの場合）
                    if (_drawResult != null) ...[
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.success,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${_drawResult!.points}P 獲得！',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineLarge
                                  ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'ポイントが追加されました',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // ボタン（まだ引いていない場合のみ）
                    if (!hasDrawnToday && _drawResult == null)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isDrawing ? null : _handleDraw,
                          icon: _isDrawing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.white,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.stars),
                          label: Text(
                            _isDrawing ? 'くじを引いています...' : '今日のポイントを受け取る',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

