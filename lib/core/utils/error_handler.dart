import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// アプリケーション全体のエラーハンドリング

class AppErrorHandler {
  static void handleError(Object error, StackTrace stackTrace) {
    // デバッグモードでは詳細なエラー情報を出力
    if (kDebugMode) {
      debugPrint('Error: $error');
      debugPrint('StackTrace: $stackTrace');
    }

    // TODO: 本番環境ではCrashlyticsなどにエラーを送信
    // FirebaseCrashlytics.instance.recordError(error, stackTrace);
  }

  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: '閉じる',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

/// 非同期処理の状態管理
class AsyncValue<T> {
  final T? data;
  final Object? error;
  final bool isLoading;

  const AsyncValue._({
    this.data,
    this.error,
    this.isLoading = false,
  });

  const AsyncValue.loading() : this._(isLoading: true);
  const AsyncValue.data(T data) : this._(data: data);
  const AsyncValue.error(Object error) : this._(error: error);

  bool get hasData => data != null;
  bool get hasError => error != null;

  R when<R>({
    required R Function(T data) data,
    required R Function(Object error) error,
    required R Function() loading,
  }) {
    if (isLoading) return loading();
    if (hasError) return error(this.error!);
    if (hasData) return data(this.data as T);
    return loading();
  }

  R maybeWhen<R>({
    R Function(T data)? data,
    R Function(Object error)? error,
    R Function()? loading,
    required R Function() orElse,
  }) {
    if (isLoading && loading != null) return loading();
    if (hasError && error != null) return error(this.error!);
    if (hasData && data != null) return data(this.data as T);
    return orElse();
  }
}

/// ローディング状態を管理するウィジェット
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.3),
            child: Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      if (message != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          message!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// エラー表示ウィジェット
class ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'エラーが発生しました',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('再試行'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
