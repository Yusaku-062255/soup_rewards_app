import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../utils/member_id_generator.dart';

/// ユーザーリポジトリ
class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 現在のユーザーIDを取得
  String? get currentUserId => _auth.currentUser?.uid;

  /// ユーザー情報を取得
  Future<UserModel?> getUser(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('ユーザー情報の取得に失敗しました: $e');
    }
  }

  /// 現在のユーザー情報を取得
  Future<UserModel?> getCurrentUser() async {
    final userId = currentUserId;
    if (userId == null) return null;
    return getUser(userId);
  }

  /// ユーザー情報を作成
  Future<void> createUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).set(user.toFirestore());
    } catch (e) {
      throw Exception('ユーザー情報の作成に失敗しました: $e');
    }
  }

  /// ユーザー情報を更新
  Future<void> updateUser(UserModel user) async {
    try {
      final updatedUser = user.copyWith(updatedAt: DateTime.now());
      await _firestore
          .collection('users')
          .doc(user.id)
          .update(updatedUser.toFirestore());
    } catch (e) {
      throw Exception('ユーザー情報の更新に失敗しました: $e');
    }
  }

  /// ポイントを更新
  Future<void> updatePoints(String userId, int newPoints) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'points': newPoints,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('ポイントの更新に失敗しました: $e');
    }
  }

  /// ユーザー情報をリアルタイムで監視
  Stream<UserModel?> watchUser(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  /// 現在のユーザー情報をリアルタイムで監視
  Stream<UserModel?> watchCurrentUser() {
    final userId = currentUserId;
    if (userId == null) return Stream.value(null);
    return watchUser(userId);
  }

  /// 会員IDを生成
  ///
  /// 新規登録時に呼び出されます。
  /// 6桁の一意な会員IDを生成します。
  Future<String> generateMemberId() async {
    final generator = MemberIdGenerator();
    return generator.generateMemberId();
  }
}
