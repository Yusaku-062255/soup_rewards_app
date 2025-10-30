import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/gacha_repository_impl.dart';
import '../domain/gacha_repository.dart';
import '../domain/gacha_result.dart';

/// ガチャリポジトリプロバイダー
final gachaRepositoryProvider = Provider<GachaRepository>((ref) {
  return GachaRepositoryImpl();
});

/// ガチャ状態プロバイダー
final gachaStateProvider = StateNotifierProvider<GachaStateNotifier, GachaState>((ref) {
  final repository = ref.watch(gachaRepositoryProvider);
  return GachaStateNotifier(repository);
});

/// 本日実行済みかどうかのプロバイダー
final isClaimedTodayProvider = FutureProvider<bool>((ref) async {
  final repository = ref.watch(gachaRepositoryProvider);
  return repository.isClaimedToday();
});

/// 連続ログイン日数プロバイダー
final streakProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(gachaRepositoryProvider);
  return repository.getStreak();
});

/// 次回実行可能日時プロバイダー
final nextClaimAtProvider = FutureProvider<DateTime>((ref) async {
  final repository = ref.watch(gachaRepositoryProvider);
  return repository.getNextClaimAt();
});

/// ガチャ状態
class GachaState {
  final GachaStatus status;
  final GachaResult? result;
  final String? errorMessage;

  const GachaState({
    required this.status,
    this.result,
    this.errorMessage,
  });

  factory GachaState.initial() {
    return const GachaState(status: GachaStatus.available);
  }

  factory GachaState.loading() {
    return const GachaState(status: GachaStatus.loading);
  }

  factory GachaState.success(GachaResult result) {
    return GachaState(
      status: GachaStatus.alreadyClaimed,
      result: result,
    );
  }

  factory GachaState.error(String message) {
    return GachaState(
      status: GachaStatus.error,
      errorMessage: message,
    );
  }

  factory GachaState.alreadyClaimed() {
    return const GachaState(status: GachaStatus.alreadyClaimed);
  }

  GachaState copyWith({
    GachaStatus? status,
    GachaResult? result,
    String? errorMessage,
  }) {
    return GachaState(
      status: status ?? this.status,
      result: result ?? this.result,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get isLoading => status == GachaStatus.loading;
  bool get isAvailable => status == GachaStatus.available;
  bool get isAlreadyClaimed => status == GachaStatus.alreadyClaimed;
  bool get hasError => status == GachaStatus.error;
}

/// ガチャ状態管理Notifier
class GachaStateNotifier extends StateNotifier<GachaState> {
  final GachaRepository _repository;

  GachaStateNotifier(this._repository) : super(GachaState.initial()) {
    _checkInitialState();
  }

  /// 初期状態チェック
  Future<void> _checkInitialState() async {
    try {
      final isClaimed = await _repository.isClaimedToday();
      if (isClaimed) {
        state = GachaState.alreadyClaimed();
      }
    } catch (e) {
      // エラーは無視（availableのまま）
    }
  }

  /// ガチャ実行
  Future<void> claimGacha() async {
    if (state.isLoading) return;

    state = GachaState.loading();

    try {
      final result = await _repository.claimDailyGacha();
      state = GachaState.success(result);
    } on GachaAlreadyClaimedException catch (e) {
      state = GachaState.error(e.message);
    } on GachaException catch (e) {
      state = GachaState.error(e.message);
    } catch (e) {
      state = GachaState.error('予期しないエラーが発生しました');
    }
  }

  /// リセット（デバッグ用）
  void reset() {
    state = GachaState.initial();
  }
}
