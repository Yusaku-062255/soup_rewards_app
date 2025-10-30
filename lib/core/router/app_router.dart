import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/home/presentation/pages/main_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/points/presentation/pages/points_page.dart';
import '../../features/coupon/presentation/pages/coupon_page.dart';
import '../../features/qr_scan/presentation/pages/qr_scan_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../providers/app_providers.dart';

/// アプリケーションルーター
///
/// Deep Link/URL対応、認証状態による遷移制御
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,

    // リダイレクト処理（認証チェック）
    redirect: (BuildContext context, GoRouterState state) {
      final isAuthenticated = authState == AuthState.authenticated;
      final isAuthenticating = authState == AuthState.loading;
      final isUnauthenticated = authState == AuthState.unauthenticated;

      // 認証が必要なルート
      final requiresAuth = state.matchedLocation.startsWith('/profile') ||
          state.matchedLocation.startsWith('/points') ||
          state.matchedLocation.startsWith('/coupons');

      // 認証処理中は待機
      if (isAuthenticating) {
        return null;
      }

      // 未認証でログイン必須ページへのアクセス
      if (!isAuthenticated && requiresAuth) {
        return '/login';
      }

      // 認証済みでログインページへのアクセス
      if (isAuthenticated && state.matchedLocation == '/login') {
        return '/';
      }

      return null;
    },

    routes: [
      // ========================================
      // ルートページ（BottomNavigationBar）
      // ========================================
      GoRoute(
        path: '/',
        name: 'main',
        builder: (context, state) => const MainPage(),
      ),

      // ========================================
      // ホーム
      // ========================================
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),

      // ========================================
      // ポイント
      // ========================================
      GoRoute(
        path: '/points',
        name: 'points',
        builder: (context, state) => const PointsPage(),
        routes: [
          // ポイント詳細
          GoRoute(
            path: ':pointId',
            name: 'point-detail',
            builder: (context, state) {
              final pointId = state.pathParameters['pointId']!;
              return PointDetailPage(pointId: pointId);
            },
          ),
        ],
      ),

      // ========================================
      // クーポン
      // ========================================
      GoRoute(
        path: '/coupons',
        name: 'coupons',
        builder: (context, state) => const CouponPage(),
        routes: [
          // クーポン詳細
          GoRoute(
            path: ':couponId',
            name: 'coupon-detail',
            builder: (context, state) {
              final couponId = state.pathParameters['couponId']!;
              return CouponDetailPage(couponId: couponId);
            },
          ),
        ],
      ),

      // ========================================
      // QRスキャン
      // ========================================
      GoRoute(
        path: '/qr-scan',
        name: 'qr-scan',
        builder: (context, state) => const QRScanPage(),
      ),

      // ========================================
      // プロフィール
      // ========================================
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfilePage(),
        routes: [
          // プロフィール編集
          GoRoute(
            path: 'edit',
            name: 'profile-edit',
            builder: (context, state) => const ProfileEditPage(),
          ),
          // 設定
          GoRoute(
            path: 'settings',
            name: 'settings',
            builder: (context, state) => const SettingsPage(),
          ),
        ],
      ),

      // ========================================
      // ログイン・認証
      // ========================================
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),

      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),

      // ========================================
      // Deep Link対応
      // ========================================

      // プッシュ通知からの遷移
      // 例: soup://app/notification/news123
      GoRoute(
        path: '/notification/:type/:id',
        name: 'notification',
        builder: (context, state) {
          final type = state.pathParameters['type']!;
          final id = state.pathParameters['id']!;
          return NotificationLandingPage(type: type, id: id);
        },
      ),

      // クーポン共有リンク
      // 例: https://soup.jp/coupon/share/coupon123
      GoRoute(
        path: '/coupon/share/:couponId',
        name: 'coupon-share',
        builder: (context, state) {
          final couponId = state.pathParameters['couponId']!;
          return CouponDetailPage(couponId: couponId);
        },
      ),
    ],

    // エラーページ
    errorBuilder: (context, state) => ErrorPage(
      error: state.error?.toString() ?? 'Unknown error',
    ),
  );
});

// ========================================
// 仮実装ページ（後で実装）
// ========================================

/// ポイント詳細ページ
class PointDetailPage extends StatelessWidget {
  final String pointId;

  const PointDetailPage({super.key, required this.pointId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ポイント詳細')),
      body: Center(child: Text('ポイントID: $pointId')),
    );
  }
}

/// クーポン詳細ページ
class CouponDetailPage extends StatelessWidget {
  final String couponId;

  const CouponDetailPage({super.key, required this.couponId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('クーポン詳細')),
      body: Center(child: Text('クーポンID: $couponId')),
    );
  }
}

/// プロフィール編集ページ
class ProfileEditPage extends StatelessWidget {
  const ProfileEditPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('プロフィール編集')),
      body: const Center(child: Text('プロフィール編集')),
    );
  }
}

/// 設定ページ
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: const Center(child: Text('設定')),
    );
  }
}

/// ログインページ
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ログイン')),
      body: const Center(child: Text('ログイン')),
    );
  }
}

/// 新規登録ページ
class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('新規登録')),
      body: const Center(child: Text('新規登録')),
    );
  }
}

/// 通知ランディングページ
class NotificationLandingPage extends StatelessWidget {
  final String type;
  final String id;

  const NotificationLandingPage({
    super.key,
    required this.type,
    required this.id,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('通知')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('通知タイプ: $type'),
            Text('ID: $id'),
          ],
        ),
      ),
    );
  }
}

/// エラーページ
class ErrorPage extends StatelessWidget {
  final String error;

  const ErrorPage({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('エラー')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(error),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('ホームに戻る'),
            ),
          ],
        ),
      ),
    );
  }
}
