import 'package:flutter/material.dart';
import 'package:soup_rewards_app/core/observability/sentry_bootstrap.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'features/home/presentation/pages/main_page.dart';

void main() {
  runWithSentry(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Firebase初期化
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    runApp(
      const ProviderScope(
        child: SoupRewardsApp(),
      ),
    );
  });

  // Sentryの接続確認メッセージを送信 (デバッグ時のみ)
  sendSentrySmokeTestMessage();
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
    );
  }
}

