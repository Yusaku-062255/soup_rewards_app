import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/constants/app_config.dart';
import '../../../../core/utils/user_id_resolver.dart';
import '../domain/models/daily_draw_result.dart';
import '../domain/repositories/points_repository.dart';
import '../data/repositories/firestore_points_repository.dart';

/// 日次くじのUI状態（ローディング状態を含む）
class DailyDrawUIState {
  final bool hasDrawnToday;
  final DateTime? lastDrawDate;
  final DailyDrawResult? todayResult;
  final bool isLoading;

  DailyDrawUIState({
    required this.hasDrawnToday,
    this.lastDrawDate,
    this.todayResult,
    this.isLoading = false,
  });

  DailyDrawUIState copyWith({
    bool? hasDrawnToday,
    DateTime? lastDrawDate,
    DailyDrawResult? todayResult,
    bool? isLoading,
  }) {
    return DailyDrawUIState(
      hasDrawnToday: hasDrawnToday ?? this.hasDrawnToday,
      lastDrawDate: lastDrawDate ?? this.lastDrawDate,
      todayResult: todayResult ?? this.todayResult,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  /// DailyDrawStateから変換
  factory DailyDrawUIState.fromDomain(DailyDrawState state,
      {bool isLoading = false}) {
    return DailyDrawUIState(
      hasDrawnToday: state.hasDrawnToday,
      lastDrawDate: state.lastDrawDate,
      todayResult: state.todayResult,
      isLoading: isLoading,
    );
  }
}

/// ポイント状態
class PointsState {
  final int currentPoints;
  final bool isLoading;

  PointsState({
    required this.currentPoints,
    this.isLoading = false,
  });

  PointsState copyWith({
    int? currentPoints,
    bool? isLoading,
  }) {
    return PointsState(
      currentPoints: currentPoints ?? this.currentPoints,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// 日次くじの状態管理
class DailyDrawNotifier extends StateNotifier<DailyDrawUIState> {
  final PointsRepository _repository;
  bool _initialized = false;

  DailyDrawNotifier(this._repository)
      : super(DailyDrawUIState(hasDrawnToday: false));

  /// ユーザーIDを解決（非同期版）
  ///
  /// ログイン状態に応じて適切なユーザーIDを返す
  /// - ログイン済み: Firebase Auth の uid
  /// - ゲスト状態: 匿名認証の uid（自動的に匿名認証を実行）
  Future<String> _resolveUserIdAsync() async {
    return await UserIdResolver.resolveAsync();
  }

  /// 店舗IDを解決
  String _resolveShopId() {
    return AppConfig.defaultShopId;
  }

  Future<void> _loadState() async {
    if (_initialized) return;

    try {
      // 匿名認証を含む認証状態を確認
      // 未認証の場合は匿名認証を試みる
      final userId = await _resolveUserIdAsync();

      final drawState = await _repository.getDailyDrawState(
        userId: userId,
        shopId: _resolveShopId(),
      );

      state = DailyDrawUIState.fromDomain(drawState);

      // 成功時のみ初期化完了フラグを立てる
      _initialized = true;
    } catch (e) {
      // エラー時は初期状態を維持（Firestore接続エラーなどに対応）
      // ネットワークエラーなどでFirestoreにアクセスできない場合でも
      // アプリがクラッシュしないようにする
      state = DailyDrawUIState(hasDrawnToday: false);
      // 初期化失敗として扱う（再試行可能にする）
      _initialized = false;
    }
  }

  /// 初期化を確実に実行
  Future<void> ensureInitialized() async {
    if (!_initialized) {
      // リポジトリが準備できているか確認
      // FutureProviderの場合は、準備が完了するまで待機する必要がある
      await _loadState();
    }
  }

  /// くじを引く
  ///
  /// 匿名認証済みユーザーでも利用可能です。
  Future<DailyDrawResult> draw() async {
    state = state.copyWith(isLoading: true);

    try {
      // 匿名認証を含む認証状態を確認
      final userId = await _resolveUserIdAsync();

      final result = await _repository.drawToday(
        userId: userId,
        shopId: _resolveShopId(),
      );

      // 状態を更新
      state = DailyDrawUIState(
        hasDrawnToday: true,
        lastDrawDate: DateTime.now(),
        todayResult: result,
      );

      return result;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  /// 状態をリフレッシュ
  Future<void> refresh() async {
    await _loadState();
  }
}

/// ポイントの状態管理
class PointsNotifier extends StateNotifier<PointsState> {
  final PointsRepository _repository;
  bool _initialized = false;

  PointsNotifier(this._repository) : super(PointsState(currentPoints: 0));

  /// ユーザーIDを解決（非同期版）
  ///
  /// ログイン状態に応じて適切なユーザーIDを返す
  /// - ログイン済み: Firebase Auth の uid
  /// - ゲスト状態: 匿名認証の uid（自動的に匿名認証を実行）
  Future<String> _resolveUserIdAsync() async {
    return await UserIdResolver.resolveAsync();
  }

  /// 店舗IDを解決
  String _resolveShopId() {
    return AppConfig.defaultShopId;
  }

  Future<void> _loadPoints() async {
    if (_initialized && state.currentPoints > 0) {
      // 既に初期化済みでポイントがある場合は、リフレッシュのみ
      state = state.copyWith(isLoading: true);
    } else {
      // 初回初期化
      state = state.copyWith(isLoading: true);
    }

    try {
      // 匿名認証を含む認証状態を確認
      final userId = await _resolveUserIdAsync();

      final points = await _repository.getCurrentPoints(
        userId: userId,
        shopId: _resolveShopId(),
      );
      state = state.copyWith(currentPoints: points, isLoading: false);
      _initialized = true;
    } catch (e) {
      // エラー時は現在のポイントを維持（Firestore接続エラーなどに対応）
      // ネットワークエラーなどでFirestoreにアクセスできない場合でも
      // アプリがクラッシュしないようにする
      state = state.copyWith(isLoading: false);
      // 初回初期化失敗の場合は、初期化済みフラグを立てない（再試行可能にする）
      if (_initialized) {
        // リフレッシュ時のエラーは無視
      } else {
        // 初回初期化失敗は再試行可能にする
        _initialized = false;
      }
    }
  }

  /// 初期化を確実に実行
  Future<void> ensureInitialized() async {
    if (!_initialized) {
      await _loadPoints();
    }
  }

  /// ポイントを追加
  Future<void> addPoints(int points) async {
    final userId = await _resolveUserIdAsync();
    await _repository.addPoints(
      userId: userId,
      shopId: _resolveShopId(),
      points: points,
    );
    await _loadPoints();
  }

  /// 状態をリフレッシュ
  Future<void> refresh() async {
    await _loadPoints();
  }
}

/// プロバイダー定義
/// 注意: pointsRepositoryProviderは app_providers.dart で定義されています

final dailyDrawNotifierProvider =
    StateNotifierProvider<DailyDrawNotifier, DailyDrawUIState>((ref) {
  final repositoryAsync = ref.watch(pointsRepositoryProvider);
  // repositoryAsyncがloading状態の場合は、一時的なNotifierを返す
  // 実際の使用時には、ensureInitialized()で初期化を確実に実行する
  if (repositoryAsync.hasValue && repositoryAsync.value != null) {
    return DailyDrawNotifier(repositoryAsync.value!);
  } else {
    // loading状態の場合は、一時的なNotifierを返す
    // 実際の使用時には、ensureInitialized()で初期化を確実に実行する
    // 注意: このNotifierは実際には使用されない（ensureInitialized()で再初期化される）
    // 一時的なリポジトリとして、Firestore実装を使用（SharedPreferences不要）
    return DailyDrawNotifier(
        FirestorePointsRepository(FirebaseFirestore.instance));
  }
});

final pointsNotifierProvider =
    StateNotifierProvider<PointsNotifier, PointsState>((ref) {
  final repositoryAsync = ref.watch(pointsRepositoryProvider);
  // repositoryAsyncがloading状態の場合は、一時的なNotifierを返す
  // 実際の使用時には、ensureInitialized()で初期化を確実に実行する
  if (repositoryAsync.hasValue && repositoryAsync.value != null) {
    return PointsNotifier(repositoryAsync.value!);
  } else {
    // loading状態の場合は、一時的なNotifierを返す
    // 実際の使用時には、ensureInitialized()で初期化を確実に実行する
    // 注意: このNotifierは実際には使用されない（ensureInitialized()で再初期化される）
    // 一時的なリポジトリとして、Firestore実装を使用（SharedPreferences不要）
    return PointsNotifier(
        FirestorePointsRepository(FirebaseFirestore.instance));
  }
});

/// くじ結果の一時表示用（アニメーション後に消す）
final drawResultProvider = StateProvider<DailyDrawResult?>((ref) => null);
