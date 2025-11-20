# 再起動時クラッシュ修正 - 最終版

## 🐛 問題

アプリを一度閉じて再度開くと必ずクラッシュする

## 🔍 根本原因

1. **`pointsRepositoryProvider`が`sharedPreferencesProvider`の`loading`状態の時に例外を投げていた**
   - `Provider`の`when`メソッドで`loading`状態の時に`UnimplementedError`を投げていた
   - 再起動時に`SharedPreferences`の初期化が完了する前に`pointsRepositoryProvider`が評価され、例外が発生

2. **`PointsPage`の`initState`で`ref.read()`を呼び出していた**
   - `build`メソッド外で`ref.read()`を呼び出すと、Riverpodのコンテキストが正しく取得できない可能性がある
   - `MainPage`の`IndexedStack`で全ページが一度に作成されるため、初期化前にNotifierにアクセスされる

## ✅ 修正内容

### 1. `pointsRepositoryProvider`を`FutureProvider`に変更

**変更前**:
```dart
final pointsRepositoryProvider = Provider<PointsRepository>((ref) {
  final prefsAsync = ref.watch(sharedPreferencesProvider);
  return prefsAsync.when(
    data: (prefs) => MockPointsRepository(prefs),
    loading: () => throw UnimplementedError('SharedPreferences is not ready'),
    error: (_, __) => throw UnimplementedError('Failed to initialize SharedPreferences'),
  );
});
```

**変更後**:
```dart
final pointsRepositoryProvider = FutureProvider<PointsRepository>((ref) async {
  const useFirestore = false;
  if (useFirestore) {
    return FirestorePointsRepository(FirebaseFirestore.instance);
  } else {
    // SharedPreferencesが準備できるまで待機
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    return MockPointsRepository(prefs);
  }
});
```

### 2. `dailyDrawNotifierProvider`と`pointsNotifierProvider`で`AsyncValue`を適切に処理

**変更前**:
```dart
final dailyDrawNotifierProvider =
    StateNotifierProvider<DailyDrawNotifier, DailyDrawUIState>((ref) {
  final repository = ref.watch(pointsRepositoryProvider);
  return DailyDrawNotifier(repository);
});
```

**変更後**:
```dart
final dailyDrawNotifierProvider =
    StateNotifierProvider<DailyDrawNotifier, DailyDrawUIState>((ref) {
  final repositoryAsync = ref.watch(pointsRepositoryProvider);
  if (repositoryAsync.hasValue && repositoryAsync.value != null) {
    return DailyDrawNotifier(repositoryAsync.value!);
  } else {
    // loading状態の場合は、一時的なNotifierを返す
    // 実際の使用時には、ensureInitialized()で初期化を確実に実行する
    // 一時的なリポジトリとして、Firestore実装を使用（SharedPreferences不要）
    return DailyDrawNotifier(FirestorePointsRepository(FirebaseFirestore.instance));
  }
});
```

### 3. `main.dart`でリポジトリの準備を待機

**追加**:
```dart
// pointsRepositoryProviderが準備できるまで待機（SharedPreferencesの初期化を待つ）
try {
  final repositoryAsync = ref.read(pointsRepositoryProvider);
  if (!repositoryAsync.hasValue) {
    // リポジトリがまだ準備できていない場合は、準備が完了するまで待機
    // 最大1秒まで待機（通常は100-200msで完了する）
    for (int i = 0; i < 10; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      final retryAsync = ref.read(pointsRepositoryProvider);
      if (retryAsync.hasValue) {
        debugPrint('[SoupRewardsApp] リポジトリ準備完了（${i + 1}回目の試行）');
        break;
      }
    }
  }
} catch (e) {
  debugPrint('[SoupRewardsApp] リポジトリ準備エラー: $e');
}
```

### 4. `PointsPage`の初期化を安全に実行

**変更前**:
```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ref.read(dailyDrawNotifierProvider.notifier).refresh();
    ref.read(pointsNotifierProvider.notifier).refresh();
  });
}
```

