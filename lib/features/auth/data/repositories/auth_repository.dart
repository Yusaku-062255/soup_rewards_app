import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../domain/models/app_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
    functions: FirebaseFunctions.instanceFor(region: 'asia-northeast1'),
  );
});

class AuthRepository {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  final FirebaseFunctions functions;

  AuthRepository({
    required this.auth,
    required this.firestore,
    required this.functions,
  });

  /// 認証状態のストリーム
  Stream<User?> get authStateChanges => auth.authStateChanges();

  /// 現在のユーザー
  User? get currentUser => auth.currentUser;

  /// AppUserのストリーム
  Stream<AppUser?> userStream(String uid) {
    return firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return AppUser.fromFirestore(doc);
    });
  }

  /// 匿名ログイン
  Future<UserCredential> signInAnonymously() async {
    return await auth.signInAnonymously();
  }

  /// Apple Sign-In（匿名アカウントにリンク、または新規サインイン）
  Future<UserCredential> signInWithApple({bool link = false}) async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      UserCredential userCredential;
      if (link && currentUser != null && currentUser!.isAnonymous) {
        // 匿名アカウントにリンク
        try {
          userCredential = await currentUser!.linkWithCredential(oauthCredential);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'credential-already-in-use') {
            // 既に使用されているクレデンシャルの場合、サインインに切り替え
            userCredential = await auth.signInWithCredential(oauthCredential);
          } else {
            rethrow;
          }
        }
      } else {
        // 新規サインイン
        userCredential = await auth.signInWithCredential(oauthCredential);
      }

      // プロフィール更新をCloud Functionで実行
      await updateProfileAfterLink();

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  /// Emailでサインアップ（匿名アカウントにリンク）
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    bool link = false,
  }) async {
    final emailCredential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );

    UserCredential userCredential;
    if (link && currentUser != null && currentUser!.isAnonymous) {
      // 匿名アカウントにリンク
      try {
        userCredential = await currentUser!.linkWithCredential(emailCredential);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'credential-already-in-use') {
          // 既に使用されているクレデンシャルの場合、サインインに切り替え
          userCredential = await auth.signInWithCredential(emailCredential);
        } else {
          rethrow;
        }
      }
    } else {
      // 新規サインアップ
      userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    }

    // メール確認送信
    await userCredential.user?.sendEmailVerification();

    // プロフィール更新
    await updateProfileAfterLink();

    return userCredential;
  }

  /// Emailでログイン
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// サインアウト
  Future<void> signOut() async {
    await auth.signOut();
  }

  /// プロフィール更新（Callable Function）
  Future<void> updateProfileAfterLink() async {
    try {
      final callable = functions.httpsCallable('updateProfileAfterLink');
      await callable.call();
    } catch (e) {
      // Functionが存在しない場合のフォールバック処理
      // 本番では必ずFunctionを用意する
      print('updateProfileAfterLink failed: $e');
    }
  }

  /// プロフィール編集
  Future<void> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    if (currentUser == null) return;

    // Firebase Auth更新
    if (displayName != null) {
      await currentUser!.updateDisplayName(displayName);
    }
    if (photoURL != null) {
      await currentUser!.updatePhotoURL(photoURL);
    }

    // Firestore更新
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (displayName != null) updates['displayName'] = displayName;
    if (photoURL != null) updates['photoURL'] = photoURL;

    await firestore.collection('users').doc(currentUser!.uid).update(updates);
  }

  /// 通知設定更新
  Future<void> updateNotificationSettings({
    required bool enabled,
    String? token,
  }) async {
    if (currentUser == null) return;

    final updates = <String, dynamic>{
      'notificationEnabled': enabled,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (token != null) {
      updates['notificationToken'] = token;
    }

    await firestore.collection('users').doc(currentUser!.uid).update(updates);
  }

  /// アカウント削除（論理削除）
  Future<void> deleteAccount() async {
    try {
      final callable = functions.httpsCallable('softDeleteAccount');
      await callable.call();
    } catch (e) {
      // Functionが存在しない場合のフォールバック処理
      print('softDeleteAccount failed: $e');
      rethrow;
    }
  }
}
