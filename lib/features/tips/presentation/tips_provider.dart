import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/tips_repository.dart';
import '../domain/tip.dart';
import '../data/tips_repository_impl.dart';

/// Tipsリポジトリプロバイダー
final tipsRepositoryProvider = Provider<TipsRepository>((ref) {
  return TipsRepositoryImpl();
});

/// すべてのTipsプロバイダー
final allTipsProvider = FutureProvider<List<Tip>>((ref) async {
  final repository = ref.watch(tipsRepositoryProvider);
  return repository.getAllTips();
});

/// おすすめTipsプロバイダー
final recommendedTipsProvider = FutureProvider<List<Tip>>((ref) async {
  final repository = ref.watch(tipsRepositoryProvider);
  return repository.getRecommendedTips();
});

/// カテゴリ別Tipsプロバイダー
final tipsByCategoryProvider =
    FutureProvider.family<List<Tip>, TipCategory>((ref, category) async {
  final repository = ref.watch(tipsRepositoryProvider);
  return repository.getTipsByCategory(category);
});

/// 季節別Tipsプロバイダー
final tipsBySeasonProvider =
    FutureProvider.family<List<Tip>, Season>((ref, season) async {
  final repository = ref.watch(tipsRepositoryProvider);
  return repository.getTipsBySeason(season);
});

/// 季節チェックリストプロバイダー
final seasonalChecklistProvider =
    FutureProvider.family<List<ChecklistItem>, Season>((ref, season) async {
  final repository = ref.watch(tipsRepositoryProvider);
  return repository.getSeasonalChecklist(season);
});
