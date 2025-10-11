import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// アプリケーション全体で使用するプロバイダー

// SharedPreferencesプロバイダー
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferencesProvider must be overridden');
});

// ユーザー認証状態プロバイダー
final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  return AuthStateNotifier();
});

// ユーザー認証状態
enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

// 認証状態管理
class AuthStateNotifier extends StateNotifier<AuthState> {
  AuthStateNotifier() : super(AuthState.initial);

  Future<void> signIn(String email, String password) async {
    state = AuthState.loading;
    try {
      // TODO: Firebase Auth実装
      await Future.delayed(const Duration(seconds: 1)); // 仮の処理
      state = AuthState.authenticated;
    } catch (e) {
      state = AuthState.error;
    }
  }

  Future<void> signOut() async {
    state = AuthState.loading;
    try {
      // TODO: Firebase Auth実装
      await Future.delayed(const Duration(milliseconds: 500)); // 仮の処理
      state = AuthState.unauthenticated;
    } catch (e) {
      state = AuthState.error;
    }
  }
}

// ポイント残高プロバイダー
final pointsProvider = StateNotifierProvider<PointsNotifier, int>((ref) {
  return PointsNotifier();
});

class PointsNotifier extends StateNotifier<int> {
  PointsNotifier() : super(0);

  void addPoints(int points) {
    state = state + points;
  }

  void usePoints(int points) {
    if (state >= points) {
      state = state - points;
    }
  }

  void setPoints(int points) {
    state = points;
  }
}

// クーポン一覧プロバイダー
final couponsProvider = StateNotifierProvider<CouponsNotifier, List<Coupon>>((ref) {
  return CouponsNotifier();
});

class CouponsNotifier extends StateNotifier<List<Coupon>> {
  CouponsNotifier() : super([]);

  Future<void> loadCoupons() async {
    try {
      // TODO: Firestore実装
      await Future.delayed(const Duration(seconds: 1)); // 仮の処理
      state = [
        Coupon(
          id: '1',
          title: '洗車サービス20%OFF',
          description: '次回洗車サービスが20%割引になります',
          discountRate: 20,
          expiryDate: DateTime.now().add(const Duration(days: 30)),
          isUsed: false,
        ),
        Coupon(
          id: '2',
          title: 'コーティング10%OFF',
          description: 'コーティングサービスが10%割引になります',
          discountRate: 10,
          expiryDate: DateTime.now().add(const Duration(days: 60)),
          isUsed: false,
        ),
      ];
    } catch (e) {
      // エラーハンドリング
      state = [];
    }
  }

  void useCoupon(String couponId) {
    state = state.map((coupon) {
      if (coupon.id == couponId) {
        return coupon.copyWith(isUsed: true);
      }
      return coupon;
    }).toList();
  }
}

// クーポンデータモデル
class Coupon {
  final String id;
  final String title;
  final String description;
  final int discountRate;
  final DateTime expiryDate;
  final bool isUsed;

  const Coupon({
    required this.id,
    required this.title,
    required this.description,
    required this.discountRate,
    required this.expiryDate,
    required this.isUsed,
  });

  Coupon copyWith({
    String? id,
    String? title,
    String? description,
    int? discountRate,
    DateTime? expiryDate,
    bool? isUsed,
  }) {
    return Coupon(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      discountRate: discountRate ?? this.discountRate,
      expiryDate: expiryDate ?? this.expiryDate,
      isUsed: isUsed ?? this.isUsed,
    );
  }
}

// ニュース一覧プロバイダー
final newsProvider = StateNotifierProvider<NewsNotifier, List<News>>((ref) {
  return NewsNotifier();
});

class NewsNotifier extends StateNotifier<List<News>> {
  NewsNotifier() : super([]);

  Future<void> loadNews() async {
    try {
      // TODO: Firestore実装
      await Future.delayed(const Duration(seconds: 1)); // 仮の処理
      state = [
        News(
          id: '1',
          title: '新サービス「プレミアムコーティング」開始',
          content: '長期間効果が持続するプレミアムコーティングサービスを開始しました。',
          publishDate: DateTime.now().subtract(const Duration(days: 1)),
          imageUrl: null,
        ),
        News(
          id: '2',
          title: 'SOUP徳島店リニューアルオープン',
          content: '徳島店が新しくリニューアルオープンしました。最新設備でお客様をお迎えします。',
          publishDate: DateTime.now().subtract(const Duration(days: 3)),
          imageUrl: null,
        ),
      ];
    } catch (e) {
      state = [];
    }
  }
}

// ニュースデータモデル
class News {
  final String id;
  final String title;
  final String content;
  final DateTime publishDate;
  final String? imageUrl;

  const News({
    required this.id,
    required this.title,
    required this.content,
    required this.publishDate,
    this.imageUrl,
  });
}
