import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../design/theme.dart';
import '../../design/widgets/soup_card.dart';
import '../../design/widgets/soup_section_title.dart';
import 'points_repository.dart';

class PointsScreen extends ConsumerStatefulWidget {
  const PointsScreen({super.key});

  @override
  ConsumerState<PointsScreen> createState() => _PointsScreenState();
}

class _PointsScreenState extends ConsumerState<PointsScreen> {
  bool _isClaimingGacha = false;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to view your points.'),
        ),
      );
    }

    final pointsRepo = ref.watch(pointsRepositoryProvider);
    final totalPointsStream = pointsRepo.totalPoints(user.uid);
    final ledgerStream = pointsRepo.ledgerPaged(user.uid, limit: 10);

    return Scaffold(
      backgroundColor: DesignTokens.surface,
      appBar: AppBar(
        title: const Text('ポイント'),
        backgroundColor: DesignTokens.primary,
        foregroundColor: DesignTokens.onPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Total points header
            StreamBuilder<int>(
              stream: totalPointsStream,
              builder: (context, snapshot) {
                final total = snapshot.data ?? 0;
                return Container(
                  padding: const EdgeInsets.all(DesignTokens.spaceHeading),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        DesignTokens.primary,
                        DesignTokens.accentMint,
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        CupertinoIcons.star_circle_fill,
                        size: 64,
                        color: Colors.white,
                      ),
                      const SizedBox(height: DesignTokens.spaceSmall),
                      Text(
                        '$total',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        '合計ポイント',
                        style: TextStyle(
                          fontSize: DesignTokens.fontSizeBody,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            Padding(
              padding: const EdgeInsets.all(DesignTokens.spaceBase),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Current month acquisition
                  FutureBuilder<int>(
                    future: pointsRepo.getCurrentMonthPoints(user.uid),
                    builder: (context, snapshot) {
                      final monthPoints = snapshot.data ?? 0;
                      return SoupCard(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '今月の獲得',
                              style: TextStyle(
                                fontSize: DesignTokens.fontSizeBody,
                                color: DesignTokens.textSecondary,
                              ),
                            ),
                            Text(
                              '+$monthPoints pt',
                              style: const TextStyle(
                                fontSize: DesignTokens.fontSizeH3,
                                fontWeight: FontWeight.bold,
                                color: DesignTokens.primary,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: DesignTokens.spaceBase),

                  // Expiring points indicator
                  FutureBuilder<({int totalPoints, DateTime? earliestExpiry})>(
                    future: pointsRepo.getExpiringPoints(user.uid),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox.shrink();

                      final data = snapshot.data!;
                      if (data.totalPoints == 0 || data.earliestExpiry == null) {
                        return const SizedBox.shrink();
                      }

                      final daysUntilExpiry = data.earliestExpiry!.difference(DateTime.now()).inDays;

                      return SoupCard(
                        backgroundColor: DesignTokens.warning.withOpacity(0.1),
                        child: Row(
                          children: [
                            const Icon(
                              CupertinoIcons.exclamationmark_triangle,
                              color: DesignTokens.warning,
                              size: 24,
                            ),
                            const SizedBox(width: DesignTokens.spaceSmall),
                            Expanded(
                              child: Text(
                                '${daysUntilExpiry}日後に ${data.totalPoints}pt 失効予定',
                                style: const TextStyle(
                                  fontSize: DesignTokens.fontSizeBody,
                                  color: DesignTokens.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: DesignTokens.spaceBase),

                  // Daily gacha button
                  ElevatedButton.icon(
                    onPressed: _isClaimingGacha ? null : () => _claimDailyGacha(context),
                    icon: _isClaimingGacha
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(CupertinoIcons.gift),
                    label: const Text('デイリーガチャを回す'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: DesignTokens.spaceBase * 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spaceSection),

                  // Ledger list
                  const SoupSectionTitle(title: 'ポイント履歴'),
                  StreamBuilder<List<PointEntry>>(
                    stream: ledgerStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return SoupCard(
                          child: Text('エラー: ${snapshot.error}'),
                        );
                      }

                      final entries = snapshot.data ?? [];
                      if (entries.isEmpty) {
                        return const SoupCard(
                          child: Text('履歴がありません'),
                        );
                      }

                      return Column(
                        children: entries.map((entry) {
                          return _buildLedgerEntry(entry);
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLedgerEntry(PointEntry entry) {
    final icon = _getIconForType(entry.type);
    final isPositive = entry.delta > 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.spaceSmall),
      child: SoupCard(
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isPositive
                    ? DesignTokens.accentMint
                    : DesignTokens.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: DesignTokens.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: DesignTokens.spaceBase),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.note,
                    style: const TextStyle(
                      fontSize: DesignTokens.fontSizeBody,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDateTime(entry.createdAt),
                    style: const TextStyle(
                      fontSize: DesignTokens.fontSizeSmall,
                      color: DesignTokens.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '残高: ${entry.balance} pt',
                    style: const TextStyle(
                      fontSize: DesignTokens.fontSizeSmall,
                      color: DesignTokens.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${isPositive ? '+' : ''}${entry.delta}',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeH3,
                fontWeight: FontWeight.bold,
                color: isPositive ? DesignTokens.primary : DesignTokens.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'gacha':
        return CupertinoIcons.gift;
      case 'booking':
        return CupertinoIcons.calendar_badge_plus;
      case 'manual':
        return CupertinoIcons.pencil_circle;
      default:
        return CupertinoIcons.star;
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}/${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _claimDailyGacha(BuildContext context) async {
    setState(() => _isClaimingGacha = true);

    try {
      final pointsRepo = ref.read(pointsRepositoryProvider);
      final result = await pointsRepo.claimDailyGacha();

      if (mounted) {
        if (result.ok) {
          final amount = result.reward?['amount'] ?? 10;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ガチャ成功！ +${amount}ポイント獲得'),
              backgroundColor: DesignTokens.success,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          final reason = result.reason ?? 'unknown';
          String message;
          if (reason == 'already_claimed') {
            final hoursLeft = (result.resetInSeconds / 3600).ceil();
            message = '本日分は既に受取済みです。リセットまで約${hoursLeft}時間';
          } else {
            message = 'ガチャを引けませんでした（理由: $reason）';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: DesignTokens.warning,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = _getErrorMessage(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: DesignTokens.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isClaimingGacha = false);
      }
    }
  }

  String _getErrorMessage(Object error) {
    final errorString = error.toString();

    // Firebase Functions エラー
    if (errorString.contains('functions/not-found')) {
      return 'ガチャ機能が利用できません。しばらくしてからお試しください。';
    } else if (errorString.contains('functions/unauthenticated')) {
      return 'ログインが必要です。再度ログインしてください。';
    } else if (errorString.contains('functions/permission-denied')) {
      return '権限がありません。アカウント設定を確認してください。';
    } else if (errorString.contains('functions/unavailable')) {
      return 'サーバーに接続できません。ネットワーク接続を確認してください。';
    } else if (errorString.contains('functions/deadline-exceeded')) {
      return '処理がタイムアウトしました。もう一度お試しください。';
    }

    // ネットワークエラー
    if (errorString.contains('SocketException') || errorString.contains('NetworkError')) {
      return 'ネットワーク接続を確認してください。';
    }

    // その他のエラー
    return 'ガチャに失敗しました。もう一度お試しください。';
  }
}
