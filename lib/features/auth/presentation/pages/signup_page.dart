import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/utils/auth_error_mapper.dart';
import '../../../../core/models/user_model.dart';

/// 新規登録ページ
class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _vehicleMakerController = TextEditingController();
  final _vehicleModelController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorText;
  VehicleType? _selectedVehicleType;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _vehicleMakerController.dispose();
    _vehicleModelController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _errorText = null;
    });

    try {
      await ref.read(authStateProvider.notifier).signUp(
            _emailController.text.trim(),
            _passwordController.text,
            _nameController.text.trim(),
            vehicleType: _selectedVehicleType,
            vehicleMaker: _vehicleMakerController.text.trim().isEmpty 
                ? null 
                : _vehicleMakerController.text.trim(),
            vehicleModel: _vehicleModelController.text.trim().isEmpty 
                ? null 
                : _vehicleModelController.text.trim(),
          );

      // 登録成功時は前の画面に戻る
      // ProfilePage は authStateChangesProvider を watch しているため、
      // 認証状態の変更が自動的に反映される
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _errorText = AuthErrorMapper.mapFirebaseAuthException(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isLoading = authState == AuthState.loading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('新規会員登録'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textMain,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                
                // タイトル
                Text(
                  '会員登録',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'SOUP Rewardsアプリをご利用いただくために、\n会員登録をお願いします',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),

                // エラーメッセージ
                if (_errorText != null)
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
                            _errorText!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // 名前入力
                TextFormField(
                  controller: _nameController,
                  enabled: !isLoading,
                  decoration: InputDecoration(
                    labelText: 'お名前',
                    hintText: '山田 太郎',
                    prefixIcon: const Icon(Icons.person_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'お名前を入力してください';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // メールアドレス入力
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !isLoading,
                  decoration: InputDecoration(
                    labelText: 'メールアドレス',
                    hintText: 'example@email.com',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'メールアドレスを入力してください';
                    }
                    if (!value.contains('@')) {
                      return 'メールアドレスの形式が正しくありません';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // パスワード入力
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  enabled: !isLoading,
                  decoration: InputDecoration(
                    labelText: 'パスワード',
                    hintText: '6文字以上で入力',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'パスワードを入力してください';
                    }
                    if (value.length < 6) {
                      return 'パスワードは6文字以上で入力してください';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // パスワード確認入力
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  enabled: !isLoading,
                  decoration: InputDecoration(
                    labelText: 'パスワード（確認）',
                    hintText: 'パスワードを再入力',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'パスワード（確認）を入力してください';
                    }
                    if (value != _passwordController.text) {
                      return 'パスワードが一致しません';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // 車種区分（ラジオボタン）
                Text(
                  '車種区分',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<VehicleType>(
                        title: const Text('EV車'),
                        value: VehicleType.ev,
                        // ignore: deprecated_member_use
                        groupValue: _selectedVehicleType,
                        // ignore: deprecated_member_use
                        onChanged: (value) {
                          setState(() {
                            _selectedVehicleType = value;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<VehicleType>(
                        title: const Text('ガソリン車など'),
                        value: VehicleType.gasoline,
                        // ignore: deprecated_member_use
                        groupValue: _selectedVehicleType,
                        // ignore: deprecated_member_use
                        onChanged: (value) {
                          setState(() {
                            _selectedVehicleType = value;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // メーカー名（任意）
                TextFormField(
                  controller: _vehicleMakerController,
                  enabled: !isLoading,
                  decoration: InputDecoration(
                    labelText: 'メーカー名（任意）',
                    hintText: '例: トヨタ',
                    prefixIcon: const Icon(Icons.directions_car_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 車種名（任意）
                TextFormField(
                  controller: _vehicleModelController,
                  enabled: !isLoading,
                  decoration: InputDecoration(
                    labelText: '車種名（任意）',
                    hintText: '例: プリウス',
                    prefixIcon: const Icon(Icons.car_rental_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // 登録ボタン
                ElevatedButton(
                  onPressed: isLoading ? null : _handleSignup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                          ),
                        )
                      : const Text(
                          '会員登録',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

