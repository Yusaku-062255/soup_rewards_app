import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_user.freezed.dart';
part 'app_user.g.dart';

@freezed
class AppUser with _$AppUser {
  const factory AppUser({
    required String uid,
    required bool isAnonymous,
    required List<String> authProviders,
    required bool emailVerified,
    required bool notificationEnabled,
    required String locale,
    required int totalPoints,
    required int totalBookings,
    required int totalGachaPlays,
    required DateTime createdAt,
    required DateTime updatedAt,
    required DateTime lastLoginAt,
    String? displayName,
    String? photoURL,
    String? email,
    String? phoneNumber,
    String? notificationToken,
    DateTime? deletedAt,
  }) = _AppUser;

  factory AppUser.fromJson(Map<String, dynamic> json) =>
      _$AppUserFromJson(json);

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      isAnonymous: data['isAnonymous'] as bool? ?? true,
      authProviders: List<String>.from(data['authProviders'] as List? ?? ['anonymous']),
      emailVerified: data['emailVerified'] as bool? ?? false,
      notificationEnabled: data['notificationEnabled'] as bool? ?? true,
      locale: data['locale'] as String? ?? 'ja-JP',
      totalPoints: data['totalPoints'] as int? ?? 0,
      totalBookings: data['totalBookings'] as int? ?? 0,
      totalGachaPlays: data['totalGachaPlays'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      displayName: data['displayName'] as String?,
      photoURL: data['photoURL'] as String?,
      email: data['email'] as String?,
      phoneNumber: data['phoneNumber'] as String?,
      notificationToken: data['notificationToken'] as String?,
      deletedAt: data['deletedAt'] != null
          ? (data['deletedAt'] as Timestamp).toDate()
          : null,
    );
  }
}
