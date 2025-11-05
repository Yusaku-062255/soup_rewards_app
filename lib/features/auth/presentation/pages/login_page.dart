import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../design/theme.dart';
import '../../data/repositories/auth_repository.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.spaceHeading),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo
              const Icon(
                CupertinoIcons.car_detailed,
                size: 80,
                color: DesignTokens.primary,
              ),
              const SizedBox(height: DesignTokens.spaceBase),
              const Text(
                'SOUP Rewards',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: DesignTokens.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: DesignTokens.spaceSmall),
              const Text(
                'カーケアポイントプログラム',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeBody,
                  color: DesignTokens.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: DesignTokens.spaceLarge * 2),

              // 匿名ログインボタン
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _signInAnonymously,
                icon: const Icon(CupertinoIcons.play_circle),
                label: const Text('今すぐ始める（ゲスト）'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: DesignTokens.spaceBase),
                  backgroundColor: DesignTokens.primary,
                  foregroundColor: DesignTokens.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.spaceBase),

              // Apple Sign-Inボタン
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _signInWithApple,
                icon: const Icon(CupertinoIcons.logo_apple),
                label: const Text('Appleでサインイン'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: DesignTokens.spaceBase),
                  side: const BorderSide(color: DesignTokens.textSecondary),
                  foregroundColor: DesignTokens.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: DesignTokens.spaceSection),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signInAnonymously() async {
    setState(() => _isLoading = true);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signInAnonymously();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ゲストとしてログインしました'),
            backgroundColor: DesignTokens.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ログインに失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithApple() async {
    setState(() => _isLoading = true);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final currentUser = authRepo.currentUser;

      // 匿名ユーザーの場合はリンク、そうでない場合は新規サインイン
      await authRepo.signInWithApple(link: currentUser?.isAnonymous ?? false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appleアカウントでログインしました'),
            backgroundColor: DesignTokens.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Appleサインインに失敗しました: ${_getErrorMessage(e)}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getErrorMessage(Object error) {
    if (error.toString().contains('credential-already-in-use')) {
      return '既に使用されているアカウントです';
    } else if (error.toString().contains('canceled')) {
      return 'キャンセルされました';
    } else {
      return error.toString();
    }
  }
}
