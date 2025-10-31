import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final pointsRepositoryProvider = Provider<PointsRepository>((ref) {
  return PointsRepository(
    firestore: FirebaseFirestore.instance,
    functions: FirebaseFunctions.instanceFor(region: 'asia-northeast1'),
  );
});

/// Point entry model
class PointEntry {
  final String id;
  final String type;
  final int delta;
  final String note;
  final DateTime createdAt;

  PointEntry({
    required this.id,
    required this.type,
    required this.delta,
    required this.note,
    required this.createdAt,
  });

  factory PointEntry.fromFirestore(String id, Map<String, dynamic> data) {
    return PointEntry(
      id: id,
      type: data['type'] as String,
      delta: data['delta'] as int,
      note: data['note'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}

/// Gacha result model
class GachaResult {
  final bool ok;
  final Map<String, dynamic>? reward;
  final String? reason;
  final int resetInSeconds;
  final String dayId;

  GachaResult({
    required this.ok,
    this.reward,
    this.reason,
    required this.resetInSeconds,
    required this.dayId,
  });

  factory GachaResult.fromJson(Map<String, dynamic> json) {
    return GachaResult(
      ok: json['ok'] as bool,
      reward: json['reward'] as Map<String, dynamic>?,
      reason: json['reason'] as String?,
      resetInSeconds: json['resetInSeconds'] as int,
      dayId: json['dayId'] as String,
    );
  }
}

class PointsRepository {
  final FirebaseFirestore firestore;
  final FirebaseFunctions functions;

  PointsRepository({
    required this.firestore,
    required this.functions,
  });

  /// Get total points stream
  Stream<int> totalPoints(String userId) {
    return firestore
        .collection('users')
        .doc(userId)
        .collection('points')
        .doc('total')
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return 0;
      return snapshot.data()?['total'] as int? ?? 0;
    });
  }

  /// Get point ledger stream with pagination
  Stream<List<PointEntry>> ledgerPaged(String userId, {int limit = 20}) {
    return firestore
        .collection('users')
        .doc(userId)
        .collection('pointLedger')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return PointEntry.fromFirestore(doc.id, doc.data());
      }).toList();
    });
  }

  /// Get current month's point acquisition
  Future<int> getCurrentMonthPoints(String userId) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    final snapshot = await firestore
        .collection('users')
        .doc(userId)
        .collection('pointLedger')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('delta', isGreaterThan: 0)
        .get();

    if (snapshot.docs.isEmpty) return 0;

    return snapshot.docs.fold<int>(0, (sum, doc) {
      return sum + (doc.data()['delta'] as int? ?? 0);
    });
  }

  /// Claim daily gacha
  Future<GachaResult> claimDailyGacha() async {
    final callable = functions.httpsCallable('claimDailyGacha');
    final result = await callable.call();

    return GachaResult.fromJson(result.data as Map<String, dynamic>);
  }
}
