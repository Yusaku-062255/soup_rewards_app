import '../domain/tips_repository.dart';
import '../domain/tip.dart';

/// Tipsリポジトリ実装（静的データ版）
class TipsRepositoryImpl implements TipsRepository {
  // 静的Tipsデータ
  static final List<Tip> _staticTips = [
    Tip(
      id: '1',
      title: '洗車の基本',
      description: '正しい洗車方法でコーティングを長持ちさせましょう',
      category: TipCategory.wash,
      steps: [
        '水で汚れを洗い流す',
        'カーシャンプーで優しく洗う',
        '上から下へ順番に洗う',
        '水気をしっかり拭き取る',
      ],
      priority: 10,
      createdAt: DateTime.now(),
    ),
    Tip(
      id: '2',
      title: '夏場の車内温度対策',
      description: '炎天下の車内温度上昇を防ぐ方法',
      category: TipCategory.seasonal,
      season: Season.summer,
      steps: [
        'サンシェードを使用する',
        '窓を少し開けて駐車する',
        '日陰に駐車する',
        '乗車前にエアコンで換気する',
      ],
      priority: 9,
      createdAt: DateTime.now(),
    ),
    Tip(
      id: '3',
      title: 'コーティング後の注意点',
      description: 'コーティング施工後1週間の注意事項',
      category: TipCategory.coating,
      steps: [
        '洗車は施工後48時間以降に',
        '雨に濡れても拭き取らない',
        'ワックス・艶出し剤は使用しない',
        '直射日光を避ける',
      ],
      priority: 8,
      createdAt: DateTime.now(),
    ),
    Tip(
      id: '4',
      title: '冬季の凍結対策',
      description: '冬の朝のトラブルを防ぐ準備',
      category: TipCategory.seasonal,
      season: Season.winter,
      steps: [
        'ウォッシャー液は寒冷地用に',
        'ワイパーを立てて駐車',
        'ドアゴムに保護剤を塗る',
        'バッテリーの点検',
      ],
      priority: 9,
      createdAt: DateTime.now(),
    ),
    Tip(
      id: '5',
      title: '定期メンテナンスのポイント',
      description: '愛車を長く乗るための定期チェック項目',
      category: TipCategory.maintenance,
      steps: [
        'オイル交換は5,000km毎',
        'タイヤ空気圧の確認',
        'ワイパーゴムの状態確認',
        'エアコンフィルターの交換',
      ],
      priority: 7,
      createdAt: DateTime.now(),
    ),
    Tip(
      id: '6',
      title: '花粉対策',
      description: '春の花粉から車を守る方法',
      category: TipCategory.seasonal,
      season: Season.spring,
      steps: [
        'こまめに洗車する',
        '水で流してから拭く',
        '車内換気は朝晩避ける',
        'エアコンフィルター交換',
      ],
      priority: 8,
      createdAt: DateTime.now(),
    ),
  ];

  static final List<ChecklistItem> _staticChecklists = [
    ChecklistItem(
      id: 'spring_1',
      title: '花粉除去洗車',
      description: '花粉をしっかり洗い流す',
      category: TipCategory.wash,
      season: Season.spring,
    ),
    ChecklistItem(
      id: 'spring_2',
      title: 'エアコンフィルター交換',
      description: '花粉対策のためフィルター交換',
      category: TipCategory.maintenance,
      season: Season.spring,
    ),
    ChecklistItem(
      id: 'summer_1',
      title: 'エアコン点検',
      description: '冷房の効きを確認',
      category: TipCategory.maintenance,
      season: Season.summer,
    ),
    ChecklistItem(
      id: 'summer_2',
      title: 'タイヤ空気圧チェック',
      description: '熱膨張に注意して調整',
      category: TipCategory.maintenance,
      season: Season.summer,
    ),
    ChecklistItem(
      id: 'autumn_1',
      title: '台風前の点検',
      description: 'ワイパー・ライト確認',
      category: TipCategory.maintenance,
      season: Season.autumn,
    ),
    ChecklistItem(
      id: 'autumn_2',
      title: 'コーティングメンテ',
      description: '夏のダメージ回復',
      category: TipCategory.coating,
      season: Season.autumn,
    ),
    ChecklistItem(
      id: 'winter_1',
      title: 'スタッドレスタイヤ準備',
      description: '降雪前の交換',
      category: TipCategory.maintenance,
      season: Season.winter,
    ),
    ChecklistItem(
      id: 'winter_2',
      title: 'ウォッシャー液交換',
      description: '寒冷地用に変更',
      category: TipCategory.maintenance,
      season: Season.winter,
    ),
  ];

  final Map<String, bool> _checklistCompletionStatus = {};

  @override
  Future<List<Tip>> getAllTips() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_staticTips);
  }

  @override
  Future<List<Tip>> getTipsByCategory(TipCategory category) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _staticTips.where((tip) => tip.category == category).toList();
  }

  @override
  Future<List<Tip>> getTipsBySeason(Season season) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _staticTips.where((tip) => tip.season == season).toList();
  }

  @override
  Future<List<Tip>> getRecommendedTips() async {
    await Future.delayed(const Duration(milliseconds: 200));
    final currentSeason = Season.current;

    // 優先度が高いものと現在の季節に関連するものを返す
    final tips = _staticTips.where((tip) {
      return tip.priority >= 8 || tip.season == currentSeason;
    }).toList();

    tips.sort((a, b) => b.priority.compareTo(a.priority));
    return tips.take(5).toList();
  }

  @override
  Future<List<ChecklistItem>> getSeasonalChecklist(Season season) async {
    await Future.delayed(const Duration(milliseconds: 200));

    return _staticChecklists
        .where((item) => item.season == season)
        .map((item) {
      final isCompleted = _checklistCompletionStatus[item.id] ?? false;
      return item.copyWith(isCompleted: isCompleted);
    }).toList();
  }

  @override
  Future<void> toggleChecklistItem(String itemId, bool isCompleted) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _checklistCompletionStatus[itemId] = isCompleted;
  }
}
