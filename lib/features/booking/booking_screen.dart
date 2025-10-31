import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../design/theme.dart';
import '../../design/widgets/soup_card.dart';
import '../../design/widgets/soup_badge_icon.dart';
import '../../design/widgets/soup_section_title.dart';
import 'booking_repository.dart';
import 'booking_models.dart';

final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());
final selectedSlotProvider = StateProvider<TimeSlot?>((ref) => null);

class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to make a booking.'),
        ),
      );
    }

    final selectedDate = ref.watch(selectedDateProvider);
    final selectedSlot = ref.watch(selectedSlotProvider);

    return Scaffold(
      backgroundColor: DesignTokens.surface,
      appBar: AppBar(
        title: const Text('予約'),
        backgroundColor: DesignTokens.primary,
        foregroundColor: DesignTokens.onPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Wave background header
            _buildWaveHeader(),

            Padding(
              padding: const EdgeInsets.all(DesignTokens.spaceBase),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Date picker
                  const SoupSectionTitle(title: '日付を選択'),
                  _buildDatePicker(context, selectedDate),
                  const SizedBox(height: DesignTokens.spaceSection),

                  // Time slots
                  const SoupSectionTitle(title: '時間を選択'),
                  _buildTimeSlots(selectedDate, selectedSlot),
                  const SizedBox(height: DesignTokens.spaceSection),

                  // Confirm button
                  if (selectedSlot != null)
                    ElevatedButton(
                      onPressed: _isLoading ? null : () => _confirmBooking(context, user.uid, selectedDate, selectedSlot),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('予約を確定する'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaveHeader() {
    return Container(
      height: 120,
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
      child: CustomPaint(
        painter: WavePainter(),
        child: const Center(
          child: Icon(
            CupertinoIcons.calendar_circle,
            size: 48,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context, DateTime selectedDate) {
    return SoupCard(
      onTap: () => _showDatePicker(context),
      child: Row(
        children: [
          const Icon(CupertinoIcons.calendar, color: DesignTokens.primary),
          const SizedBox(width: DesignTokens.spaceBase),
          Text(
            '${selectedDate.year}年${selectedDate.month}月${selectedDate.day}日',
            style: const TextStyle(
              fontSize: DesignTokens.fontSizeBody,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          const Icon(CupertinoIcons.chevron_right, size: 20),
        ],
      ),
    );
  }

  Widget _buildTimeSlots(DateTime selectedDate, TimeSlot? selectedSlot) {
    final bookingRepo = ref.watch(bookingRepositoryProvider);

    return FutureBuilder<List<TimeSlot>>(
      future: bookingRepo.fetchSlots(selectedDate),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return SoupCard(
            child: Text('エラー: ${snapshot.error}'),
          );
        }

        final slots = snapshot.data ?? [];
        if (slots.isEmpty) {
          return const SoupCard(
            child: Text('この日は予約枠がありません'),
          );
        }

        return Wrap(
          spacing: DesignTokens.spaceSmall,
          runSpacing: DesignTokens.spaceSmall,
          children: slots.map((slot) {
            final isSelected = selectedSlot?.slotId == slot.slotId;
            return _buildSlotChip(slot, isSelected);
          }).toList(),
        );
      },
    );
  }

  Widget _buildSlotChip(TimeSlot slot, bool isSelected) {
    final color = slot.isFull
        ? DesignTokens.textSecondary
        : isSelected
            ? DesignTokens.primary
            : DesignTokens.textPrimary;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            slot.slotId.padLeft(4, '0'),
            style: TextStyle(color: isSelected ? Colors.white : color),
          ),
          const SizedBox(width: 4),
          Text(
            '(${slot.availableCount}/${slot.capacity})',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeSmall,
              color: isSelected ? Colors.white : DesignTokens.textSecondary,
            ),
          ),
        ],
      ),
      selected: isSelected,
      onSelected: slot.isFull
          ? null
          : (selected) {
              ref.read(selectedSlotProvider.notifier).state = selected ? slot : null;
            },
      backgroundColor: DesignTokens.card,
      selectedColor: DesignTokens.primary,
      checkmarkColor: Colors.white,
    );
  }

  Future<void> _showDatePicker(BuildContext context) async {
    final now = DateTime.now();
    final selectedDate = ref.read(selectedDateProvider);

    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return SizedBox(
          height: 300,
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.date,
            initialDateTime: selectedDate,
            minimumDate: now,
            maximumDate: now.add(const Duration(days: 30)),
            onDateTimeChanged: (date) {
              ref.read(selectedDateProvider.notifier).state = date;
              ref.read(selectedSlotProvider.notifier).state = null;
            },
          ),
        );
      },
    );
  }

  Future<void> _confirmBooking(BuildContext context, String userId, DateTime date, TimeSlot slot) async {
    setState(() => _isLoading = true);

    try {
      final bookingRepo = ref.read(bookingRepositoryProvider);
      await bookingRepo.createBooking(
        date: date,
        slotId: slot.slotId,
        serviceType: 'wash',
        vehicleId: 'defaultVehicle',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('予約が完了しました！ +50ポイント獲得'),
            backgroundColor: DesignTokens.success,
          ),
        );

        // Reset selection
        ref.read(selectedSlotProvider.notifier).state = null;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('予約に失敗しました: $e'),
            backgroundColor: DesignTokens.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.85,
      size.width * 0.5,
      size.height * 0.7,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.55,
      size.width,
      size.height * 0.7,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
