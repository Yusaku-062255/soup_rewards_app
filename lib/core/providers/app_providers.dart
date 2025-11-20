import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/user_repository.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/coupon_repository.dart';
import '../repositories/user_coupon_repository.dart';
import '../repositories/news_repository.dart';
import '../models/user_model.dart';
import '../models/transaction_model.dart';
import '../models/coupon_model.dart';
import '../models/user_coupon_model.dart';
import '../models/news_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/points/domain/repositories/points_repository.dart';
import '../../features/points/data/repositories/mock_points_repository.dart';
import '../../features/points/data/repositories/firestore_points_repository.dart';
import '../../features/reservations/data/reservations_repository.dart';
import '../../features/redemptions/data/repositories/redemptions_repository.dart';

/// アプリケーション全体で使用するプロバイダー

// SharedPreferencesプロバイダー
final sharedPreferencesProvider =
    FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

// ポイントリポジトリプロバイダー
// TODO: 本番環境では FirestorePointsRepository に切り替える
final pointsRepositoryProvider = FutureProvider<PointsRepository>((ref) async {
  // 一時的なフラグ（動作確認後に true に変更）
  const useFirestore = false;

  // ignore: dead_code
  if (useFirestore) {
    return FirestorePointsRepository(FirebaseFirestore.instance);
  } else {
    // モック実装（SharedPreferences使用）
    // SharedPreferencesが準備できるまで待機
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    return MockPointsRepository(prefs);
  }
});

// リポジトリプロバイダー
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

final reservationsRepositoryProvider = Provider<ReservationsRepository>((ref) {
  return ReservationsRepository();
});

final redemptionsRepositoryProvider = Provider<RedemptionsRepository>((ref) {
  return RedemptionsRepository();
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository();
});

final couponRepositoryProvider = Provider<CouponRepository>((ref) {
  return CouponRepository();
});

final userCouponRepositoryProvider = Provider<UserCouponRepository>((ref) {
  return UserCouponRepository();
});

final newsRepositoryProvider = Provider<NewsRepository>((ref) {
  return NewsRepository();
});

// Firebase Auth プロバイダー
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

// 現在のユーザーストリーム
final authStateChangesProvider = StreamProvider<User?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return auth.authStateChanges();
});

// ユーザー認証状態プロバイダー
final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  return AuthStateNotifier(ref);
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
  final Ref _ref;
  final FirebaseAuth _auth;

  AuthStateNotifier(this._ref)
      : _auth = _ref.read(firebaseAuthProvider),
        super(AuthState.initial) {
    // 認証状態の変更を監視
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        state = AuthState.authenticated;
      } else {
        state = AuthState.unauthenticated;
      }
    });
  }

  Future<void> signIn(String email, String password) async {
    state = AuthState.loading;
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      state = AuthState.authenticated;
    } catch (e) {
      state = AuthState.error;
      rethrow;
    }
  }

  Future<void> signUp(
    String email,
    String password,
    String name, {
    VehicleType? vehicleType,
    String? vehicleMaker,
    String? vehicleModel,
  }) async {
    state = AuthState.loading;
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // ユーザー情報をFirestoreに保存
      if (credential.user != null) {
        final userRepo = _ref.read(userRepositoryProvider);

        // 会員IDを生成
        final memberId = await userRepo.generateMemberId();

        final user = UserModel(
          id: credential.user!.uid,
          name: name,
          email: email,
          memberId: memberId,
          vehicleType: vehicleType,
          vehicleMaker: vehicleMaker,
          vehicleModel: vehicleModel,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await userRepo.createUser(user);
      }

      state = AuthState.authenticated;
    } catch (e) {
      state = AuthState.error;
      rethrow;
    }
  }

  Future<void> signOut() async {
    state = AuthState.loading;
    try {
      await _auth.signOut();
      state = AuthState.unauthenticated;
    } catch (e) {
      state = AuthState.error;
      rethrow;
    }
  }
}

// 現在のユーザー情報プロバイダー
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final userRepo = ref.watch(userRepositoryProvider);
  return userRepo.watchCurrentUser();
});

// ポイント残高プロバイダー（現在のユーザーから取得）
final pointsProvider = Provider<int>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.when(
    data: (user) => user?.points ?? 0,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

// クーポン一覧プロバイダー
final couponsProvider = StreamProvider<List<CouponModel>>((ref) {
  final couponRepo = ref.watch(couponRepositoryProvider);
  return couponRepo.watchActiveCoupons();
});

// ユーザーが獲得したクーポンプロバイダー
final userCouponsProvider = StreamProvider<List<UserCouponModel>>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  final userCouponRepo = ref.watch(userCouponRepositoryProvider);

  return userAsync.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      return userCouponRepo.watchUserCoupons(user.id);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

// ニュース一覧プロバイダー
final newsProvider = StreamProvider<List<NewsModel>>((ref) {
  final newsRepo = ref.watch(newsRepositoryProvider);
  return newsRepo.watchLatestNews(limit: 10);
});

// 取引履歴プロバイダー
final transactionsProvider = StreamProvider<List<TransactionModel>>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  final transactionRepo = ref.watch(transactionRepositoryProvider);

  return userAsync.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      return transactionRepo.watchUserTransactions(user.id, limit: 20);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});
