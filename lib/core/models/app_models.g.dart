// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServiceModel _$ServiceModelFromJson(Map<String, dynamic> json) => ServiceModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      priceRange: json['priceRange'] as String?,
      durationMin: (json['durationMin'] as num?)?.toInt(),
      gallery:
          (json['gallery'] as List<dynamic>).map((e) => e as String).toList(),
      featuredImage: json['featuredImage'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$ServiceModelToJson(ServiceModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'priceRange': instance.priceRange,
      'durationMin': instance.durationMin,
      'gallery': instance.gallery,
      'featuredImage': instance.featuredImage,
      'createdAt': instance.createdAt.toIso8601String(),
    };

GalleryItem _$GalleryItemFromJson(Map<String, dynamic> json) => GalleryItem(
      id: json['id'] as String,
      title: json['title'] as String,
      imageUrl: json['imageUrl'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isBeforeAfter: json['isBeforeAfter'] as bool? ?? false,
    );

Map<String, dynamic> _$GalleryItemToJson(GalleryItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'imageUrl': instance.imageUrl,
      'thumbnailUrl': instance.thumbnailUrl,
      'description': instance.description,
      'createdAt': instance.createdAt.toIso8601String(),
      'isBeforeAfter': instance.isBeforeAfter,
    };

FaqItem _$FaqItemFromJson(Map<String, dynamic> json) => FaqItem(
      id: json['id'] as String,
      question: json['question'] as String,
      answer: json['answer'] as String,
      answerHtml: json['answerHtml'] as String,
      order: (json['order'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$FaqItemToJson(FaqItem instance) => <String, dynamic>{
      'id': instance.id,
      'question': instance.question,
      'answer': instance.answer,
      'answerHtml': instance.answerHtml,
      'order': instance.order,
      'createdAt': instance.createdAt.toIso8601String(),
    };

StoreInfo _$StoreInfoFromJson(Map<String, dynamic> json) => StoreInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      phoneNumber: json['phoneNumber'] as String,
      email: json['email'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      description: json['description'] as String?,
      images:
          (json['images'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$StoreInfoToJson(StoreInfo instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'address': instance.address,
      'phoneNumber': instance.phoneNumber,
      'email': instance.email,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'description': instance.description,
      'images': instance.images,
    };