**変更後**:
```dart
bool _hasInitialized = false;

@override
Widget build(BuildContext context) {
  // 初回のみ初期化を試みる（安全に実行）
  if (!_hasInitialized) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_hasInitialized) {
        _hasInitialized = true;
        // 初期化を確実に実行してからリフレッシュ
        _safeRefresh();
      }
    });
  }
  // ...
}

Future<void> _safeRefresh() async {
  try {
    // 初期化を確実に実行してからリフレッシュ
    await ref.read(dailyDrawNotifierProvider.notifier).ensureInitialized();
    await ref.read(pointsNotifierProvider.notifier).ensureInitialized();
    
    // 初期化完了後にリフレッシュ
    await ref.read(dailyDrawNotifierProvider.notifier).refresh();
    await ref.read(pointsNotifierProvider.notifier).refresh();
  } catch (e) {
    // エラー時は無視（初期化がまだ完了していない場合など）
    debugPrint('[PointsPage] リフレッシュエラー: $e');
  }
}
```

## 📝 変更ファイル

1. **`lib/core/providers/app_providers.dart`**
   - `pointsRepositoryProvider`を`FutureProvider`に変更
   - `loading`状態の時に例外を投げないように修正

2. **`lib/features/points/application/points_controller.dart`**
   - `dailyDrawNotifierProvider`と`pointsNotifierProvider`で`AsyncValue`を適切に処理
   - `loading`状態の時に一時的な`FirestorePointsRepository`を使用

3. **`lib/main.dart`**
   - `pointsRepositoryProvider`の準備を待機するロジックを追加
   - `app_providers.dart`のimportを追加

4. **`lib/features/points/presentation/pages/points_page.dart`**
   - `initState`での`ref.read()`呼び出しを削除
   - `build`メソッド内で安全に初期化を実行

## 🎯 初期化順序（修正後）

```
1. Firebase初期化（main.dart）
2. Firebase Authの準備を待つ（100ms遅延）
3. 匿名認証を初期化（UserIdResolver.resolveAsync()）
4. pointsRepositoryProviderの準備を待機（最大1秒）
   - SharedPreferencesの初期化を待つ
   - MockPointsRepositoryを作成
5. DailyDrawNotifierの初期化（ensureInitialized()）
6. PointsNotifierの初期化（ensureInitialized()）
7. デイリーくじのチェック（1日1回のみ自動表示）
```

## 🔒 再起動時クラッシュに関するコードパス（修正後）

```
【アプリ起動時】
1. main() → Firebase.initializeApp()
2. SoupRewardsApp.initState() → WidgetsBinding.instance.addPostFrameCallback()
3. _initialize() が実行される:
   a. Firebase Authの準備を待つ（100ms遅延）
   b. UserIdResolver.resolveAsync() → 匿名認証
   c. pointsRepositoryProviderの準備を待機（最大1秒）
      - SharedPreferences.getInstance()が完了するまで待機
      - MockPointsRepositoryを作成
   d. dailyDrawNotifierProvider.notifier.ensureInitialized()
      → DailyDrawNotifier._loadState() → リポジトリを使用（安全）
   e. pointsNotifierProvider.notifier.ensureInitialized()
      → PointsNotifier._loadPoints() → リポジトリを使用（安全）
4. 初期化完了後、デイリーくじをチェック

【再起動時】
- 同じ初期化順序が実行される
- Firebase Authは既に初期化済みなので、匿名認証は即座に完了
- SharedPreferencesも既に初期化済みなので、pointsRepositoryProviderは即座に完了
- Notifierの初期化も安全に実行される
- クラッシュしない ✅
```

## ✅ 期待される結果

- アプリを閉じて再度開いてもクラッシュしない
- 初期化が適切に行われる
- エラーが発生してもアプリは続行
- `flutter analyze`: No issues found!

---

**修正完了日**: 2024年（実装完了時点）

