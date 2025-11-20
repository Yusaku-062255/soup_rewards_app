import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../admin/domain/models/service_menu.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../domain/reservation_model.dart';

/// 予約ページ
class ReservationsPage extends ConsumerStatefulWidget {
  const ReservationsPage({super.key});

  @override
  ConsumerState<ReservationsPage> createState() => _ReservationsPageState();
}

class _ReservationsPageState extends ConsumerState<ReservationsPage> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  String? _selectedMenu;
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day);
    final lastDate = DateTime(now.year + 1, 12, 31);

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? firstDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: '希望日を選択',
      cancelText: 'キャンセル',
      confirmText: '決定',
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitReservation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDate == null || _selectedTimeSlot == null || _selectedMenu == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('日付、時間帯、メニューを選択してください'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final repository = ref.read(reservationsRepositoryProvider);
      final input = ReservationInput(
        scheduledDate: _selectedDate!,
        timeSlot: _selectedTimeSlot!,
        menu: _selectedMenu!,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      await repository.createReservation(input);

      if (mounted) {
        // 成功メッセージ
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('予約リクエストを受け付けました'),
            content: const Text(
              '予約リクエストを受け付けました。\n'
              'スタッフからの確認連絡をお待ちください。',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // フォームをリセット
                  setState(() {
                    _selectedDate = null;
                    _selectedTimeSlot = null;
                    _selectedMenu = null;
                    _notesController.clear();
                  });
                  _formKey.currentState?.reset();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                ),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // エラーの内容に応じて、ユーザーフレンドリーなメッセージを表示
        String errorMessage = '予約リクエストの送信に失敗しました';
        String errorDetail = e.toString();

        if (errorDetail.contains('ユーザー情報が見つかりませんでした')) {
          errorMessage = '会員情報が見つかりませんでした。再度ログインしてください。';
        } else if (errorDetail.contains('ネットワーク') || errorDetail.contains('network')) {
          errorMessage = 'ネットワーク接続エラー。通信状況を確認してください。';
        } else if (errorDetail.contains('permission') || errorDetail.contains('権限')) {
          errorMessage = '予約を作成する権限がありません。管理者にお問い合わせください。';
        }

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error_outline, color: AppColors.error),
                SizedBox(width: 8),
                Text('送信エラー'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  errorMessage,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '詳細情報:',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  errorDetail,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('閉じる'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // 再試行
                  _submitReservation();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                ),
                child: const Text('再試行'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateChangesProvider);
    final isGuest = authState.value == null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('予約'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textMain,
        elevation: 0,
      ),
      body: SafeArea(
        child: isGuest ? _buildGuestView() : _buildReservationForm(),
      ),
    );
  }

  /// ゲスト表示（未ログイン時）
  Widget _buildGuestView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.grey200,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 48,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'アプリから予約リクエストを送信するには\n会員登録が必要です。',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.login),
                  label: const Text('ログイン / 新規登録'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 予約フォーム（ログイン済み時）
  Widget _buildReservationForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 予約フォーム
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '予約リクエスト',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // 日付選択
                    TextFormField(
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: '希望日 *',
                        hintText: '日付を選択',
                        prefixIcon: const Icon(Icons.calendar_today),
                        suffixIcon: const Icon(Icons.arrow_drop_down),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      controller: TextEditingController(
                        text: _selectedDate != null
                            ? '${_selectedDate!.year}年${_selectedDate!.month}月${_selectedDate!.day}日'
                            : null,
                      ),
                      onTap: _selectDate,
                      validator: (value) {
                        if (_selectedDate == null) {
                          return '日付を選択してください';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // 時間帯選択
                    DropdownButtonFormField<String>(
                      initialValue: _selectedTimeSlot,
                      decoration: InputDecoration(
                        labelText: '時間帯 *',
                        prefixIcon: const Icon(Icons.access_time),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: '午前',
                          child: Text('午前（9〜12時）'),
                        ),
                        DropdownMenuItem(
                          value: '午後',
                          child: Text('午後（12〜15時）'),
                        ),
                        DropdownMenuItem(
                          value: '夕方',
                          child: Text('夕方（15〜18時）'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedTimeSlot = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '時間帯を選択してください';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // メニュー選択
                    DropdownButtonFormField<String>(
                      initialValue: _selectedMenu,
                      decoration: InputDecoration(
                        labelText: 'メニュー *',
                        prefixIcon: const Icon(Icons.local_offer),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: ServiceMenu.availableMenus.map((menu) {
                        return DropdownMenuItem(
                          value: menu.name,
                          child: Text(menu.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedMenu = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'メニューを選択してください';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // メモ入力
                    TextFormField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: 'メモ（任意）',
                        hintText: '車種・ナンバー・気になる点など',
                        prefixIcon: const Icon(Icons.note_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    
                    // 送信ボタン
                    ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _submitReservation,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                              ),
                            )
                          : const Icon(Icons.send),
                      label: Text(_isSubmitting ? '送信中...' : '予約リクエストを送信する'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // 自分の予約一覧
            _buildMyReservationsList(),
          ],
        ),
      ),
    );
  }

  /// 自分の予約一覧
  Widget _buildMyReservationsList() {
    final repository = ref.watch(reservationsRepositoryProvider);
    final reservationsStream = repository.watchMyReservations();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'あなたの予約リクエスト',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<ReservationModel>>(
              stream: reservationsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            '予約データを読み込み中...',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.error_outline,
                              size: 48,
                              color: AppColors.error,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '予約データの読み込みに失敗しました',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'ネットワーク接続を確認してください',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              // StreamBuilderは自動的に再試行するため、単にsetStateで再描画を促す
                              setState(() {});
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('再試行'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.white,
                            ),
                          ),
                          if (snapshot.error != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Text(
                                '詳細: ${snapshot.error}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }

                final reservations = snapshot.data ?? [];

                if (reservations.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              color: AppColors.grey200,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.calendar_month_outlined,
                              size: 48,
                              color: AppColors.grey600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '予約リクエストはありません',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '上のフォームから予約リクエストを送信できます',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: reservations.length,
                  itemBuilder: (context, index) {
                    final reservation = reservations[index];
                    return _buildReservationCard(reservation);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 予約カード
  Widget _buildReservationCard(ReservationModel reservation) {
    final date = reservation.scheduledDate;
    final timeSlot = _getTimeSlotFromDateTime(date);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getStatusColor(reservation.status).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.calendar_today,
            color: _getStatusColor(reservation.status),
          ),
        ),
        title: Text(
          reservation.menu,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${date.year}年${date.month}月${date.day}日 $timeSlot',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(reservation.status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                reservation.status,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _getStatusColor(reservation.status),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 日時から時間帯を取得
  String _getTimeSlotFromDateTime(DateTime dateTime) {
    final hour = dateTime.hour;
    if (hour >= 9 && hour < 12) {
      return '午前';
    } else if (hour >= 12 && hour < 15) {
      return '午後';
    } else if (hour >= 15 && hour < 18) {
      return '夕方';
    }
    return '$hour時';
  }

  /// ステータスに応じた色を取得
  Color _getStatusColor(String status) {
    switch (status) {
      case '予約':
        return AppColors.primary;
      case '施工中':
        return AppColors.secondary;
      case '完了':
        return AppColors.success;
      case 'キャンセル':
        return AppColors.error;
      default:
        return AppColors.grey400;
    }
  }
}

