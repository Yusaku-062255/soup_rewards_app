# 再起動時クラッシュ修正サマリー

## 🐛 問題

アプリを閉じて再度開くとクラッシュする

## 🔍 原因

1. **`PointsNotifier`のコンストラクタで即座に`_loadPoints()`が呼ばれていた**
   - `PointsNotifier`がRiverpodプロバイダーとして作成される際に、Firebase Authがまだ完全に初期化されていない
   - `_loadPoints()`内で`UserIdResolver.resolveAsync()`が呼ばれ、Firebase Authにアクセスしようとするが、まだ準備ができていない

2. **`main.dart`の初期化ロジックが削除されていた**
   - 以前追加した初期化ロジック（`_initialize()`, `_checkDailyDraw()`など）が削除されていた
   - これにより、`DailyDrawNotifier`と`PointsNotifier`の初期化が適切に行われていなかった

## ✅ 修正内容

### 1. `PointsNotifier`の遅延初期化

**変更前**:
```dart
PointsNotifier(this._repository) : super(PointsState(currentPoints: 0)) {
  _loadPoints(); // コンストラクタで即座に実行
}
```

**変更後**:
```dart
PointsNotifier(this._repository) : super(PointsState(currentPoints: 0));

// 初期化を確実に実行
Future<void> ensureInitialized() async {
  if (!_initialized) {
    await _loadPoints();
  }
}
```

### 2. `main.dart`に初期化ロジックを追加

- `ConsumerStatefulWidget`に変更
- `_initialize()`メソッドを追加:
  - Firebase Authの準備を待つ（100ms遅延）
  - 匿名認証を初期化
  - `DailyDrawNotifier`の初期化を確実に実行
  - `PointsNotifier`の初期化を確実に実行
  - 初期化完了後、デイリーくじをチェック

### 3. エラーハンドリングの強化

- 各初期化ステップでtry-catchを追加
- エラーが発生してもアプリは続行
- デバッグログを出力

## 📝 変更ファイル

1. **`lib/main.dart`**
   - `StatelessWidget`から`ConsumerStatefulWidget`に変更
   - 初期化ロジックを追加

2. **`lib/features/points/application/points_controller.dart`**
   - `PointsNotifier`のコンストラクタから`_loadPoints()`の即座呼び出しを削除
   - `_initialized`フラグを追加
   - `ensureInitialized()`メソッドを追加
   - `_loadPoints()`のエラーハンドリングを改善

## 🧪 テスト項目

- [ ] アプリを起動 → 正常に起動する
- [ ] アプリを閉じる
- [ ] アプリを再度開く → クラッシュしない（重要）
- [ ] デイリーくじが正常に表示される
- [ ] ポイントが正常に表示される

## 🎯 期待される結果

- アプリを閉じて再度開いてもクラッシュしない
- 初期化が適切に行われる
- エラーが発生してもアプリは続行

