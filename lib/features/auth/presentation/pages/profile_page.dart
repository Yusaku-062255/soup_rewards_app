import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../design/theme.dart';
import '../../../../design/widgets/soup_card.dart';
import '../../data/repositories/auth_repository.dart';
import '../providers/auth_state_provider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _displayNameController = TextEditingController();
  bool _isLoading = false;
  bool _notificationsEnabled = true;

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appUserAsync = ref.watch(appUserProvider);

    return Scaffold(
      backgroundColor: DesignTokens.surface,
      appBar: AppBar(
        title: const Text('プロフィール'),
        backgroundColor: DesignTokens.card,
        elevation: 0,
      ),
      body: appUserAsync.when(
        data: (appUser) {
          if (appUser == null) {
            return const Center(
              child: Text('ログインしてください'),
            );
          }

          // 初回のみコントローラーに値をセット
          if (_displayNameController.text.isEmpty && appUser.displayName != null) {
            _displayNameController.text = appUser.displayName!;
          }
          _notificationsEnabled = appUser.notificationEnabled;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(DesignTokens.spaceSection),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // アカウント情報カード
                SoupCard(
                  child: Padding(
                    padding: const EdgeInsets.all(DesignTokens.spaceBase),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: DesignTokens.accentMint,
                              child: Text(
                                appUser.displayName?.substring(0, 1).toUpperCase() ?? 'G',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: DesignTokens.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: DesignTokens.spaceBase),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    appUser.displayName ?? 'ゲストユーザー',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: DesignTokens.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    appUser.isAnonymous ? '匿名アカウント' : appUser.email ?? '',
                                    style: const TextStyle(
                                      fontSize: DesignTokens.fontSizeSmall,
                                      color: DesignTokens.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: DesignTokens.spaceBase),
                        const Divider(),
                        const SizedBox(height: DesignTokens.spaceSmall),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              icon: CupertinoIcons.star_fill,
                              label: 'ポイント',
                              value: '${appUser.totalPoints}',
                            ),
                            _buildStatItem(
                              icon: CupertinoIcons.calendar,
                              label: '予約',
                              value: '${appUser.totalBookings}',
                            ),
                            _buildStatItem(
                              icon: CupertinoIcons.gift,
                              label: 'ガチャ',
                              value: '${appUser.totalGachaPlays}',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: DesignTokens.spaceSection),

                // 匿名アカウントの場合、リンク促進メッセージ
                if (appUser.isAnonymous) ...[
                  SoupCard(
                    child: Padding(
                      padding: const EdgeInsets.all(DesignTokens.spaceBase),
                      child: Column(
                        children: [
                          const Icon(
                            CupertinoIcons.exclamationmark_circle,
                            color: Colors.orange,
                            size: 32,
                          ),
                          const SizedBox(height: DesignTokens.spaceSmall),
                          const Text(
                            'アカウントをリンクしましょう',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: DesignTokens.textPrimary,
                            ),
                          ),
                          const SizedBox(height: DesignTokens.spaceSmall),
                          const Text(
                            'データを保護するため、Appleアカウントとリンクすることをおすすめします',
                            style: TextStyle(
                              fontSize: DesignTokens.fontSizeSmall,
                              color: DesignTokens.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: DesignTokens.spaceBase),
                          OutlinedButton.icon(
                            onPressed: _isLoading ? null : _linkWithApple,
                            icon: const Icon(CupertinoIcons.logo_apple),
                            label: const Text('Appleアカウントとリンク'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: DesignTokens.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spaceSection),
                ],

                // プロフィール編集
                SoupCard(
                  child: Padding(
                    padding: const EdgeInsets.all(DesignTokens.spaceBase),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'プロフィール編集',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: DesignTokens.textPrimary,
                          ),
                        ),
                        const SizedBox(height: DesignTokens.spaceBase),
                        TextField(
                          controller: _displayNameController,
                          decoration: const InputDecoration(
                            labelText: '表示名',
                            hintText: '名前を入力',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: DesignTokens.spaceBase),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _updateProfile,
                          icon: const Icon(CupertinoIcons.checkmark),
                          label: const Text('保存'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DesignTokens.primary,
                            foregroundColor: DesignTokens.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: DesignTokens.spaceSection),

                // 通知設定
                SoupCard(
                  child: Padding(
                    padding: const EdgeInsets.all(DesignTokens.spaceBase),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '通知設定',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: DesignTokens.textPrimary,
                          ),
                        ),
                        const SizedBox(height: DesignTokens.spaceSmall),
                        SwitchListTile(
                          value: _notificationsEnabled,
                          onChanged: _isLoading ? null : (value) async {
                            setState(() {
                              _notificationsEnabled = value;
                              _isLoading = true;
                            });
                            await _updateNotificationSettings(value);
                            if (mounted) {
                              setState(() => _isLoading = false);
                            }
                          },
                          title: const Text('プッシュ通知'),
                          subtitle: const Text('予約確認やポイント獲得のお知らせ'),
                          activeColor: DesignTokens.primary,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: DesignTokens.spaceSection),

                // ログアウト・削除
                SoupCard(
                  child: Padding(
                    padding: const EdgeInsets.all(DesignTokens.spaceBase),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _isLoading ? null : _signOut,
                          icon: const Icon(CupertinoIcons.arrow_right_square),
                          label: const Text('ログアウト'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: DesignTokens.textSecondary,
                          ),
                        ),
                        const SizedBox(height: DesignTokens.spaceSmall),
                        TextButton.icon(
                          onPressed: _isLoading ? null : _deleteAccount,
                          icon: const Icon(CupertinoIcons.delete),
                          label: const Text('アカウントを削除'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('エラー: $error'),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: DesignTokens.primary, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: DesignTokens.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: DesignTokens.fontSizeSmall,
            color: DesignTokens.textSecondary,
          ),
        ),
      ],
    );
  }

  Future<void> _linkWithApple() async {
    setState(() => _isLoading = true);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signInWithApple(link: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appleアカウントとリンクしました'),
            backgroundColor: DesignTokens.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('リンクに失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.updateProfile(displayName: _displayNameController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('プロフィールを更新しました'),
            backgroundColor: DesignTokens.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('更新に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateNotificationSettings(bool enabled) async {
    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.updateNotificationSettings(enabled: enabled);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(enabled ? '通知をONにしました' : '通知をOFFにしました'),
            backgroundColor: DesignTokens.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('更新に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _signOut() async {
    setState(() => _isLoading = true);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ログアウトしました'),
            backgroundColor: DesignTokens.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ログアウトに失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAccount() async {
    // 確認ダイアログ
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('アカウント削除'),
        content: const Text(
          'アカウントを削除します。30日間は復元可能ですが、それ以降は完全に削除されます。よろしいですか？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.deleteAccount();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('アカウントを削除しました（30日後に完全削除）'),
            backgroundColor: Colors.orange,
          ),
        );
        // ログアウト
        await authRepo.signOut();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('削除に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
