import 'package:json_annotation/json_annotation.dart';

part 'app_models.g.dart';

@JsonSerializable()
class ServiceModel {
  final String id;
  final String name;
  final String description;
  final String? priceRange;
  final int? durationMin;
  final List<String> gallery;
  final String? featuredImage;
  final DateTime createdAt;

  ServiceModel({
    required this.id,
    required this.name,
    required this.description,
    this.priceRange,
    this.durationMin,
    required this.gallery,
    this.featuredImage,
    required this.createdAt,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) => _$ServiceModelFromJson(json);
  Map<String, dynamic> toJson() => _$ServiceModelToJson(this);
}

@JsonSerializable()
class GalleryItem {
  final String id;
  final String title;
  final String imageUrl;
  final String? thumbnailUrl;
  final String? description;
  final DateTime createdAt;
  final bool isBeforeAfter;

  GalleryItem({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.thumbnailUrl,
    this.description,
    required this.createdAt,
    this.isBeforeAfter = false,
  });

  factory GalleryItem.fromJson(Map<String, dynamic> json) => _$GalleryItemFromJson(json);
  Map<String, dynamic> toJson() => _$GalleryItemToJson(this);
}

@JsonSerializable()
class FaqItem {
  final String id;
  final String question;
  final String answer;
  final String answerHtml;
  final int order;
  final DateTime createdAt;

  FaqItem({
    required this.id,
    required this.question,
    required this.answer,
    required this.answerHtml,
    required this.order,
    required this.createdAt,
  });

  factory FaqItem.fromJson(Map<String, dynamic> json) => _$FaqItemFromJson(json);
  Map<String, dynamic> toJson() => _$FaqItemToJson(this);
}

@JsonSerializable()
class StoreInfo {
  final String id;
  final String name;
  final String address;
  final String phoneNumber;
  final String email;
  final double latitude;
  final double longitude;
  final String? description;
  final List<String> images;

  StoreInfo({
    required this.id,
    required this.name,
    required this.address,
    required this.phoneNumber,
    required this.email,
    required this.latitude,
    required this.longitude,
    this.description,
    required this.images,
  });

  factory StoreInfo.fromJson(Map<String, dynamic> json) => _$StoreInfoFromJson(json);
  Map<String, dynamic> toJson() => _$StoreInfoToJson(this);
}
