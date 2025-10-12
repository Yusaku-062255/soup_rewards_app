import 'package:json_annotation/json_annotation.dart';

part 'wp_models.g.dart';

@JsonSerializable()
class WpPost {
  final int id;
  final String? date;
  final String? modified;
  final String? slug;
  final String? link;
  final WpTitle? title;
  final WpContent? content;
  final WpExcerpt? excerpt;
  @JsonKey(name: 'featured_media')
  final int? featuredMedia;
  final List<int>? categories;
  @JsonKey(name: '_embedded')
  final WpEmbedded? embedded;

  WpPost({
    required this.id,
    this.date,
    this.modified,
    this.slug,
    this.link,
    this.title,
    this.content,
    this.excerpt,
    this.featuredMedia,
    this.categories,
    this.embedded,
  });

  factory WpPost.fromJson(Map<String, dynamic> json) => _$WpPostFromJson(json);
  Map<String, dynamic> toJson() => _$WpPostToJson(this);
}

@JsonSerializable()
class WpPage {
  final int id;
  final String? date;
  final String? modified;
  final String? slug;
  final String? link;
  final WpTitle? title;
  final WpContent? content;
  final WpExcerpt? excerpt;

  WpPage({
    required this.id,
    this.date,
    this.modified,
    this.slug,
    this.link,
    this.title,
    this.content,
    this.excerpt,
  });

  factory WpPage.fromJson(Map<String, dynamic> json) => _$WpPageFromJson(json);
  Map<String, dynamic> toJson() => _$WpPageToJson(this);
}

@JsonSerializable()
class WpMedia {
  final int id;
  final String? date;
  final WpTitle? title;
  @JsonKey(name: 'alt_text')
  final String? altText;
  @JsonKey(name: 'source_url')
  final String? sourceUrl;
  @JsonKey(name: 'media_details')
  final WpMediaDetails? mediaDetails;

  WpMedia({
    required this.id,
    this.date,
    this.title,
    this.altText,
    this.sourceUrl,
    this.mediaDetails,
  });

  factory WpMedia.fromJson(Map<String, dynamic> json) => _$WpMediaFromJson(json);
  Map<String, dynamic> toJson() => _$WpMediaToJson(this);
}

@JsonSerializable()
class WpTitle {
  final String? rendered;

  WpTitle({this.rendered});

  factory WpTitle.fromJson(Map<String, dynamic> json) => _$WpTitleFromJson(json);
  Map<String, dynamic> toJson() => _$WpTitleToJson(this);
}

@JsonSerializable()
class WpContent {
  final String? rendered;

  WpContent({this.rendered});

  factory WpContent.fromJson(Map<String, dynamic> json) => _$WpContentFromJson(json);
  Map<String, dynamic> toJson() => _$WpContentToJson(this);
}

@JsonSerializable()
class WpExcerpt {
  final String? rendered;

  WpExcerpt({this.rendered});

  factory WpExcerpt.fromJson(Map<String, dynamic> json) => _$WpExcerptFromJson(json);
  Map<String, dynamic> toJson() => _$WpExcerptToJson(this);
}

@JsonSerializable()
class WpMediaDetails {
  final int? width;
  final int? height;
  final Map<String, WpImageSize>? sizes;

  WpMediaDetails({this.width, this.height, this.sizes});

  factory WpMediaDetails.fromJson(Map<String, dynamic> json) => _$WpMediaDetailsFromJson(json);
  Map<String, dynamic> toJson() => _$WpMediaDetailsToJson(this);
}

@JsonSerializable()
class WpImageSize {
  @JsonKey(name: 'source_url')
  final String? sourceUrl;
  final int? width;
  final int? height;

  WpImageSize({this.sourceUrl, this.width, this.height});

  factory WpImageSize.fromJson(Map<String, dynamic> json) => _$WpImageSizeFromJson(json);
  Map<String, dynamic> toJson() => _$WpImageSizeToJson(this);
}

@JsonSerializable()
class WpEmbedded {
  @JsonKey(name: 'wp:featuredmedia')
  final List<WpMedia>? featuredMedia;

  WpEmbedded({this.featuredMedia});

  factory WpEmbedded.fromJson(Map<String, dynamic> json) => _$WpEmbeddedFromJson(json);
  Map<String, dynamic> toJson() => _$WpEmbeddedToJson(this);
}
