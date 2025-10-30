import 'tip.dart';

/// Tipsリポジトリ
abstract class TipsRepository {
  /// すべてのTips取得
  Future<List<Tip>> getAllTips();

  /// カテゴリ別Tips取得
  Future<List<Tip>> getTipsByCategory(TipCategory category);

  /// 季節別Tips取得
  Future<List<Tip>> getTipsBySeason(Season season);

  /// おすすめTips取得
  Future<List<Tip>> getRecommendedTips();

  /// 季節チェックリスト取得
  Future<List<ChecklistItem>> getSeasonalChecklist(Season season);

  /// チェックリストアイテム完了切り替え
  Future<void> toggleChecklistItem(String itemId, bool isCompleted);
}
