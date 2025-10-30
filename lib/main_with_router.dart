import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';

/// go_router統合版のmain.dart
///
/// このファイルを main.dart にリネームして使用
/// Deep Link/URL遷移に対応

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase初期化
  try {
    await Firebase.initializeApp();
    debugPrint('✅ Firebase initialized');
  } catch (e) {
    debugPrint('⚠️ Firebase initialization skipped: $e');
  }

  runApp(
    const ProviderScope(
      child: SoupRewardsApp(),
    ),
  );
}

class SoupRewardsApp extends ConsumerWidget {
  const SoupRewardsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      // テーマ
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      // ルーター設定
      routerConfig: router,

      // テキストスケーリング制限
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.2),
            ),
          ),
          child: child!,
        );
      },
    );
  }
}
