import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_colors.dart';

/// 予約一覧画面
class ReservationsAdminPage extends StatefulWidget {
  const ReservationsAdminPage({super.key});

  @override
  State<ReservationsAdminPage> createState() => _ReservationsAdminPageState();
}

class _ReservationsAdminPageState extends State<ReservationsAdminPage> {
  String _selectedFilter = 'today'; // today, week, all
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('予約一覧'),
        backgroundColor: AppColors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // フィルターセクション
          _buildFilterSection(),
          
          // 予約一覧
          Expanded(
            child: _buildReservationList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(
            color: AppColors.grey200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // フィルターボタン
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'today',
                label: Text('今日'),
              ),
              ButtonSegment(
                value: 'week',
                label: Text('今週'),
              ),
              ButtonSegment(
                value: 'all',
                label: Text('全て'),
              ),
            ],
            selected: {_selectedFilter},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() {
                _selectedFilter = newSelection.first;
              });
            },
          ),
          const SizedBox(width: 16),
          // 日付ピッカー
          OutlinedButton.icon(
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (date != null) {
                setState(() {
                  _selectedDate = date;
                });
              }
            },
            icon: const Icon(Icons.calendar_today),
            label: Text(
              _selectedDate != null
                  ? '${_selectedDate!.year}/${_selectedDate!.month}/${_selectedDate!.day}'
                  : '日付を選択',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationList() {
    // Firestoreから予約データを取得
    return StreamBuilder<QuerySnapshot>(
      stream: _getReservationsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                Text(
                  '予約データの取得に失敗しました',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        final reservations = snapshot.data?.docs ?? [];

        if (reservations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 64,
                  color: AppColors.grey400,
                ),
                const SizedBox(height: 16),
                Text(
                  '予約がありません',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reservations.length,
          itemBuilder: (context, index) {
            final doc = reservations[index];
            final data = doc.data() as Map<String, dynamic>;
            
            return _buildReservationCard(doc.id, data);
          },
        );
      },
    );
  }

  /// Firestoreから予約データを取得するStream
  Stream<QuerySnapshot> _getReservationsStream() {
    Query query = FirebaseFirestore.instance
        .collection('reservations')
        .orderBy('scheduledDate', descending: false);

    // フィルターに応じてクエリを調整
    final now = DateTime.now();
    
    switch (_selectedFilter) {
      case 'today':
        final startOfDay = DateTime(now.year, now.month, now.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));
        query = query
            .where('scheduledDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where('scheduledDate', isLessThan: Timestamp.fromDate(endOfDay));
        break;
      case 'week':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final startOfWeekDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        final endOfWeek = startOfWeekDate.add(const Duration(days: 7));
        query = query
            .where('scheduledDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeekDate))
            .where('scheduledDate', isLessThan: Timestamp.fromDate(endOfWeek));
        break;
      case 'all':
        // フィルターなし（全件取得）
        break;
    }

    // 日付ピッカーで選択された日付がある場合
    if (_selectedDate != null) {
      final startOfSelectedDay = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
      );
      final endOfSelectedDay = startOfSelectedDay.add(const Duration(days: 1));
      query = query
          .where('scheduledDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfSelectedDay))
          .where('scheduledDate', isLessThan: Timestamp.fromDate(endOfSelectedDay));
    }

    return query.snapshots();
  }

  Widget _buildReservationCard(String reservationId, Map<String, dynamic> data) {
    final scheduledDate = (data['scheduledDate'] as Timestamp?)?.toDate() ?? DateTime.now();
    final name = data['name'] as String? ?? '名前不明';
    final menu = data['menu'] as String? ?? 'メニュー不明';
    final status = data['status'] as String? ?? '予約';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 60,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${scheduledDate.hour.toString().padLeft(2, '0')}:${scheduledDate.minute.toString().padLeft(2, '0')}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        title: Text(
          name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(menu),
            const SizedBox(height: 4),
            Text(
              '${scheduledDate.year}/${scheduledDate.month}/${scheduledDate.day}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: _getStatusColor(status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _getStatusColor(status),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                // TODO: ステータス更新機能を実装
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('ステータス更新機能は準備中です'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case '予約':
        return AppColors.info;
      case '施工中':
        return AppColors.warning;
      case '完了':
        return AppColors.success;
      case 'キャンセル':
        return AppColors.error;
      default:
        return AppColors.grey400;
    }
  }
}
