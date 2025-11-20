import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/user_model.dart';
import '../../../core/repositories/user_repository.dart';

/// 管理画面用ユーザーリポジトリ
/// 
/// 既存のUserRepositoryを拡張し、管理画面で必要な機能を追加
/// 
/// 注意: このリポジトリは管理画面専用です。
/// モバイルアプリ側のUserRepositoryとは独立して動作します。
class AdminUserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserRepository _userRepository = UserRepository();

  /// 会員ID（6桁）でユーザーを検索
  /// 
  /// [memberId] 6桁の会員ID
  /// 
  /// FirestoreのusersコレクションにmemberIdフィールドがある前提で実装
  /// 
  /// TODO: 会員IDのインデックスを作成する必要がある場合がある
  /// firestore.indexes.json に以下を追加:
  /// {
  ///   "collectionGroup": "users",
  ///   "queryScope": "COLLECTION",
  ///   "fields": [
  ///     { "fieldPath": "memberId", "order": "ASCENDING" }
  ///   ]
  /// }
  Future<UserModel?> searchByMemberId(String memberId) async {
    try {
      // memberIdフィールドで検索（インデックスが必要）
      final snapshot = await _firestore
          .collection('users')
          .where('memberId', isEqualTo: memberId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      return UserModel.fromFirestore(snapshot.docs.first);
    } catch (e) {
      // インデックスが存在しない場合など、エラーが発生する可能性がある
      // フォールバック: 全ユーザーを取得してフィルタリング（非効率だが動作する）
      try {
        final snapshot = await _firestore.collection('users').get();
        
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final docMemberId = data['memberId'] as String?;
          if (docMemberId == memberId) {
            return UserModel.fromFirestore(doc);
          }
        }
        
        return null;
      } catch (fallbackError) {
        throw Exception('会員ID検索に失敗しました: $e');
      }
    }
  }

  /// 名前で部分一致検索
  /// 
  /// [name] 検索する名前（部分一致）
  /// 
  /// 注意: Firestoreの部分一致検索は制限があるため、
  /// 全ユーザーを取得してクライアント側でフィルタリング
  /// 
  /// TODO: 将来的にはAlgoliaなどの全文検索サービスを検討
  Future<List<UserModel>> searchByName(String name) async {
    try {
      final snapshot = await _firestore.collection('users').get();
      final results = <UserModel>[];
      
      for (var doc in snapshot.docs) {
        final user = UserModel.fromFirestore(doc);
        if (user.name.toLowerCase().contains(name.toLowerCase())) {
          results.add(user);
        }
      }
      
      return results;
    } catch (e) {
      throw Exception('名前検索に失敗しました: $e');
    }
  }

  /// 電話番号で検索
  /// 
  /// [phoneNumber] 電話番号（完全一致）
  /// 
  /// TODO: 電話番号の正規化（ハイフン除去など）を実装
  Future<List<UserModel>> searchByPhoneNumber(String phoneNumber) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .get();
      
      return snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('電話番号検索に失敗しました: $e');
    }
  }

  /// ユーザー情報を取得（既存のUserRepositoryをラップ）
  Future<UserModel?> getUser(String userId) async {
    return _userRepository.getUser(userId);
  }

  /// 最終来店日を取得
  /// 
  /// users/{userId} の lastVisitDate フィールドから取得
  /// 
  /// 注意: このフィールドはポイント付与時に更新されます
  Future<DateTime?> getLastVisitDate(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      
      if (!doc.exists) return null;
      
      final data = doc.data();
      final timestamp = data?['lastVisitDate'] as Timestamp?;
      return timestamp?.toDate();
    } catch (e) {
      // エラー時はnullを返す
      return null;
    }
  }

  /// 累計来店回数を取得
  /// 
  /// users/{userId} の visitCount フィールドから取得
  /// 
  /// 注意: このフィールドはポイント付与時に +1 されます
  Future<int> getTotalVisitCount(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      
      if (!doc.exists) return 0;
      
      final data = doc.data();
      return data?['visitCount'] as int? ?? 0;
    } catch (e) {
      return 0;
    }
  }
}
