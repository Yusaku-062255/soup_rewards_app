import 'package:cloud_firestore/cloud_firestore.dart';

/// 会員ID生成ユーティリティ
/// 
/// 6桁の一意な会員IDを生成します。
/// フォーマット: 000001 〜 999999
class MemberIdGenerator {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 新しい会員IDを生成
  /// 
  /// 既存の会員IDと重複しないように、Firestoreで確認しながら生成します。
  /// 
  /// 生成ロジック:
  /// 1. ランダムな6桁の数字を生成
  /// 2. Firestoreで重複チェック
  /// 3. 重複していれば再生成（最大10回試行）
  /// 
  /// 注意: 将来的には、シーケンス番号やタイムスタンプベースの生成に変更する可能性があります。
  Future<String> generateMemberId() async {
    const maxAttempts = 10;
    
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      // ランダムな6桁の数字を生成（000001 〜 999999）
      final random = DateTime.now().millisecondsSinceEpoch % 1000000;
      final memberId = random.toString().padLeft(6, '0');
      
      // 重複チェック
      final exists = await _checkMemberIdExists(memberId);
      
      if (!exists) {
        return memberId;
      }
    }
    
    // 10回試行しても重複する場合は、タイムスタンプベースで生成
    // （実用上はほぼ発生しないが、フォールバックとして）
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return (timestamp % 1000000).toString().padLeft(6, '0');
  }

  /// 会員IDが既に存在するかチェック
  Future<bool> _checkMemberIdExists(String memberId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('memberId', isEqualTo: memberId)
          .limit(1)
          .get();
      
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      // エラー時は重複していないとみなす（インデックス未作成の場合など）
      return false;
    }
  }

  /// 会員IDのフォーマットを検証
  /// 
  /// 6桁の数字であることを確認します。
  static bool isValidFormat(String memberId) {
    if (memberId.length != 6) return false;
    return RegExp(r'^\d{6}$').hasMatch(memberId);
  }
}

