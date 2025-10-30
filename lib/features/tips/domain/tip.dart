import 'package:cloud_firestore/cloud_firestore.dart';

/// アフターケアTipsモデル
class Tip {
  final String id;
  final String title;
  final String description;
  final TipCategory category;
  final Season? season;
  final String? imageUrl;
  final List<String> steps;
  final int priority;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Tip({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.season,
    this.imageUrl,
    this.steps = const [],
    this.priority = 0,
    required this.createdAt,
    this.updatedAt,
  });

  factory Tip.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Tip.fromJson(data, doc.id);
  }

  factory Tip.fromJson(Map<String, dynamic> json, String id) {
    return Tip(
      id: id,
      title: json['title'] as String,
      description: json['description'] as String,
      category: TipCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => TipCategory.general,
      ),
      season: json['season'] != null
          ? Season.values.firstWhere(
              (e) => e.name == json['season'],
              orElse: () => Season.spring,
            )
          : null,
      imageUrl: json['imageUrl'] as String?,
      steps: (json['steps'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      priority: json['priority'] as int? ?? 0,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category': category.name,
      if (season != null) 'season': season!.name,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'steps': steps,
      'priority': priority,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  @override
  String toString() {
    return 'Tip(id: $id, title: $title, category: ${category.displayName})';
  }
}

/// Tipsカテゴリ
enum TipCategory {
  wash('洗車', '🚿'),
  coating('コーティング', '🛡️'),
  maintenance('メンテナンス', '🔧'),
  seasonal('季節のケア', '🌸'),
  general('一般', '💡');

  final String displayName;
  final String emoji;

  const TipCategory(this.displayName, this.emoji);
}

/// 季節
enum Season {
  spring('春', '🌸'),
  summer('夏', '☀️'),
  autumn('秋', '🍂'),
  winter('冬', '❄️');

  final String displayName;
  final String emoji;

  const Season(this.displayName, this.emoji);

  /// 現在の季節を取得
  static Season get current {
    final now = DateTime.now();
    final month = now.month;

    if (month >= 3 && month <= 5) return Season.spring;
    if (month >= 6 && month <= 8) return Season.summer;
    if (month >= 9 && month <= 11) return Season.autumn;
    return Season.winter;
  }
}

/// チェックリストアイテム
class ChecklistItem {
  final String id;
  final String title;
  final String description;
  final TipCategory category;
  final Season season;
  final bool isCompleted;

  const ChecklistItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.season,
    this.isCompleted = false,
  });

  ChecklistItem copyWith({
    bool? isCompleted,
  }) {
    return ChecklistItem(
      id: id,
      title: title,
      description: description,
      category: category,
      season: season,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  factory ChecklistItem.fromJson(Map<String, dynamic> json, String id) {
    return ChecklistItem(
      id: id,
      title: json['title'] as String,
      description: json['description'] as String,
      category: TipCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => TipCategory.general,
      ),
      season: Season.values.firstWhere(
        (e) => e.name == json['season'],
        orElse: () => Season.spring,
      ),
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category': category.name,
      'season': season.name,
      'isCompleted': isCompleted,
    };
  }
}
