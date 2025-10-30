import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/services/sentry_service.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'features/home/presentation/pages/main_page.dart';

/// Sentry統合版のmain.dart
///
/// 使い方:
/// 1. Sentryプロジェクト作成: https://sentry.io/
/// 2. DSNを取得
/// 3. ビルド時に環境変数で注入:
///    flutter run --dart-define=SENTRY_DSN=https://your-dsn@sentry.io/project-id
///
/// または、このファイルを main.dart にリネームして使用

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Sentry初期化（エラー監視開始）
  await SentryService.initialize();

  // Sentryでアプリ全体をラップ
  await SentryService.initialize();

  // Firebase初期化
  try {
    await Firebase.initializeApp();
    debugPrint('✅ Firebase initialized');
  } catch (e, stackTrace) {
    debugPrint('⚠️ Firebase initialization skipped: $e');
    // Sentryにエラー送信
    await SentryService.captureException(
      e,
      stackTrace: stackTrace,
      hint: 'Firebase initialization failed',
    );
  }

  // Flutterエラーハンドラー設定
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    SentryService.captureException(
      details.exception,
      stackTrace: details.stack,
      hint: 'Flutter Framework Error',
    );
  };

  runApp(
    const ProviderScope(
      child: SoupRewardsApp(),
    ),
  );
}

class SoupRewardsApp extends StatelessWidget {
  const SoupRewardsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const MainPage(),
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

      // グローバルナビゲーションオブザーバー（画面遷移トラッキング）
      navigatorObservers: [
        // Sentryのナビゲーション監視
        // SentryNavigatorObserver(), // 必要に応じて有効化
      ],
    );
  }
}
