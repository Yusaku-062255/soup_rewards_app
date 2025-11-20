import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ユーザーIDを解決するユーティリティ
///
/// ログイン状態に応じて適切なユーザーIDを返す
/// - ログイン済み: Firebase Auth の uid
/// - ゲスト状態: 匿名認証の uid（自動的に匿名認証を実行）
class UserIdResolver {
  static const String _anonymousUserIdKey = 'anonymous_user_id';

  /// 現在のユーザーIDを取得（非同期版）
  ///
  /// 優先順位:
  /// 1. Firebase Auth の currentUser?.uid（ログイン済みの場合）
  /// 2. 匿名認証の uid（ゲスト状態の場合、自動的に匿名認証を実行）
  ///
  /// 注意: ゲスト状態でも匿名認証を行うため、常にFirebase Authのuidが返されます。
  /// これにより、デイリーくじやQRスキャンなどの機能をゲストでも利用可能にします。
  static Future<String> resolveAsync() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      // ログイン済み: Firebase Auth の uid を使用
      return currentUser.uid;
    }

    // ゲスト状態: 匿名認証を試みる
    final prefs = await SharedPreferences.getInstance();
    String? anonymousId = prefs.getString(_anonymousUserIdKey);

    if (anonymousId != null) {
      // 既に匿名認証済みのIDが保存されている場合、そのIDを返す
      // ただし、Firebase Authの状態と一致するか確認
      final authUser = FirebaseAuth.instance.currentUser;
      if (authUser != null && authUser.uid == anonymousId) {
        return anonymousId;
      }
    }

    // 匿名認証を実行
    try {
      final credential = await FirebaseAuth.instance.signInAnonymously();
      anonymousId = credential.user?.uid;

      if (anonymousId != null) {
        // 匿名IDを保存（次回起動時に使用）
        await prefs.setString(_anonymousUserIdKey, anonymousId);
        return anonymousId;
      }
    } catch (e) {
      // 匿名認証に失敗した場合（ネットワークエラーなど）
      // 既存の匿名IDがあればそれを使用、なければフォールバック
      if (anonymousId != null) {
        return anonymousId;
      }
      // 最終的なフォールバック（通常は到達しない）
      return 'localUser';
    }

    // フォールバック（通常は到達しない）
    return 'localUser';
  }

  /// 現在のユーザーIDを取得（同期版）
  ///
  /// 注意: ゲスト状態の場合は匿名認証が完了していない可能性があるため、
  /// 非同期版（resolveAsync）の使用を推奨します。
  static String resolve() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      return currentUser.uid;
    }
    // ゲスト状態で同期版を呼び出した場合は、一時的に'localUser'を返す
    // 実際の使用時は resolveAsync() を使用すること
    return 'localUser';
  }

  /// ユーザーがログイン済みかどうかを判定
  ///
  /// 注意: 匿名認証も「認証済み」として扱います。
  static bool isAuthenticated() {
    final currentUser = FirebaseAuth.instance.currentUser;
    return currentUser != null;
  }

  /// 本会員登録済みかどうかを判定
  ///
  /// 匿名認証は「本会員」ではないため、falseを返します。
  static bool isMember() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;
    // 匿名ユーザーは isAnonymous == true
    return !currentUser.isAnonymous;
  }

  /// ゲスト状態かどうかを判定
  ///
  /// 注意: 匿名認証済みでも「ゲスト」として扱います。
  static bool isGuest() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return true;
    // 匿名ユーザーはゲストとして扱う
    return currentUser.isAnonymous;
  }
}
