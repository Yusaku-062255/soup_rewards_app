import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/models/transaction_model.dart';
import '../../../../features/points/domain/models/rank.dart';
import '../../../../core/repositories/transaction_repository.dart';
import '../../data/repositories/admin_user_repository.dart';

/// 会員検索＆詳細画面
class MembersAdminPage extends ConsumerStatefulWidget {
  const MembersAdminPage({super.key});

  @override
  ConsumerState<MembersAdminPage> createState() => _MembersAdminPageState();
}

class _MembersAdminPageState extends ConsumerState<MembersAdminPage> {
  final _memberIdController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _adminUserRepository = AdminUserRepository();
  final _transactionRepository = TransactionRepository();

  List<UserModel> _searchResults = [];
  UserModel? _selectedMember;
  Rank? _selectedMemberRank;
  DateTime? _lastVisitDate;
  int _visitCount = 0;
  List<TransactionModel> _transactionHistory = [];
  bool _isSearching = false;
  bool _isLoadingDetail = false;

  @override
  void dispose() {
    _memberIdController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _searchMembers() async {
    setState(() {
      _isSearching = true;
      _searchResults = [];
      _selectedMember = null;
    });

    try {
      List<UserModel> results = [];

      // 会員IDで検索
      if (_memberIdController.text.trim().isNotEmpty) {
        final user = await _adminUserRepository.searchByMemberId(
          _memberIdController.text.trim(),
        );
        if (user != null) {
          results.add(user);
        }
      }

      // 名前で検索
      if (_nameController.text.trim().isNotEmpty) {
        final users = await _adminUserRepository.searchByName(
          _nameController.text.trim(),
        );
        results.addAll(users);
      }

      // 電話番号で検索
      if (_phoneController.text.trim().isNotEmpty) {
        final users = await _adminUserRepository.searchByPhoneNumber(
          _phoneController.text.trim(),
        );
        results.addAll(users);
      }

      // 重複を除去
      final uniqueResults = <String, UserModel>{};
      for (var user in results) {
        uniqueResults[user.id] = user;
      }

      setState(() {
        _searchResults = uniqueResults.values.toList();
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('検索エラー: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _loadMemberDetail(UserModel member) async {
    setState(() {
      _isLoadingDetail = true;
      _selectedMember = member;
      _selectedMemberRank = RankCalculator.calculate(member.points);
    });

    try {
      // 最終来店日を取得
      final lastVisit = await _adminUserRepository.getLastVisitDate(member.id);

      // 累計来店回数を取得
      final visitCount =
          await _adminUserRepository.getTotalVisitCount(member.id);

      // 取引履歴を取得（直近10件）
      final transactions = await _transactionRepository.getUserTransactions(
        member.id,
        limit: 10,
      );

      setState(() {
        _lastVisitDate = lastVisit;
        _visitCount = visitCount;
        _transactionHistory = transactions;
        _isLoadingDetail = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingDetail = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('詳細情報の取得に失敗しました: $e'),
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
        title: const Text('会員検索'),
        backgroundColor: AppColors.white,
        elevation: 0,
      ),
      body: Row(
        children: [
          // 左側: 検索フォーム + 検索結果
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 検索フォーム
                  _buildSearchForm(),
                  const SizedBox(height: 24),

                  // 検索結果
                  _buildSearchResults(),
                ],
              ),
            ),
          ),

          // 右側: 会員詳細
          if (_selectedMember != null)
            Expanded(
              flex: 1,
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.grey50,
                  border: Border(
                    left: BorderSide(
                      color: AppColors.grey200,
                      width: 1,
                    ),
                  ),
                ),
                child: _buildMemberDetail(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '検索条件',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _memberIdController,
              decoration: InputDecoration(
                labelText: '会員ID（6桁）',
                hintText: '000001',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: '名前（部分一致）',
                hintText: '山田',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: '電話番号',
                hintText: '090-1234-5678',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSearching ? null : _searchMembers,
                icon: _isSearching
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
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '検索結果 (${_searchResults.length}件)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        ..._searchResults.map((member) {
          final rank = RankCalculator.calculate(member.points);
          final memberId = _getMemberId(member);

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(member.name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ID: $memberId'),
                  Text('ランク: ${RankCalculator.label(rank)}'),
                  Text('ポイント: ${member.points}P'),
                ],
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _loadMemberDetail(member),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMemberDetail() {
    if (_isLoadingDetail) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final member = _selectedMember!;
    final rank = _selectedMemberRank!;
    final memberId = _getMemberId(member);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '会員詳細',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),

          // 基本情報カード
          _buildBasicInfoCard(member, memberId),
          const SizedBox(height: 16),

          // ポイント・ランク情報カード
          _buildPointsInfoCard(member, rank),
          const SizedBox(height: 16),

          // 来店情報カード
          _buildVisitInfoCard(),
          const SizedBox(height: 16),

          // 取引履歴
          _buildTransactionHistory(),
        ],
      ),
    );
  }

  Widget _buildBasicInfoCard(UserModel member, String memberId) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '基本情報',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('会員ID', memberId),
            const Divider(),
            _buildDetailRow('名前', member.name),
            const Divider(),
            _buildDetailRow('メールアドレス', member.email),
            if (member.phoneNumber != null) ...[
              const Divider(),
              _buildDetailRow('電話番号', member.phoneNumber!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPointsInfoCard(UserModel member, Rank rank) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ポイント・ランク情報',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('ランク', RankCalculator.label(rank)),
            const Divider(),
            _buildDetailRow('現在ポイント', '${member.points}P'),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '来店情報',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              '累計利用回数',
              _visitCount > 0 ? '$_visitCount回' : 'データなし',
            ),
            const Divider(),
            _buildDetailRow(
              '最終来店日',
              _lastVisitDate != null
                  ? '${_lastVisitDate!.year}/${_lastVisitDate!.month}/${_lastVisitDate!.day} '
                      '${_lastVisitDate!.hour}:${_lastVisitDate!.minute.toString().padLeft(2, '0')}'
                  : 'データなし',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ポイント履歴（直近10件）',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        if (_transactionHistory.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Text(
                  '取引履歴がありません',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ),
            ),
          )
        else
          ..._transactionHistory.map((transaction) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: transaction.type == TransactionType.earn
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    transaction.type == TransactionType.earn
                        ? Icons.add
                        : Icons.remove,
                    color: transaction.type == TransactionType.earn
                        ? AppColors.success
                        : AppColors.error,
                  ),
                ),
                title: Text(transaction.description),
                subtitle: Text(
                  '${transaction.timestamp.year}/${transaction.timestamp.month}/${transaction.timestamp.day} '
                  '${transaction.timestamp.hour}:${transaction.timestamp.minute.toString().padLeft(2, '0')}',
                ),
                trailing: Text(
                  '${transaction.type == TransactionType.earn ? '+' : '-'}${transaction.points}P',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: transaction.type == TransactionType.earn
                            ? AppColors.success
                            : AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  /// 会員IDを取得（6桁表示用）
  String _getMemberId(UserModel member) {
    // TODO: 実際の会員IDフォーマットに合わせて調整
    // 現時点では、usersコレクションのmemberIdフィールドを優先的に使用
    // memberIdフィールドが存在しない場合は、userIdの末尾6桁を表示

    // Firestoreから直接取得する必要があるため、現時点ではuserIdの末尾6桁を使用
    if (member.id.length >= 6) {
      return member.id.substring(member.id.length - 6);
    }
    return member.id.padLeft(6, '0');
  }
}
