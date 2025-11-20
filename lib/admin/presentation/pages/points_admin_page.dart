import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/models/user_model.dart';
import '../../../../features/points/domain/models/rank.dart';
import '../../domain/models/service_menu.dart';
import '../../data/repositories/admin_user_repository.dart';
import '../../data/repositories/admin_points_repository.dart';

/// ポイント付与画面
class PointsAdminPage extends ConsumerStatefulWidget {
  const PointsAdminPage({super.key});

  @override
  ConsumerState<PointsAdminPage> createState() => _PointsAdminPageState();
}

class _PointsAdminPageState extends ConsumerState<PointsAdminPage> {
  final _memberIdController = TextEditingController();
  final _adminUserRepository = AdminUserRepository();
  final _adminPointsRepository = AdminPointsRepository();
  
  UserModel? _selectedUser;
  Rank? _currentRank;
  ServiceMenu? _selectedMenu;
  bool _isLoading = false;
  bool _isGranting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _memberIdController.dispose();
    super.dispose();
  }

  Future<void> _searchMember() async {
    final memberId = _memberIdController.text.trim();
    
    if (memberId.isEmpty) {
      setState(() {
        _errorMessage = '会員IDを入力してください';
        _selectedUser = null;
        _currentRank = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _selectedUser = null;
      _currentRank = null;
      _selectedMenu = null;
    });

    try {
      final user = await _adminUserRepository.searchByMemberId(memberId);
      
      if (user == null) {
        setState(() {
          _errorMessage = '会員が見つかりませんでした';
          _isLoading = false;
        });
        return;
      }

      final rank = RankCalculator.calculate(user.points);
      
      setState(() {
        _selectedUser = user;
        _currentRank = rank;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '検索エラー: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _grantPoints() async {
    if (_selectedUser == null || _selectedMenu == null) {
      return;
    }

    setState(() {
      _isGranting = true;
      _errorMessage = null;
    });

    try {
      await _adminPointsRepository.grantPoints(
        userId: _selectedUser!.id,
        points: _selectedMenu!.points,
        description: _selectedMenu!.name,
      );

      // ユーザー情報を再取得
      final updatedUser = await _adminUserRepository.getUser(_selectedUser!.id);
      final updatedRank = updatedUser != null
          ? RankCalculator.calculate(updatedUser.points)
          : null;

      setState(() {
        _selectedUser = updatedUser;
        _currentRank = updatedRank;
        _isGranting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedMenu!.name}のポイント（${_selectedMenu!.points}P）を付与しました'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'ポイント付与エラー: $e';
        _isGranting = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ポイント付与に失敗しました: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ポイント付与'),
        backgroundColor: AppColors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 会員ID検索セクション
                _buildSearchSection(),
                const SizedBox(height: 24),
                
                // エラーメッセージ
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // 会員情報表示
                if (_selectedUser != null && _currentRank != null)
                  _buildMemberCard(),
                
                // メニュー選択
                if (_selectedUser != null)
                  _buildMenuSelection(),
                
                // ポイント付与ボタン
                if (_selectedUser != null && _selectedMenu != null)
                  _buildGrantButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '会員検索',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _memberIdController,
                    decoration: InputDecoration(
                      labelText: '会員ID（6桁）',
                      hintText: '000001',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    enabled: !_isLoading,
                    onSubmitted: (_) => _searchMember(),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _searchMember,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.search),
                  label: const Text('検索'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 24,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberCard() {
    final memberId = _selectedUser!.id.length >= 6
        ? _selectedUser!.id.substring(_selectedUser!.id.length - 6)
        : _selectedUser!.id.padLeft(6, '0');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '会員情報',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem('会員ID', memberId),
                ),
                Expanded(
                  child: _buildInfoItem('現在ポイント', '${_selectedUser!.points}P'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem('ランク', RankCalculator.label(_currentRank!)),
                ),
                Expanded(
                  child: _buildInfoItem('名前', _selectedUser!.name),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'サービスメニュー',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: ServiceMenu.availableMenus.map((menu) {
                final isSelected = _selectedMenu?.id == menu.id;
                return ChoiceChip(
                  label: Text('${menu.name}\n+${menu.points}P'),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedMenu = selected ? menu : null;
                    });
                  },
                  selectedColor: AppColors.primary.withValues(alpha: 0.2),
                  checkmarkColor: AppColors.primary,
                );
              }).toList(),
            ),
            if (_selectedMenu != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.grey50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '付与予定ポイント',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          '+${_selectedMenu!.points}P',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '付与後ポイント',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_selectedUser!.points + _selectedMenu!.points}P',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGrantButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: ElevatedButton.icon(
        onPressed: _isGranting ? null : _grantPoints,
        icon: _isGranting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                ),
              )
            : const Icon(Icons.check_circle),
        label: Text(_isGranting ? '付与中...' : 'ポイントを付与する'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

