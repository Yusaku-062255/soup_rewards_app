import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/wp_models.dart';

class WordPressApiService {
  static const String _baseUrl = 'https://soup.tokushima.jp';
  static const Duration _timeout = Duration(seconds: 30);
  static const Duration _cacheExpiry = Duration(days: 7);
  
  final http.Client _client;
  final SharedPreferences _prefs;

  WordPressApiService({
    http.Client? client,
    required SharedPreferences prefs,
  }) : _client = client ?? http.Client(),
        _prefs = prefs;

  Future<dynamic> _get(String endpoint, {Map<String, String>? queryParams}) async {
    final cacheKey = 'wp_cache_${endpoint}_${queryParams.toString()}';
    
    // キャッシュから取得を試行
    final cachedItem = await _getCachedData(cacheKey);
    if (cachedItem != null) {
      return json.decode(cachedItem);
    }

    // ネットワークから取得
    try {
      final uri = Uri.parse('$_baseUrl/wp-json/wp/v2$endpoint');
      final finalUri = queryParams != null ? uri.replace(queryParameters: queryParams) : uri;

      final response = await _client.get(finalUri, headers: {
        'Accept': 'application/json',
        'User-Agent': 'SOUP-Rewards-App/1.0.0',
      }).timeout(_timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // キャッシュに保存
        await _setCachedData(cacheKey, response.body);
        return json.decode(response.body);
      } else {
        throw HttpException('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } on SocketException {
      throw Exception('インターネット接続を確認してください');
    } on HttpException {
      rethrow;
    } catch (e) {
      throw Exception('APIリクエストに失敗しました: $e');
    }
  }

  Future<List<WpPost>> getPosts({
    int page = 1,
    int perPage = 10,
    List<int>? categories,
    String? search,
    bool includeEmbedded = true,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
      if (categories != null && categories.isNotEmpty) 'categories': categories.join(','),
      if (search != null && search.isNotEmpty) 'search': search,
      if (includeEmbedded) '_embed': '1',
    };

    try {
      final response = await _get('/posts', queryParams: queryParams);
      if (response is List) {
        return response.map((json) => WpPost.fromJson(json as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching posts: $e');
      return [];
    }
  }

  Future<List<WpPage>> getPages({
    int page = 1,
    int perPage = 100,
    bool includeEmbedded = true,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
      if (includeEmbedded) '_embed': '1',
    };

    try {
      final response = await _get('/pages', queryParams: queryParams);
      if (response is List) {
        return response.map((json) => WpPage.fromJson(json as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching pages: $e');
      return [];
    }
  }

  Future<List<WpMedia>> getMedia({
    int page = 1,
    int perPage = 50,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };

    try {
      final response = await _get('/media', queryParams: queryParams);
      if (response is List) {
        return response.map((json) => WpMedia.fromJson(json as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching media: $e');
      return [];
    }
  }

  Future<WpPost?> getPost(int id, {bool includeEmbedded = true}) async {
    try {
      final response = await _get('/posts/$id', queryParams: includeEmbedded ? {'_embed': '1'} : null);
      return WpPost.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('Error fetching post $id: $e');
      return null;
    }
  }

  Future<WpPage?> getPageBySlug(String slug, {bool includeEmbedded = true}) async {
    try {
      final queryParams = <String, String>{
        'slug': slug,
        if (includeEmbedded) '_embed': '1',
      };
      final response = await _get('/pages', queryParams: queryParams);
      if (response is List && response.isNotEmpty) {
        return WpPage.fromJson(response.first as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error fetching page by slug $slug: $e');
      return null;
    }
  }

  // キャッシュ管理
  Future<String?> _getCachedData(String key) async {
    try {
      final expiresAt = _prefs.getInt('${key}_expiry');
      if (expiresAt == null || DateTime.now().millisecondsSinceEpoch > expiresAt) {
        await _clearCache(key);
        return null;
      }
      return _prefs.getString(key);
    } catch (e) {
      return null;
    }
  }

  Future<void> _setCachedData(String key, String data) async {
    try {
      final expiryTime = DateTime.now().add(_cacheExpiry).millisecondsSinceEpoch;
      await _prefs.setString(key, data);
      await _prefs.setInt('${key}_expiry', expiryTime);
    } catch (e) {
      // キャッシュエラーは無視
    }
  }

  Future<void> _clearCache(String key) async {
    try {
      await _prefs.remove(key);
      await _prefs.remove('${key}_expiry');
    } catch (e) {
      // キャッシュエラーは無視
    }
  }

  Future<void> clearAllCache() async {
    try {
      final keys = _prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith('wp_cache_')) {
          await _prefs.remove(key);
        }
      }
    } catch (e) {
      // キャッシュエラーは無視
    }
  }

  void dispose() {
    _client.close();
  }
}
