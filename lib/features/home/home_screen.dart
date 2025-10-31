import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../design/theme.dart';
import '../../design/widgets/soup_card.dart';
import '../../design/widgets/soup_progress_bar.dart';
import '../../design/widgets/soup_section_title.dart';
import '../booking/booking_repository.dart';
import '../points/points_repository.dart';

class HomeScreen extends ConsumerWidget {
  final VoidCallback onNavigateToBooking;

  const HomeScreen({
    super.key,
    required this.onNavigateToBooking,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(
        child: Text('Please log in to view your home screen.'),
      );
    }

    return Scaffold(
      backgroundColor: DesignTokens.surface,
      appBar: AppBar(
        title: const Text('ホーム'),
        backgroundColor: DesignTokens.primary,
        foregroundColor: DesignTokens.onPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignTokens.spaceBase),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Points summary card
            _buildPointsSummaryCard(context, ref, user.uid),
            const SizedBox(height: DesignTokens.spaceSection),

            // Today's booking card
            _buildTodayBookingCard(context, ref, user.uid),
            const SizedBox(height: DesignTokens.spaceSection),

            // Quest section
            const SoupSectionTitle(title: '進行中のクエスト'),
            const SizedBox(height: DesignTokens.spaceSmall),
            _buildQuestCard(
              context,
              title: 'デイリーガチャをクリア',
              description: '毎日ガチャを回してポイントをゲット！',
              progress: 0.7,
              icon: CupertinoIcons.gift,
            ),
            const SizedBox(height: DesignTokens.spaceSmall),
            _buildQuestCard(
              context,
              title: '初回予約を完了',
              description: '洗車サービスを予約してボーナスポイント獲得',
              progress: 0.3,
              icon: CupertinoIcons.calendar_badge_plus,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onNavigateToBooking,
        backgroundColor: DesignTokens.primary,
        foregroundColor: DesignTokens.onPrimary,
        icon: const Icon(CupertinoIcons.calendar_badge_plus),
        label: const Text('予約する'),
      ),
    );
  }

  Widget _buildPointsSummaryCard(BuildContext context, WidgetRef ref, String userId) {
    final totalPointsAsync = ref.watch(
      pointsRepositoryProvider.select((repo) => repo.totalPoints(userId)),
    );

    return totalPointsAsync.when(
      data: (total) => SoupCard(
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: DesignTokens.accentMint,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                CupertinoIcons.star_fill,
                color: DesignTokens.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: DesignTokens.spaceBase),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '保有ポイント',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: DesignTokens.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$total pt',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: DesignTokens.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      loading: () => const SoupCard(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SoupCard(
        child: Text('ポイント読込エラー'),
      ),
    );
  }

  Widget _buildTodayBookingCard(BuildContext context, WidgetRef ref, String userId) {
    final bookingRepo = ref.watch(bookingRepositoryProvider);

    return FutureBuilder<Booking?>(
      future: bookingRepo.getTodayBooking(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final booking = snapshot.data;
        if (booking == null) {
          return const SizedBox.shrink();
        }

        return SoupCard(
          backgroundColor: DesignTokens.accentMint,
          child: Row(
            children: [
              const Icon(
                CupertinoIcons.check_mark_circled_solid,
                color: DesignTokens.primary,
                size: 32,
              ),
              const SizedBox(width: DesignTokens.spaceBase),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '本日の予約',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${booking.date} ${booking.slotId}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuestCard(
    BuildContext context, {
    required String title,
    required String description,
    required double progress,
    required IconData icon,
  }) {
    return SoupCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: DesignTokens.primary),
              const SizedBox(width: DesignTokens.spaceSmall),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: DesignTokens.fontSizeBody,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spaceSmall),
          Text(
            description,
            style: const TextStyle(
              fontSize: DesignTokens.fontSizeCaption,
              color: DesignTokens.textSecondary,
            ),
          ),
          const SizedBox(height: DesignTokens.spaceBase),
          SoupProgressBar(progress: progress, height: 10),
          const SizedBox(height: 4),
          Text(
            '${(progress * 100).toInt()}% 完了',
            style: const TextStyle(
              fontSize: DesignTokens.fontSizeSmall,
              color: DesignTokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
