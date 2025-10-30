import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/booking.dart';
import '../booking_provider.dart';
import '../widgets/booking_card.dart';
import 'create_booking_page.dart';

/// 予約管理ページ
class BookingPage extends ConsumerWidget {
  const BookingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(bookingsProvider);

    return Container(
      color: AppColors.white,
      child: Column(
        children: [
          // 予約追加ボタン
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CreateBookingPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('新しい予約を作成'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),

          // 予約リスト
          Expanded(
            child: bookingsAsync.when(
                    data: (bookings) {
                      if (bookings.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.event_available,
                                size: 80,
                                color: AppColors.grey400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '予約がありません',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: AppColors.textSub,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const CreateBookingPage(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('予約を作成'),
                              ),
                            ],
                          ),
                        );
                      }

                      // 今後の予約と過去の予約に分ける
                      final upcoming = bookings
                          .where((b) => b.isFuture && b.status != BookingStatus.cancelled)
                          .toList();
                      final past = bookings
                          .where((b) => b.isPast || b.status == BookingStatus.cancelled)
                          .toList();

                      return DefaultTabController(
                        length: 2,
                        child: Column(
                          children: [
                            const TabBar(
                              labelColor: AppColors.primary,
                              tabs: [
                                Tab(text: '今後の予約'),
                                Tab(text: '過去の予約'),
                              ],
                            ),
                            Expanded(
                              child: TabBarView(
                                children: [
                                  // 今後の予約
                                  _buildBookingList(context, upcoming, true),
                                  // 過去の予約
                                  _buildBookingList(context, past, false),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (error, _) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: AppColors.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'データの読み込みに失敗しました',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: AppColors.error,
                                ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingList(
    BuildContext context,
    List<Booking> bookings,
    bool isUpcoming,
  ) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUpcoming ? Icons.event_available : Icons.history,
              size: 64,
              color: AppColors.grey400,
            ),
            const SizedBox(height: 16),
            Text(
              isUpcoming ? '今後の予約がありません' : '過去の予約がありません',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSub,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: BookingCard(
            booking: booking,
            onTap: () {
              // TODO: 予約詳細ページへ遷移
            },
          ),
        );
      },
    );
  }
}
