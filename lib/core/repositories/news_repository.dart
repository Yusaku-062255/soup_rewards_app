import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/news_model.dart';

/// ニュースリポジトリ
class NewsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 最新のニュースを取得
  Future<List<NewsModel>> getLatestNews({int? limit}) async {
    try {
      Query query = _firestore
          .collection('news')
          .orderBy('publishedAt', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => NewsModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('ニュースの取得に失敗しました: $e');
    }
  }

  /// ニュースをIDで取得
  Future<NewsModel?> getNews(String newsId) async {
    try {
      final doc = await _firestore.collection('news').doc(newsId).get();
      if (!doc.exists) return null;
      return NewsModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('ニュースの取得に失敗しました: $e');
    }
  }

  /// 最新のニュースをリアルタイムで監視
  Stream<List<NewsModel>> watchLatestNews({int? limit}) {
    Query query =
        _firestore.collection('news').orderBy('publishedAt', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => NewsModel.fromFirestore(doc)).toList());
  }
}
