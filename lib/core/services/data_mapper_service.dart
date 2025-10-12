import '../models/wp_models.dart';
import '../models/app_models.dart';

class DataMapperService {
  static String stripHtmlTags(String htmlString) {
    final RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    return htmlString.replaceAll(exp, '').trim();
  }

  static List<ServiceModel> mapPostsToServices(List<WpPost> posts) {
    return posts.map((post) => mapPostToService(post)).where((service) => service != null).cast<ServiceModel>().toList();
  }

  static ServiceModel? mapPostToService(WpPost post) {
    try {
      final title = post.title?.rendered ?? '';
      final content = post.content?.rendered ?? '';
      final excerpt = post.excerpt?.rendered ?? '';
      
      if (title.isEmpty) return null;

      // 価格情報を抽出（簡易的な実装）
      String? priceRange;
      final priceMatch = RegExp(r'(\d+[,\d]*円)').firstMatch(content);
      if (priceMatch != null) {
        priceRange = priceMatch.group(1);
      }

      // 所要時間を抽出（簡易的な実装）
      int? durationMin;
      final durationMatch = RegExp(r'(\d+)分').firstMatch(content);
      if (durationMatch != null) {
        durationMin = int.tryParse(durationMatch.group(1) ?? '');
      }

      // 画像URLを取得
      String? featuredImage;
      final gallery = <String>[];
      
      if (post.embedded?.featuredMedia != null && post.embedded!.featuredMedia!.isNotEmpty) {
        featuredImage = post.embedded!.featuredMedia!.first.sourceUrl;
        if (featuredImage != null) {
          gallery.add(featuredImage);
        }
      }

      return ServiceModel(
        id: post.id.toString(),
        name: stripHtmlTags(title),
        description: stripHtmlTags(excerpt),
        priceRange: priceRange,
        durationMin: durationMin,
        gallery: gallery,
        featuredImage: featuredImage,
        createdAt: DateTime.tryParse(post.date ?? '') ?? DateTime.now(),
      );
    } catch (e) {
      print('Error mapping post to service: $e');
      return null;
    }
  }

  static List<GalleryItem> mapMediaToGalleryItems(List<WpMedia> mediaList) {
    return mediaList.map((media) => mapMediaToGalleryItem(media)).where((item) => item != null).cast<GalleryItem>().toList();
  }

  static GalleryItem? mapMediaToGalleryItem(WpMedia media) {
    try {
      final title = media.title?.rendered ?? '';
      final imageUrl = media.sourceUrl;
      
      if (imageUrl == null || imageUrl.isEmpty) return null;

      // サムネイルURLを取得
      String? thumbnailUrl;
      if (media.mediaDetails?.sizes != null) {
        final sizes = media.mediaDetails!.sizes!;
        thumbnailUrl = sizes['medium']?.sourceUrl ?? sizes['thumbnail']?.sourceUrl ?? imageUrl;
      }

      // ビフォーアフター画像かどうかを判定
      final isBeforeAfter = title.toLowerCase().contains('before') || 
                           title.toLowerCase().contains('after') ||
                           title.toLowerCase().contains('ビフォー') ||
                           title.toLowerCase().contains('アフター');

      return GalleryItem(
        id: media.id.toString(),
        title: stripHtmlTags(title),
        imageUrl: imageUrl,
        thumbnailUrl: thumbnailUrl,
        description: media.altText,
        createdAt: DateTime.tryParse(media.date ?? '') ?? DateTime.now(),
        isBeforeAfter: isBeforeAfter,
      );
    } catch (e) {
      print('Error mapping media to gallery item: $e');
      return null;
    }
  }

  static List<FaqItem> mapPagesToFaqItems(List<WpPage> pages) {
    return pages
        .where((page) => _isFaqPage(page))
        .map((page) => mapPageToFaqItem(page))
        .where((item) => item != null)
        .cast<FaqItem>()
        .toList();
  }

  static bool _isFaqPage(WpPage page) {
    final title = page.title?.rendered?.toLowerCase() ?? '';
    final slug = page.slug?.toLowerCase() ?? '';
    return title.contains('faq') || 
           title.contains('よくある質問') || 
           slug.contains('faq') ||
           slug.contains('question');
  }

  static FaqItem? mapPageToFaqItem(WpPage page) {
    try {
      final title = page.title?.rendered ?? '';
      final content = page.content?.rendered ?? '';
      
      if (title.isEmpty || content.isEmpty) return null;

      return FaqItem(
        id: page.id.toString(),
        question: stripHtmlTags(title),
        answer: stripHtmlTags(content),
        answerHtml: content,
        order: page.id,
        createdAt: DateTime.tryParse(page.date ?? '') ?? DateTime.now(),
      );
    } catch (e) {
      print('Error mapping page to FAQ item: $e');
      return null;
    }
  }

  static StoreInfo? mapPageToStoreInfo(WpPage page) {
    try {
      final title = page.title?.rendered ?? '';
      final content = page.content?.rendered ?? '';
      
      if (title.isEmpty) return null;

      // 住所を抽出（簡易的な実装）
      String address = '徳島県徳島市';
      final addressMatch = RegExp(r'徳島県[^<\n]+').firstMatch(content);
      if (addressMatch != null) {
        address = addressMatch.group(0) ?? address;
      }

      // 電話番号を抽出
      String phoneNumber = '0883-22-8655';
      final phoneMatch = RegExp(r'0\d{1,4}-\d{1,4}-\d{4}').firstMatch(content);
      if (phoneMatch != null) {
        phoneNumber = phoneMatch.group(0) ?? phoneNumber;
      }

      return StoreInfo(
        id: page.id.toString(),
        name: stripHtmlTags(title),
        address: address,
        phoneNumber: phoneNumber,
        email: 'info@soup.tokushima.jp',
        latitude: 34.0658, // 徳島市の緯度
        longitude: 134.5594, // 徳島市の経度
        description: stripHtmlTags(content),
        images: [],
      );
    } catch (e) {
      print('Error mapping page to store info: $e');
      return null;
    }
  }
}
