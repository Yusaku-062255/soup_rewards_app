// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wp_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WpPost _$WpPostFromJson(Map<String, dynamic> json) => WpPost(
      id: (json['id'] as num).toInt(),
      date: json['date'] as String?,
      modified: json['modified'] as String?,
      slug: json['slug'] as String?,
      link: json['link'] as String?,
      title: json['title'] == null
          ? null
          : WpTitle.fromJson(json['title'] as Map<String, dynamic>),
      content: json['content'] == null
          ? null
          : WpContent.fromJson(json['content'] as Map<String, dynamic>),
      excerpt: json['excerpt'] == null
          ? null
          : WpExcerpt.fromJson(json['excerpt'] as Map<String, dynamic>),
      featuredMedia: (json['featured_media'] as num?)?.toInt(),
      categories: (json['categories'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
      embedded: json['_embedded'] == null
          ? null
          : WpEmbedded.fromJson(json['_embedded'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$WpPostToJson(WpPost instance) => <String, dynamic>{
      'id': instance.id,
      'date': instance.date,
      'modified': instance.modified,
      'slug': instance.slug,
      'link': instance.link,
      'title': instance.title,
      'content': instance.content,
      'excerpt': instance.excerpt,
      'featured_media': instance.featuredMedia,
      'categories': instance.categories,
      '_embedded': instance.embedded,
    };

WpPage _$WpPageFromJson(Map<String, dynamic> json) => WpPage(
      id: (json['id'] as num).toInt(),
      date: json['date'] as String?,
      modified: json['modified'] as String?,
      slug: json['slug'] as String?,
      link: json['link'] as String?,
      title: json['title'] == null
          ? null
          : WpTitle.fromJson(json['title'] as Map<String, dynamic>),
      content: json['content'] == null
          ? null
          : WpContent.fromJson(json['content'] as Map<String, dynamic>),
      excerpt: json['excerpt'] == null
          ? null
          : WpExcerpt.fromJson(json['excerpt'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$WpPageToJson(WpPage instance) => <String, dynamic>{
      'id': instance.id,
      'date': instance.date,
      'modified': instance.modified,
      'slug': instance.slug,
      'link': instance.link,
      'title': instance.title,
      'content': instance.content,
      'excerpt': instance.excerpt,
    };

WpMedia _$WpMediaFromJson(Map<String, dynamic> json) => WpMedia(
      id: (json['id'] as num).toInt(),
      date: json['date'] as String?,
      title: json['title'] == null
          ? null
          : WpTitle.fromJson(json['title'] as Map<String, dynamic>),
      altText: json['alt_text'] as String?,
      sourceUrl: json['source_url'] as String?,
      mediaDetails: json['media_details'] == null
          ? null
          : WpMediaDetails.fromJson(
              json['media_details'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$WpMediaToJson(WpMedia instance) => <String, dynamic>{
      'id': instance.id,
      'date': instance.date,
      'title': instance.title,
      'alt_text': instance.altText,
      'source_url': instance.sourceUrl,
      'media_details': instance.mediaDetails,
    };

WpTitle _$WpTitleFromJson(Map<String, dynamic> json) => WpTitle(
      rendered: json['rendered'] as String?,
    );

Map<String, dynamic> _$WpTitleToJson(WpTitle instance) => <String, dynamic>{
      'rendered': instance.rendered,
    };

WpContent _$WpContentFromJson(Map<String, dynamic> json) => WpContent(
      rendered: json['rendered'] as String?,
    );

Map<String, dynamic> _$WpContentToJson(WpContent instance) => <String, dynamic>{
      'rendered': instance.rendered,
    };

WpExcerpt _$WpExcerptFromJson(Map<String, dynamic> json) => WpExcerpt(
      rendered: json['rendered'] as String?,
    );

Map<String, dynamic> _$WpExcerptToJson(WpExcerpt instance) => <String, dynamic>{
      'rendered': instance.rendered,
    };

WpMediaDetails _$WpMediaDetailsFromJson(Map<String, dynamic> json) =>
    WpMediaDetails(
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
      sizes: (json['sizes'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, WpImageSize.fromJson(e as Map<String, dynamic>)),
      ),
    );

Map<String, dynamic> _$WpMediaDetailsToJson(WpMediaDetails instance) =>
    <String, dynamic>{
      'width': instance.width,
      'height': instance.height,
      'sizes': instance.sizes,
    };

WpImageSize _$WpImageSizeFromJson(Map<String, dynamic> json) => WpImageSize(
      sourceUrl: json['source_url'] as String?,
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
    );

Map<String, dynamic> _$WpImageSizeToJson(WpImageSize instance) =>
    <String, dynamic>{
      'source_url': instance.sourceUrl,
      'width': instance.width,
      'height': instance.height,
    };

WpEmbedded _$WpEmbeddedFromJson(Map<String, dynamic> json) => WpEmbedded(
      featuredMedia: (json['wp:featuredmedia'] as List<dynamic>?)
          ?.map((e) => WpMedia.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$WpEmbeddedToJson(WpEmbedded instance) =>
    <String, dynamic>{
      'wp:featuredmedia': instance.featuredMedia,
    };
