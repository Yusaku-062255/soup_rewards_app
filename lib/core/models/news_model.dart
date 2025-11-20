import 'package:cloud_firestore/cloud_firestore.dart';

/// ニュースモデル
class NewsModel {
  final String id;
  final String title;
  final String content;
  final String? imageUrl;
  final String? category;
  final DateTime publishedAt;

  NewsModel({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl,
    this.category,
    required this.publishedAt,
  });

  /// Firestoreから作成
  factory NewsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NewsModel(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'],
      category: data['category'],
      publishedAt:
          (data['publishedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Firestore用に変換
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (category != null) 'category': category,
      'publishedAt': Timestamp.fromDate(publishedAt),
    };
  }
}
