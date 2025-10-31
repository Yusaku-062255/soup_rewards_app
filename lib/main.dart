import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options_loader.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initFirebaseSafely();

  runApp(
    const ProviderScope(
      child: SoupRewardsApp(),
    ),
  );
}

/// Firebase安全初期化
///
/// firebase_options_loader.dartがnullを返す場合（未設定時）でも
/// アプリが起動できるようにtry-catchで保護します。
Future<void> _initFirebaseSafely() async {
  try {
    if (firebaseOptions != null) {
      await Firebase.initializeApp(options: firebaseOptions);
      dev.log('Firebase initialized successfully', name: 'bootstrap');
    } else {
      dev.log('Firebase options not configured, skipping initialization', name: 'bootstrap');
      if (kDebugMode) {
        debugPrint('[INFO] Firebase未設定: firebase_options_loader.dartを更新してください');
      }
    }
  } catch (e, st) {
    dev.log('Firebase initialization failed', name: 'bootstrap', error: e, stackTrace: st);
    if (kDebugMode) {
      debugPrint('[WARN] Firebase init skipped: $e\n$st');
    }
  }
}
