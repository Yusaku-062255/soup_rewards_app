import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/vehicle.dart';
import '../maintenance_provider.dart';

/// 車両追加ページ
class AddVehiclePage extends ConsumerStatefulWidget {
  const AddVehiclePage({super.key});

  @override
  ConsumerState<AddVehiclePage> createState() => _AddVehiclePageState();
}

class _AddVehiclePageState extends ConsumerState<AddVehiclePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _licensePlateController = TextEditingController();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  DateTime? _coatedAt;
  int _intervalMonths = 12;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _licensePlateController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  Future<void> _selectCoatedDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _coatedAt ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _coatedAt) {
      setState(() {
        _coatedAt = picked;
      });
    }
  }

  Future<void> _saveVehicle() async {
    if (!_formKey.currentState!.validate()) return;
    if (_coatedAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('施工日を選択してください')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final nextMaintenanceAt = DateTime(
        _coatedAt!.year,
        _coatedAt!.month + _intervalMonths,
        _coatedAt!.day,
      );

      final vehicle = Vehicle(
        id: '', // Will be set by Firestore
        name: _nameController.text.trim(),
        licensePlate: _licensePlateController.text.trim().isNotEmpty
            ? _licensePlateController.text.trim()
            : null,
        make: _makeController.text.trim().isNotEmpty
            ? _makeController.text.trim()
            : null,
        model: _modelController.text.trim().isNotEmpty
            ? _modelController.text.trim()
            : null,
        coatedAt: _coatedAt!,
        intervalMonths: _intervalMonths,
        nextMaintenanceAt: nextMaintenanceAt,
        createdAt: DateTime.now(),
      );

      final repository = ref.read(maintenanceRepositoryProvider);
      await repository.addVehicle(vehicle);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('車両を登録しました')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラーが発生しました: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('車両登録'),
        backgroundColor: AppColors.maintenance,
        foregroundColor: AppColors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 車両名
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '車両名 *',
                  hintText: '例: マイカー',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '車両名を入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ナンバープレート
              TextFormField(
                controller: _licensePlateController,
                decoration: const InputDecoration(
                  labelText: 'ナンバープレート',
                  hintText: '例: 品川 500 あ 12-34',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // メーカー・モデル
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _makeController,
                      decoration: const InputDecoration(
                        labelText: 'メーカー',
                        hintText: '例: トヨタ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _modelController,
                      decoration: const InputDecoration(
                        labelText: 'モデル',
                        hintText: '例: プリウス',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 施工日
              InkWell(
                onTap: () => _selectCoatedDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'コーティング施工日 *',
                    border: OutlineInputBorder(),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _coatedAt == null
                            ? '日付を選択'
                            : '${_coatedAt!.year}年${_coatedAt!.month}月${_coatedAt!.day}日',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // メンテナンス間隔
              DropdownButtonFormField<int>(
                value: _intervalMonths,
                decoration: const InputDecoration(
                  labelText: 'メンテナンス間隔',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 6, child: Text('6ヶ月')),
                  DropdownMenuItem(value: 12, child: Text('12ヶ月')),
                  DropdownMenuItem(value: 18, child: Text('18ヶ月')),
                  DropdownMenuItem(value: 24, child: Text('24ヶ月')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _intervalMonths = value);
                  }
                },
              ),
              const SizedBox(height: 24),

              // 保存ボタン
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : _saveVehicle,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.maintenance,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(AppColors.white),
                          ),
                        )
                      : const Text('登録する'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
