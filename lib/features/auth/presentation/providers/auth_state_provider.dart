import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/models/app_user.dart';

/// 認証状態プロバイダー
final authStateProvider = StreamProvider<User?>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.authStateChanges;
});

/// 現在のユーザーIDプロバイダー
final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value?.uid;
});

/// AppUserプロバイダー
final appUserProvider = StreamProvider.autoDispose<AppUser?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return Stream.value(null);
  }
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.userStream(userId);
});
