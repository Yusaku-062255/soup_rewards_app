// 車両情報モデル
import 'dart:convert';

class VehicleModel {
  final String name;           // 車名（必須）
  final String manufacturer;   // メーカー
  final int? year;            // 年式
  final String? plateNumber;  // ナンバー（任意・非保存でも可）
  final bool isEv;            // EVかどうか
  final String? photoPath;    // 車の写真パス

  const VehicleModel({
    required this.name,
    this.manufacturer = '',
    this.year,
    this.plateNumber,
    this.isEv = false,
    this.photoPath,
  });

  // JSON変換
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'manufacturer': manufacturer,
      'year': year,
      'plateNumber': plateNumber,
      'isEv': isEv,
      'photoPath': photoPath,
    };
  }

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      name: json['name'] ?? '',
      manufacturer: json['manufacturer'] ?? '',
      year: json['year'],
      plateNumber: json['plateNumber'],
      isEv: json['isEv'] ?? false,
      photoPath: json['photoPath'],
    );
  }

  // JSON文字列変換
  String toJsonString() => jsonEncode(toJson());

  factory VehicleModel.fromJsonString(String jsonString) {
    return VehicleModel.fromJson(jsonDecode(jsonString));
  }

  // コピー作成
  VehicleModel copyWith({
    String? name,
    String? manufacturer,
    int? year,
    String? plateNumber,
    bool? isEv,
    String? photoPath,
  }) {
    return VehicleModel(
      name: name ?? this.name,
      manufacturer: manufacturer ?? this.manufacturer,
      year: year ?? this.year,
      plateNumber: plateNumber ?? this.plateNumber,
      isEv: isEv ?? this.isEv,
      photoPath: photoPath ?? this.photoPath,
    );
  }

  // バリデーション
  bool get isValid {
    return name.trim().isNotEmpty && 
           (year == null || (year! >= 1900 && year! <= DateTime.now().year));
  }

  // 表示用文字列
  String get displayName {
    if (manufacturer.isNotEmpty) {
      return '$manufacturer $name';
    }
    return name;
  }

  String get displayYear {
    return year != null ? '${year}年式' : '年式不明';
  }

  String get displayType {
    return isEv ? 'EV' : 'ガソリン車';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VehicleModel &&
        other.name == name &&
        other.manufacturer == manufacturer &&
        other.year == year &&
        other.plateNumber == plateNumber &&
        other.isEv == isEv &&
        other.photoPath == photoPath;
  }

  @override
  int get hashCode {
    return Object.hash(
      name,
      manufacturer,
      year,
      plateNumber,
      isEv,
      photoPath,
    );
  }

  @override
  String toString() {
    return 'VehicleModel(name: $name, manufacturer: $manufacturer, year: $year, isEv: $isEv)';
  }
}
