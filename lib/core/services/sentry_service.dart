import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Sentry エラー監視サービス
class SentryService {
  SentryService._();

  /// Sentry DSN（環境変数から取得）
  static const String _dsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue: '', // 本番環境では必須
  );

  /// 環境名（dev/stg/prod）
  static const String _environment = String.fromEnvironment(
    'FLAVOR',
    defaultValue: 'development',
  );

  /// Sentry初期化
  static Future<void> initialize() async {
    if (_dsn.isEmpty) {
      debugPrint('⚠️ Sentry DSN not configured. Error tracking disabled.');
      return;
    }

    await SentryFlutter.init(
      (options) {
        options.dsn = _dsn;
        options.environment = _environment;

        // トレース設定
        options.tracesSampleRate = _environment == 'production' ? 0.1 : 1.0;

        // デバッグログ
        options.debug = kDebugMode;

        // リリースバージョン
        options.release = 'soup_rewards_app@1.0.0'; // pubspec.yamlと同期

        // ユーザーフィードバック
        options.enableUserInteractionTracing = true;

        // スクリーンショット添付（エラー時）
        options.attachScreenshot = true;

        // パフォーマンス監視
        options.enableAutoPerformanceTracing = true;

        // センシティブデータフィルタリング
        options.beforeSend = (event, hint) {
          // パスワード・トークンなどを除外
          if (event.request?.data != null) {
            final data = event.request!.data as Map<String, dynamic>?;
            data?.remove('password');
            data?.remove('token');
            data?.remove('api_key');
          }
          return event;
        };

        // ブレッドクラム設定
        options.maxBreadcrumbs = 100;
      },
    );

    debugPrint('✅ Sentry initialized (env: $_environment)');
  }

  /// エラーを手動送信
  static Future<void> captureException(
    dynamic exception, {
    dynamic stackTrace,
    String? hint,
  }) async {
    await Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      hint: hint != null ? Hint.withMap({'message': hint}) : null,
    );
  }

  /// メッセージを送信
  static Future<void> captureMessage(
    String message, {
    SentryLevel level = SentryLevel.info,
  }) async {
    await Sentry.captureMessage(message, level: level);
  }

  /// ユーザー情報を設定
  static void setUser({
    required String userId,
    String? email,
    String? username,
  }) {
    Sentry.configureScope((scope) {
      scope.setUser(SentryUser(
        id: userId,
        email: email,
        username: username,
      ));
    });
  }

  /// ユーザー情報をクリア
  static void clearUser() {
    Sentry.configureScope((scope) {
      scope.setUser(null);
    });
  }

  /// カスタムコンテキスト追加
  static void setContext(String key, Map<String, dynamic> data) {
    Sentry.configureScope((scope) {
      scope.setContexts(key, data);
    });
  }

  /// ブレッドクラム追加（ユーザー行動トラッキング）
  static void addBreadcrumb({
    required String message,
    String? category,
    SentryLevel level = SentryLevel.info,
    Map<String, dynamic>? data,
  }) {
    Sentry.addBreadcrumb(Breadcrumb(
      message: message,
      category: category,
      level: level,
      data: data,
      timestamp: DateTime.now(),
    ));
  }

  /// トランザクション開始（パフォーマンス計測）
  static ISentrySpan startTransaction(
    String name,
    String operation,
  ) {
    return Sentry.startTransaction(name, operation);
  }
}
