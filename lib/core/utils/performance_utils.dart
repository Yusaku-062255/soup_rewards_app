import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// パフォーマンス最適化のためのユーティリティ

class PerformanceUtils {
  /// デバウンス処理（連続した呼び出しを制限）
  static void debounce(
    String key,
    VoidCallback callback, {
    Duration delay = const Duration(milliseconds: 300),
  }) {
    _debounceTimers[key]?.cancel();
    _debounceTimers[key] = Timer(delay, callback);
  }

  static final Map<String, Timer> _debounceTimers = {};

  /// スロットル処理（一定時間内の呼び出し回数を制限）
  static void throttle(
    String key,
    VoidCallback callback, {
    Duration interval = const Duration(milliseconds: 100),
  }) {
    if (_throttleTimestamps[key] != null) {
      final elapsed = DateTime.now().difference(_throttleTimestamps[key]!);
      if (elapsed < interval) return;
    }

    _throttleTimestamps[key] = DateTime.now();
    callback();
  }

  static final Map<String, DateTime> _throttleTimestamps = {};

  /// メモリ使用量を監視（デバッグモードのみ）
  static void logMemoryUsage(String context) {
    if (kDebugMode) {
      // タイムラインイベントを記録
      developer.Timeline.instantSync(
        'Memory Check',
        arguments: {'context': context},
      );

      // タイムスタンプ付きでログ出力
      final timestamp = DateTime.now().toIso8601String();
      debugPrint('[$timestamp] Memory usage check: $context');

      // デベロッパーイベントとして送信（DevToolsで確認可能）
      developer.postEvent('memory_check', {
        'context': context,
        'timestamp': timestamp,
      });
    }
  }
}

/// 遅延ローディング用のウィジェット
class LazyBuilder extends StatefulWidget {
  final Widget Function(BuildContext context) builder;
  final Duration delay;

  const LazyBuilder({
    super.key,
    required this.builder,
    this.delay = const Duration(milliseconds: 100),
  });

  @override
  State<LazyBuilder> createState() => _LazyBuilderState();
}

class _LazyBuilderState extends State<LazyBuilder> {
  bool _shouldBuild = false;

  @override
  void initState() {
    super.initState();
    Timer(widget.delay, () {
      if (mounted) {
        setState(() {
          _shouldBuild = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldBuild) {
      return const SizedBox.shrink();
    }
    return widget.builder(context);
  }
}

/// 画像の遅延ローディング
class LazyImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const LazyImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ??
            SizedBox(
              width: width,
              height: height,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            );
      },
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ??
            SizedBox(
              width: width,
              height: height,
              child: const Icon(Icons.error),
            );
      },
    );
  }
}

/// リストの仮想化（大量データ対応）
class VirtualizedListView<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final double itemHeight;
  final ScrollController? controller;

  const VirtualizedListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.itemHeight,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      itemCount: items.length,
      itemExtent: itemHeight, // 固定高さでパフォーマンス向上
      itemBuilder: (context, index) {
        return itemBuilder(context, items[index], index);
      },
    );
  }
}

/// キャッシュ管理
class CacheManager {
  static final Map<String, dynamic> _cache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};

  static void put<T>(String key, T value, {Duration? ttl}) {
    _cache[key] = value;
    if (ttl != null) {
      _cacheTimestamps[key] = DateTime.now().add(ttl);
    }
  }

  static T? get<T>(String key) {
    // TTLチェック
    if (_cacheTimestamps.containsKey(key)) {
      if (DateTime.now().isAfter(_cacheTimestamps[key]!)) {
        remove(key);
        return null;
      }
    }

    return _cache[key] as T?;
  }

  static void remove(String key) {
    _cache.remove(key);
    _cacheTimestamps.remove(key);
  }

  static void clear() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  static int get size => _cache.length;
}

/// Timer拡張
extension TimerExtension on Timer {
  static Timer periodic(Duration duration, void Function(Timer) callback) {
    return Timer.periodic(duration, callback);
  }
}

/// BuildContext拡張
extension BuildContextExtension on BuildContext {
  /// 安全なナビゲーション
  void safePop() {
    if (Navigator.canPop(this)) {
      Navigator.pop(this);
    }
  }

  /// 安全なプッシュ
  Future<T?> safePush<T extends Object?>(Route<T> route) {
    if (mounted) {
      return Navigator.push(this, route);
    }
    return Future.value(null);
  }
}
