import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:soup_rewards_app/core/theme/soup_theme.dart'; // SOUP_THEMEをインポート
import 'core/constants/app_constants.dart';
import 'features/home/presentation/pages/main_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase初期化（本番環境では設定ファイルが必要）
  try {
    await Firebase.initializeApp();
  } catch (e) {
    // Firebase設定がない場合はスキップ（開発環境）
    debugPrint('Firebase initialization skipped: $e');
  }

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
      theme: SoupTheme.lightTheme, // AppTheme.lightThemeをSoupTheme.lightThemeに修正
      darkTheme: SoupTheme.darkTheme, // AppTheme.darkThemeをSoupTheme.darkThemeに修正
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

