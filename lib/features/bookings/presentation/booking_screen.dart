import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/booking_repository.dart';
import '../domain/models/booking.dart';
import '../../common/design_tokens.dart';
import '../../common/soup_card.dart';

class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  static const String _centerId = 'default';

  String _serviceType = 'wash';
  DateTime _selectedDate = DateTime.now();
  bool _isLoadingSlots = false;
  List<Slot> _slots = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  Future<void> _loadSlots() async {
    setState(() {
      _isLoadingSlots = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(bookingRepositoryProvider);
      final dateStr = BookingRepository.formatDateYYYYMMDD(_selectedDate);
      final slots = await repo.listAvailableSlots(
        centerId: _centerId,
        date: dateStr,
        serviceType: _serviceType,
      );

      setState(() {
        _slots = slots;
        _isLoadingSlots = false;
      });
    } catch (error) {
      setState(() {
        _errorMessage = _getErrorMessage(error);
        _isLoadingSlots = false;
      });
    }
  }

  Future<void> _createBooking(Slot slot) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ログインが必要です')),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _BookingConfirmDialog(
        date: _selectedDate,
        slot: slot,
      ),
    );

    if (confirmed != true) return;

    try {
      final repo = ref.read(bookingRepositoryProvider);
      final dateStr = BookingRepository.formatDateYYYYMMDD(_selectedDate);
      await repo.createBooking(
        centerId: _centerId,
        slotId: slot.id,
        date: dateStr,
        serviceType: _serviceType,
      );

      if (!mounted) return;

      // Show success SnackBar with cross-promotion
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('予約が完了しました！50ptを獲得しました'),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: '給油券に交換',
            textColor: DesignTokens.accent,
            onPressed: () {
              Navigator.of(context).pushNamed('/coupons');
            },
          ),
        ),
      );

      // Reload slots to update availability
      _loadSlots();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_getErrorMessage(error))),
      );
    }
  }

  Future<void> _cancelBooking(Booking booking) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('予約をキャンセルしますか？'),
        content: Text('${booking.formattedDateTime} (${booking.serviceTypeLabel})'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('戻る'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: DesignTokens.error,
            ),
            child: const Text('キャンセルする'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final repo = ref.read(bookingRepositoryProvider);
      await repo.cancelBooking(bookingId: booking.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('予約をキャンセルしました')),
      );

      // Reload slots to update availability
      _loadSlots();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_getErrorMessage(error))),
      );
    }
  }

  String _getErrorMessage(Object error) {
    final errorString = error.toString();

    if (errorString.contains('auth_required')) {
      return 'ログインが必要です';
    } else if (errorString.contains('slot_not_found')) {
      return '選択したスロットが見つかりません';
    } else if (errorString.contains('slot_full')) {
      return 'このスロットは満席です';
    } else if (errorString.contains('invalid_date_format')) {
      return '日付形式が不正です';
    } else if (errorString.contains('past_date_not_allowed')) {
      return '過去の日付は選択できません';
    } else if (errorString.contains('date_too_far')) {
      return '14日以内の日付を選択してください';
    } else if (errorString.contains('booking_not_found')) {
      return '予約が見つかりません';
    } else if (errorString.contains('not_your_booking')) {
      return 'この予約をキャンセルする権限がありません';
    } else if (errorString.contains('already_cancelled')) {
      return 'この予約は既にキャンセルされています';
    } else if (errorString.contains('service_type_mismatch')) {
      return 'サービスタイプが一致しません';
    }

    return '予約処理に失敗しました';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('予約'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service type selector
            _ServiceTypeSelector(
              selectedType: _serviceType,
              onChanged: (type) {
                setState(() {
                  _serviceType = type;
                });
                _loadSlots();
              },
            ),
            const SizedBox(height: 24),

            // Date picker
            _DatePicker(
              selectedDate: _selectedDate,
              onDateChanged: (date) {
                setState(() {
                  _selectedDate = date;
                });
                _loadSlots();
              },
            ),
            const SizedBox(height: 24),

            // Available slots section
            Text(
              '空き状況',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),

            if (_isLoadingSlots)
              const Center(child: CircularProgressIndicator())
            else if (_errorMessage != null)
              SoupCard(
                backgroundColor: DesignTokens.error.withOpacity(0.1),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: DesignTokens.error),
                ),
              )
            else if (_slots.isEmpty)
              const SoupCard(
                child: Text('この日は予約枠がありません'),
              )
            else
              ..._slots.map((slot) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _SlotCard(
                      slot: slot,
                      onBook: () => _createBooking(slot),
                    ),
                  )),

            const SizedBox(height: 32),

            // My bookings section
            if (user != null) ...[
              Text(
                'マイ予約',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              _MyBookingsList(
                userId: user.uid,
                onCancel: _cancelBooking,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ServiceTypeSelector extends StatelessWidget {
  final String selectedType;
  final ValueChanged<String> onChanged;

  const _ServiceTypeSelector({
    required this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SoupCard(
      child: Row(
        children: [
          Expanded(
            child: _ServiceTypeButton(
              label: '洗車',
              type: 'wash',
              isSelected: selectedType == 'wash',
              onTap: () => onChanged('wash'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ServiceTypeButton(
              label: 'コーティング',
              type: 'coating',
              isSelected: selectedType == 'coating',
              onTap: () => onChanged('coating'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceTypeButton extends StatelessWidget {
  final String label;
  final String type;
  final bool isSelected;
  final VoidCallback onTap;

  const _ServiceTypeButton({
    required this.label,
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? DesignTokens.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? DesignTokens.primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? DesignTokens.primary : Colors.black87,
          ),
        ),
      ),
    );
  }
}

class _DatePicker extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  const _DatePicker({
    required this.selectedDate,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SoupCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '予約日',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final now = DateTime.now();
              final firstDate = now;
              final lastDate = now.add(const Duration(days: 14));

              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: firstDate,
                lastDate: lastDate,
                locale: const Locale('ja', 'JP'),
              );

              if (picked != null) {
                onDateChanged(picked);
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(selectedDate),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Icon(Icons.calendar_today, color: DesignTokens.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }
}

class _SlotCard extends StatelessWidget {
  final Slot slot;
  final VoidCallback onBook;

  const _SlotCard({
    required this.slot,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    return SoupCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slot.time,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '残り ${slot.available}/${slot.capacity}',
                  style: TextStyle(
                    fontSize: 14,
                    color: slot.isAvailable ? DesignTokens.success : DesignTokens.error,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: slot.isAvailable ? onBook : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              disabledForegroundColor: Colors.grey.shade600,
            ),
            child: Text(slot.isAvailable ? '予約する' : '満席'),
          ),
        ],
      ),
    );
  }
}

class _BookingConfirmDialog extends StatelessWidget {
  final DateTime date;
  final Slot slot;

  const _BookingConfirmDialog({
    required this.date,
    required this.slot,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('予約確認'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('サービス: ${slot.serviceTypeLabel}'),
          const SizedBox(height: 8),
          Text('日時: ${_formatDate(date)} ${slot.time}'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DesignTokens.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.stars, color: DesignTokens.success),
                SizedBox(width: 8),
                Text(
                  '予約完了で50ptを獲得！',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: DesignTokens.success,
                  ),
                ),
              ],
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
            backgroundColor: DesignTokens.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('予約する'),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }
}

class _MyBookingsList extends ConsumerWidget {
  final String userId;
  final Function(Booking) onCancel;

  const _MyBookingsList({
    required this.userId,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(bookingRepositoryProvider);

    return StreamBuilder<List<Booking>>(
      stream: repo.userBookings(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return SoupCard(
            backgroundColor: DesignTokens.error.withOpacity(0.1),
            child: Text(
              '予約の取得に失敗しました',
              style: TextStyle(color: DesignTokens.error),
            ),
          );
        }

        final bookings = snapshot.data ?? [];

        if (bookings.isEmpty) {
          return const SoupCard(
            child: Text('予約はありません'),
          );
        }

        return Column(
          children: bookings.map((booking) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _BookingCard(
                booking: booking,
                onCancel: () => onCancel(booking),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback onCancel;

  const _BookingCard({
    required this.booking,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return SoupCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.serviceTypeLabel,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      booking.formattedDateTime,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: booking.status),
            ],
          ),
          if (booking.isConfirmed) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: DesignTokens.error,
                  side: BorderSide(color: DesignTokens.error),
                ),
                child: const Text('キャンセル'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor;
    final Color textColor;
    final String label;

    switch (status) {
      case 'confirmed':
        backgroundColor = DesignTokens.success.withOpacity(0.1);
        textColor = DesignTokens.success;
        label = '予約中';
        break;
      case 'cancelled':
        backgroundColor = Colors.grey.shade200;
        textColor = Colors.grey.shade700;
        label = 'キャンセル済';
        break;
      default:
        backgroundColor = Colors.grey.shade200;
        textColor = Colors.grey.shade700;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}
