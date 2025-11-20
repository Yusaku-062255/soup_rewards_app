import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/utils/user_id_resolver.dart';
import 'core/providers/app_providers.dart';
import 'features/home/presentation/pages/main_page.dart';
import 'features/points/presentation/pages/daily_draw_fullscreen_page.dart';
import 'features/points/application/points_controller.dart';

void main() async {
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
}

class SoupRewardsApp extends ConsumerStatefulWidget {
  const SoupRewardsApp({super.key});

  @override
  ConsumerState<SoupRewardsApp> createState() => _SoupRewardsAppState();
}

class _SoupRewardsAppState extends ConsumerState<SoupRewardsApp> {
  bool _hasShownDailyDraw = false;
  bool _initializationComplete = false;
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    // アプリ起動時に初期化を実行（PostFrameCallbackで安全に実行）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  /// アプリ起動時の初期化処理
  ///
  /// 初期化順序:
  /// 1. Firebase Authの準備を待つ（100ms遅延）
  /// 2. 匿名認証を初期化
  /// 3. DailyDrawNotifierの初期化
  /// 4. PointsNotifierの初期化
  /// 5. デイリーくじのチェック（1日1回のみ自動表示）
  Future<void> _initialize() async {
    if (_initializationComplete || _isInitializing) return;
    _isInitializing = true;

    try {
      // Firebase Authの準備を待つ（少し遅延を入れる）
      await Future.delayed(const Duration(milliseconds: 100));

      // 匿名認証を初期化（Firebase Authの準備を確実にする）
      try {
        await UserIdResolver.resolveAsync();
      } catch (e) {
        // 匿名認証に失敗してもアプリは続行
        debugPrint('[SoupRewardsApp] 匿名認証エラー: $e');
      }

      // pointsRepositoryProviderが準備できるまで待機（SharedPreferencesの初期化を待つ）
      try {
        final repositoryAsync = ref.read(pointsRepositoryProvider);
        if (!repositoryAsync.hasValue) {
          // リポジトリがまだ準備できていない場合は、準備が完了するまで待機
          // 最大1秒まで待機（通常は100-200msで完了する）
          for (int i = 0; i < 10; i++) {
            await Future.delayed(const Duration(milliseconds: 100));
            final retryAsync = ref.read(pointsRepositoryProvider);
            if (retryAsync.hasValue) {
              debugPrint('[SoupRewardsApp] リポジトリ準備完了（${i + 1}回目の試行）');
              break;
            }
            if (i == 9) {
              debugPrint('[SoupRewardsApp] リポジトリ準備がタイムアウトしました（1秒経過）');
            }
          }
        }
      } catch (e) {
        debugPrint('[SoupRewardsApp] リポジトリ準備エラー: $e');
      }

      // DailyDrawNotifierの初期化を確実に実行
      try {
        await ref.read(dailyDrawNotifierProvider.notifier).ensureInitialized();
      } catch (e) {
        // DailyDrawNotifierの初期化に失敗してもアプリは続行
        debugPrint('[SoupRewardsApp] DailyDrawNotifier初期化エラー: $e');
      }

      // PointsNotifierの初期化を確実に実行
      try {
        await ref.read(pointsNotifierProvider.notifier).ensureInitialized();
      } catch (e) {
        // PointsNotifierの初期化に失敗してもアプリは続行
        debugPrint('[SoupRewardsApp] PointsNotifier初期化エラー: $e');
      }

      // 初期化完了
      if (mounted) {
        setState(() {
          _initializationComplete = true;
          _isInitializing = false;
        });

        // 初期化完了後、デイリーくじをチェック（1日1回のみ自動表示）
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _checkDailyDraw();
          }
        });
      }
    } catch (e) {
      // エラー時もアプリは続行（ネットワークエラーなど）
      debugPrint('[SoupRewardsApp] 初期化エラー: $e');
      if (mounted) {
        setState(() {
          _initializationComplete = true;
          _isInitializing = false;
        });
      }
    }
  }

  /// デイリーくじの自動表示チェック
  ///
  /// 条件:
  /// - その日のくじが未実行であること
  /// - ローディング中でないこと
  /// - 既に表示済みでないこと
  void _checkDailyDraw() {
    if (_hasShownDailyDraw || !_initializationComplete) return;

    try {
      final drawState = ref.read(dailyDrawNotifierProvider);

      // その日のくじが未実行で、ローディング中でない場合
      if (!drawState.hasDrawnToday && !drawState.isLoading) {
        _hasShownDailyDraw = true;

        // 少し遅延してから表示（アプリ起動直後は避ける）
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const DailyDrawFullscreenPage(),
                fullscreenDialog: true,
              ),
            );
          }
        });
      }
    } catch (e) {
      // エラー時は無視（DailyDrawNotifierがまだ初期化されていない場合など）
      debugPrint('[SoupRewardsApp] デイリーくじチェックエラー: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // デイリーくじの状態を監視（初期化完了後のみ）
    if (_initializationComplete) {
      ref.watch(dailyDrawNotifierProvider);
    }

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
