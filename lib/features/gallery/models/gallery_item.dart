/// 施工実績ギャラリーアイテムのモデル
class GalleryItem {
  final String id;
  final String title;
  final String description;
  final VehicleInfo vehicle;
  final String service;
  final String beforeImage;
  final String afterImage;
  final DateTime date;
  final List<String> tags;

  GalleryItem({
    required this.id,
    required this.title,
    required this.description,
    required this.vehicle,
    required this.service,
    required this.beforeImage,
    required this.afterImage,
    required this.date,
    required this.tags,
  });

  factory GalleryItem.fromJson(Map<String, dynamic> json) {
    return GalleryItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      vehicle: VehicleInfo.fromJson(json['vehicle'] ?? {}),
      service: json['service'] ?? '',
      beforeImage: json['before_image'] ?? '',
      afterImage: json['after_image'] ?? '',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'vehicle': vehicle.toJson(),
      'service': service,
      'before_image': beforeImage,
      'after_image': afterImage,
      'date': date.toIso8601String(),
      'tags': tags,
    };
  }
}

/// 車両情報
class VehicleInfo {
  final String make;
  final String model;
  final int year;
  final String color;

  VehicleInfo({
    required this.make,
    required this.model,
    required this.year,
    required this.color,
  });

  factory VehicleInfo.fromJson(Map<String, dynamic> json) {
    return VehicleInfo(
      make: json['make'] ?? '',
      model: json['model'] ?? '',
      year: json['year'] ?? DateTime.now().year,
      color: json['color'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'make': make,
      'model': model,
      'year': year,
      'color': color,
    };
  }

  String get displayName => '$make $model';
}
