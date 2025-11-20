import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/utils/user_id_resolver.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../qr_scan/presentation/pages/qr_scan_page_new.dart';
import '../../../redemptions/domain/models/redemption_model.dart';
import '../widgets/points_balance_display.dart';
import '../widgets/daily_draw_button.dart';
import '../widgets/draw_result_display.dart';
import '../widgets/next_rank_display.dart';
import '../pages/daily_draw_fullscreen_page.dart';
import '../../application/points_controller.dart';

/// ポイントページ - 日次くじ機能（ゲスト利用前提）
class PointsPage extends ConsumerStatefulWidget {
  const PointsPage({super.key});

  @override
  ConsumerState<PointsPage> createState() => _PointsPageState();
}

class _PointsPageState extends ConsumerState<PointsPage> {
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    // 初期化はbuildメソッド内で安全に行う
  }

  /// 「本日のポイントを受け取る」ボタンをタップしたときの処理
  ///
  /// 常にデイリーくじ画面（DailyDrawFullscreenPage）を開きます。
  /// ゲスト（匿名ユーザー）でも利用可能です。
  /// 今日すでにくじを引いている場合は、くじ画面内で「今日はもう受け取り済みです」と表示されます。
  Future<void> _handleDraw() async {
    if (!mounted) return;
    
    // 常にデイリーくじ画面を開く
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const DailyDrawFullscreenPage(),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 初回のみ初期化を試みる（安全に実行）
    if (!_hasInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_hasInitialized) {
          _hasInitialized = true;
          // 初期化を確実に実行してからリフレッシュ
          _safeRefresh();
        }
      });
    }

    // Notifierの状態を監視（初期化されていない場合は安全にデフォルト値を返す）
    final drawState = ref.watch(dailyDrawNotifierProvider);
    final pointsState = ref.watch(pointsNotifierProvider);
    final drawResult = ref.watch(drawResultProvider);
    final authState = ref.watch(authStateChangesProvider);
    final isGuest = authState.value == null;
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ポイント'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textMain,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(dailyDrawNotifierProvider.notifier).refresh();
          await ref.read(pointsNotifierProvider.notifier).refresh();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ゲスト利用中の案内（小さく表示）
              if (isGuest)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.grey50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.grey200,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '※ゲスト利用中です。ポイントは貯められますが、使うには会員登録が必要です。\n会員登録すると、機種変更時もポイントを引き継げます。',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // ポイント残高表示
              PointsBalanceDisplay(
                points: pointsState.currentPoints,
                vehicleType: userAsync.value?.vehicleType,
              ),
              
              const SizedBox(height: 28),
              
              // くじ結果表示（一時的）
              if (drawResult != null) ...[
                DrawResultDisplay(result: drawResult),
                const SizedBox(height: 28),
              ],
              
              // くじを引く前 or 引いた後
              if (!drawState.hasDrawnToday && drawResult == null)
                DailyDrawButton(
                  onTap: _handleDraw,
                  isLoading: drawState.isLoading,
                )
              else if (drawState.hasDrawnToday && drawResult == null)
                DrawCompletedDisplay(
                  currentPoints: pointsState.currentPoints,
                ),
              
              const SizedBox(height: 28),
              
              // ランク表示
              NextRankDisplay(currentPoints: pointsState.currentPoints),
              
              const SizedBox(height: 32),
              
              // 来店ポイントをもらうボタン
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const QrScanPageNew(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.qr_code_scanner,
                            color: AppColors.primary,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '来店ポイントをもらう',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '店舗のQRコードをスキャン',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // ポイントを使うセクション
              _buildRedemptionSection(context),
              
              // 下部の余白
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// 安全にリフレッシュを実行
  Future<void> _safeRefresh() async {
    try {
      // 初期化を確実に実行してからリフレッシュ
      await ref.read(dailyDrawNotifierProvider.notifier).ensureInitialized();
      await ref.read(pointsNotifierProvider.notifier).ensureInitialized();
      
      // 初期化完了後にリフレッシュ
      await ref.read(dailyDrawNotifierProvider.notifier).refresh();
      await ref.read(pointsNotifierProvider.notifier).refresh();
    } catch (e) {
      // エラー時は無視（初期化がまだ完了していない場合など）
      debugPrint('[PointsPage] リフレッシュエラー: $e');
    }
  }

  /// ポイント交換セクションを構築
  Widget _buildRedemptionSection(BuildContext context) {
    // フル給油券に必要なポイント（仮の値、将来的には設定から取得）
    const int fullGasTicketPoints = 1000;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ポイントを使う',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '貯めたポイントを給油券と交換できます。\n※ポイントを使うには会員登録が必要です。',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            // フル給油券カード
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.grey50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.grey200,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.local_gas_station,
                      color: AppColors.secondary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'フル給油券',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${fullGasTicketPoints}P必要',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _handleRedemption(context, fullGasTicketPoints),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('交換する'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ポイント交換を処理
  ///
  /// 会員チェックロジック:
  /// - `memberId == null` の場合: 会員登録ダイアログを表示し、ProfilePageに遷移
  /// - `memberId != null` の場合: ポイント交換を実行
  ///
  /// この条件分岐は、ポイントを使うアクション時に一元的に処理されます。
  Future<void> _handleRedemption(BuildContext context, int pointsRequired) async {
    try {
      // ユーザーIDを解決
      final userId = await UserIdResolver.resolveAsync();
      
      // ユーザー情報を取得
      final userRepository = ref.read(userRepositoryProvider);
      final user = await userRepository.getUser(userId);

      if (user == null) {
        if (!mounted) return;
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ユーザー情報が見つかりませんでした'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      // 本会員登録チェック
      if (user.memberId == null) {
        // 会員登録が必要
        if (!mounted) return;
        // ignore: use_build_context_synchronously
        final shouldRegister = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('会員登録が必要です'),
            content: const Text(
              'ポイントを使うには会員登録が必要です。\n\n'
              '会員登録をすると、ポイントやクーポンを安全に管理できます。',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('キャンセル'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                ),
                child: const Text('会員登録する'),
              ),
            ],
          ),
        );

        if (shouldRegister == true && mounted) {
          // ignore: use_build_context_synchronously
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const ProfilePage(),
            ),
          );
        }
        return;
      }

      // ポイントが足りているかチェック
      if (user.points < pointsRequired) {
        if (!mounted) return;
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ポイントが不足しています（現在: ${user.points}P、必要: ${pointsRequired}P）',
            ),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      // 確認ダイアログ
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      final shouldProceed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('フル給油券と交換'),
          content: Text(
            '${pointsRequired}Pを使用してフル給油券と交換しますか？\n\n'
            '交換後、ポイントは${user.points - pointsRequired}Pになります。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.white,
              ),
              child: const Text('交換する'),
            ),
          ],
        ),
      );

      if (shouldProceed != true) return;

      // 交換を実行
      final redemptionsRepo = ref.read(redemptionsRepositoryProvider);
      await redemptionsRepo.createRedemption(
        userId: userId,
        type: RedemptionType.fullGasTicket,
        pointsUsed: pointsRequired,
        memberId: user.memberId,
      );

      // ポイントをリフレッシュ
      await ref.read(pointsNotifierProvider.notifier).refresh();

      // 成功メッセージ
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('フル給油券と交換しました'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('エラーが発生しました: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
