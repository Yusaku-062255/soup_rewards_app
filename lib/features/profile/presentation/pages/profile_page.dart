import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/models/user_model.dart';
import '../../../../features/points/domain/models/rank.dart';
import '../../../auth/presentation/pages/login_page.dart';

/// マイページ
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);
    final currentUser = authState.value;
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('マイページ'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textMain,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ゲスト利用中 / ログイン済み表示
              userAsync.when(
                data: (user) => _buildUserInfoCard(context, user),
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (_, __) => _buildGuestCard(context),
              ),
              const SizedBox(height: 24),

              // ログイン / ログアウトボタン
              if (currentUser == null)
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.login),
                  label: const Text('ログイン / 会員登録'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                )
              else
                OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      await ref.read(authStateProvider.notifier).signOut();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('ログアウトしました'),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('ログアウトに失敗しました: $e'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('ログアウト'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // 会員情報詳細（ログイン済みの場合）
              if (currentUser != null)
                userAsync.when(
                  data: (user) => user != null
                      ? _buildMemberDetailsCard(context, user)
                      : const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),

              const SizedBox(height: 24),

              // 会員特典の説明
              _buildBenefitsCard(context, currentUser != null),
            ],
          ),
        ),
      ),
    );
  }

  /// ユーザー情報カード（ログイン済み）
  Widget _buildUserInfoCard(BuildContext context, UserModel? user) {
    if (user == null) {
      return _buildGuestCard(context);
    }

    final memberId = user.memberId ?? _getFallbackMemberId(user.id);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              size: 48,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user.name,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            user.email,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '会員ID: $memberId',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ゲストカード
  Widget _buildGuestCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.grey200,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.person_outline,
            size: 48,
            color: AppColors.grey400,
          ),
          const SizedBox(height: 12),
          Text(
            '現在：ゲスト利用中',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// 会員詳細情報カード
  Widget _buildMemberDetailsCard(BuildContext context, UserModel user) {
    final rank = RankCalculator.calculate(user.points);
    final memberId = user.memberId ?? _getFallbackMemberId(user.id);

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
            _buildDetailRow(context, '会員ID', memberId),
            const Divider(),
            _buildDetailRow(context, 'ランク', RankCalculator.labelJa(rank)),
            const Divider(),
            _buildDetailRow(context, '現在ポイント', '${user.points}P'),
            if (user.phoneNumber != null) ...[
              const Divider(),
              _buildDetailRow(context, '電話番号', user.phoneNumber!),
            ],
          ],
        ),
      ),
    );
  }

  /// 会員特典カード
  Widget _buildBenefitsCard(BuildContext context, bool isLoggedIn) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.stars,
                color: isLoggedIn ? AppColors.secondary : AppColors.grey400,
              ),
              const SizedBox(width: 8),
              Text(
                isLoggedIn ? '会員特典' : '会員登録すると',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isLoggedIn
                ? '• 給油券・ランク特典が使える\n'
                    '• ポイント履歴を確認できる\n'
                    '• クーポンを管理できる'
                : '• 給油券・ランク特典が使える\n'
                    '• ポイント履歴を確認できる\n'
                    '• クーポンを管理できる\n'
                    '• ポイントをクラウドに保存して、機種変更後も引き継げます',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  /// 詳細行を構築
  Widget _buildDetailRow(BuildContext context, String label, String value) {
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

  /// フォールバック会員IDを取得（memberIdが未設定の場合）
  String _getFallbackMemberId(String userId) {
    // userIdの末尾6桁を使用（暫定）
    if (userId.length >= 6) {
      return userId.substring(userId.length - 6);
    }
    return userId.padLeft(6, '0');
  }
}
