import 'package:firebase_auth/firebase_auth.dart';

/// Firebase認証エラーを日本語メッセージに変換するユーティリティ
class AuthErrorMapper {
  /// Firebase認証エラーを日本語メッセージに変換
  static String mapFirebaseAuthException(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'このメールアドレスは登録されていません。';
        case 'wrong-password':
          return 'パスワードが正しくありません。';
        case 'email-already-in-use':
          return 'このメールアドレスは既に使用されています。';
        case 'invalid-email':
          return 'メールアドレスの形式が正しくありません。';
        case 'weak-password':
          return 'パスワードが弱すぎます。6文字以上で設定してください。';
        case 'operation-not-allowed':
          return 'このログイン方法は現在利用できません。';
        case 'user-disabled':
          return 'このアカウントは無効化されています。';
        case 'too-many-requests':
          return 'リクエストが多すぎます。しばらく待ってから再度お試しください。';
        case 'network-request-failed':
          return 'ネットワークエラーが発生しました。インターネット接続を確認してください。';
        default:
          return 'メールアドレスまたはパスワードが正しくないか、このログイン方法が無効です。';
      }
    }
    
    // FirebaseAuthException以外のエラー
    final errorString = error.toString().toLowerCase();
    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'ネットワークエラーが発生しました。インターネット接続を確認してください。';
    }
    
    return 'エラーが発生しました。もう一度お試しください。';
  }
}

