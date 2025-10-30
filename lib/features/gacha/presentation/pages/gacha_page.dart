import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:confetti/confetti.dart';
import 'package:vibration/vibration.dart';
import '../../domain/gacha_result.dart';
import '../gacha_provider.dart';
import '../widgets/gacha_button.dart';
import '../widgets/gacha_result_card.dart';
import '../widgets/streak_indicator.dart';

/// 毎日ガチャページ
class GachaPage extends ConsumerStatefulWidget {
  const GachaPage({super.key});

  @override
  ConsumerState<GachaPage> createState() => _GachaPageState();
}

class _GachaPageState extends ConsumerState<GachaPage> {
  late ConfettiController _confettiController;
  bool _showResult = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _handleGachaClaim() async {
    setState(() => _showResult = false);

    await ref.read(gachaStateProvider.notifier).claimGacha();

    final state = ref.read(gachaStateProvider);

    if (state.result != null) {
      // 成功時の演出
      _triggerSuccessEffects(state.result!);
    }
  }

  void _triggerSuccessEffects(GachaResult result) {
    // Vibration
    if (result.rank.index >= GachaRank.rare.index) {
      Vibration.vibrate(duration: 200, amplitude: 128);
    } else {
      Vibration.vibrate(duration: 100);
    }

    // Confetti（レア以上）
    if (result.rank.index >= GachaRank.rare.index) {
      _confettiController.play();
    }

    // 結果表示
    setState(() => _showResult = true);
  }

  @override
  Widget build(BuildContext context) {
    final gachaState = ref.watch(gachaStateProvider);
    final streakAsync = ref.watch(streakProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('今日のガチャ'),
        centerTitle: true,
        actions: [
          // デバッグ用リセットボタン（本番では削除）
          if (const bool.fromEnvironment('DEBUG', defaultValue: false))
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                ref.read(gachaStateProvider.notifier).reset();
                ref.invalidate(isClaimedTodayProvider);
                ref.invalidate(streakProvider);
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          // メインコンテンツ
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 連続ログイン表示
                  streakAsync.when(
                    data: (streak) => StreakIndicator(streak: streak),
                    loading: () => const SizedBox(height: 60),
                    error: (_, __) => const SizedBox(height: 60),
                  ),

                  const SizedBox(height: 32),

                  // ガチャイラスト
                  _buildGachaIllustration(gachaState),

                  const SizedBox(height: 32),

                  // 説明テキスト
                  if (!_showResult) _buildDescriptionText(),

                  // 結果カード
                  if (_showResult && gachaState.result != null)
                    GachaResultCard(result: gachaState.result!),

                  const SizedBox(height: 32),

                  // ガチャボタン
                  GachaButton(
                    state: gachaState,
                    onPressed: _handleGachaClaim,
                  ),

                  // エラーメッセージ
                  if (gachaState.hasError && gachaState.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        gachaState.errorMessage!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Confetti演出
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              gravity: 0.1,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGachaIllustration(GachaState state) {
    if (state.isLoading) {
      // ローディング時はLottieアニメーション
      return SizedBox(
        height: 240,
        child: Center(
          child: Lottie.asset(
            'assets/lottie/loading.json',
            width: 200,
            height: 200,
            errorBuilder: (context, error, stackTrace) {
              // Lottieファイルがない場合はCircularProgressIndicator
              return const CircularProgressIndicator();
            },
          ),
        ),
      );
    }

    if (_showResult && state.result != null) {
      // 結果表示時はランク別アニメーション
      final rank = state.result!.rank;
      String animationAsset;

      switch (rank) {
        case GachaRank.legendary:
          animationAsset = 'assets/lottie/legendary.json';
          break;
        case GachaRank.epic:
          animationAsset = 'assets/lottie/epic.json';
          break;
        case GachaRank.rare:
          animationAsset = 'assets/lottie/rare.json';
          break;
        default:
          animationAsset = 'assets/lottie/common.json';
      }

      return SizedBox(
        height: 240,
        child: Lottie.asset(
          animationAsset,
          width: 240,
          height: 240,
          repeat: false,
          errorBuilder: (context, error, stackTrace) {
            // Lottieファイルがない場合はアイコン表示
            return Icon(
              Icons.card_giftcard,
              size: 120,
              color: _getRankColor(rank),
            );
          },
        ),
      );
    }

    // デフォルト表示
    return Container(
      height: 240,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            Theme.of(context).colorScheme.secondary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Icon(
        Icons.card_giftcard_rounded,
        size: 120,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildDescriptionText() {
    return Column(
      children: [
        Text(
          '毎日1回ガチャを回せます！',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          '最大500ポイントが当たる！\n連続ログインでさらにお得に',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        // 当選確率表
        _buildProbabilityTable(),
      ],
    );
  }

  Widget _buildProbabilityTable() {
    final probabilities = [
      ('5pt', '55%', GachaRank.common),
      ('10pt', '30%', GachaRank.uncommon),
      ('30pt', '10%', GachaRank.rare),
      ('100pt', '4%', GachaRank.epic),
      ('500pt', '1%', GachaRank.legendary),
    ];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '当選確率',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...probabilities.map(
              (p) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _getRankColor(p.$3),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(p.$1),
                      ],
                    ),
                    Text(
                      p.$2,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRankColor(GachaRank rank) {
    switch (rank) {
      case GachaRank.legendary:
        return Colors.amber;
      case GachaRank.epic:
        return Colors.purple;
      case GachaRank.rare:
        return Colors.blue;
      case GachaRank.uncommon:
        return Colors.green;
      case GachaRank.common:
        return Colors.grey;
    }
  }
}
