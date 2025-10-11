# 依存関係更新方針

## 🎯 基本方針

**pubspec.yaml の範囲指定の範囲内で pubspec.lock を再生成する方針で統一**

## 📋 運用ルール

### **1. pubspec.yaml 編集**
- **人が編集**: 新しいパッケージ追加・バージョン範囲変更
- **範囲指定**: `^` 記号を使用して互換性を確保
- **例**: `flutter_riverpod: ^2.5.1`

### **2. pubspec.lock 管理**
- **機械管理**: 自動生成・更新のみ
- **編集禁止**: 手動での変更は行わない
- **競合時**: 削除して `flutter pub get` で再生成

### **3. 依存関係更新手順**

#### **通常の更新**
```bash
# 1. pubspec.yaml で範囲指定を確認
# 2. pubspec.lock を再生成
flutter pub get

# 3. 品質確認
flutter analyze
flutter test

# 4. 問題なければコミット
git add pubspec.lock
git commit -m "Update dependencies within specified ranges"
```

#### **メジャーバージョン更新**
```bash
# 1. pubspec.yaml の範囲指定を更新
# 例: ^2.5.1 → ^3.0.0

# 2. pubspec.lock を削除・再生成
rm pubspec.lock
flutter clean
flutter pub get

# 3. 破壊的変更への対応
flutter analyze  # エラーがあれば修正
flutter test     # テストが失敗すれば修正

# 4. 動作確認後コミット
git add pubspec.yaml pubspec.lock
git commit -m "Update to new major version: package_name ^3.0.0"
```

#### **競合解決**
```bash
# pubspec.lock で競合が発生した場合
rm pubspec.lock
flutter pub get
git add pubspec.lock
git commit -m "Resolve pubspec.lock conflicts"
```

### **4. 便利スクリプト活用**

```bash
# 全体的な問題修復
./tools/fix_ios.sh

# 実行内容:
# - pubspec.lock 削除・再生成
# - flutter clean & pub get
# - CocoaPods 更新・インストール
# - 品質チェック実行
```

## 🔍 品質保証

### **必須チェック項目**
- ✅ `flutter analyze` エラー0件
- ✅ `flutter test` 全テスト通過
- ✅ iOS/Android ビルド成功

### **CI自動化**
- **GitHub Actions**: PR時に自動実行
- **品質ゲート**: analyze/test 失敗時はマージ禁止

## 📈 メリット

### **安定性**
- **互換性**: 範囲指定による柔軟な更新
- **予測可能**: 破壊的変更の事前把握
- **ロールバック**: 問題時の迅速な復旧

### **効率性**
- **自動化**: 機械的な作業の削減
- **一貫性**: チーム全体での統一運用
- **トラブル回避**: 競合・エラーの最小化

## 🚨 注意事項

### **やってはいけないこと**
- ❌ pubspec.lock の手動編集
- ❌ 範囲指定なしの固定バージョン
- ❌ 品質チェックなしでの更新

### **推奨事項**
- ✅ 小さな単位での更新
- ✅ 更新前後での動作確認
- ✅ 破壊的変更の事前調査

## 🔄 定期メンテナンス

### **月次作業**
```bash
# 利用可能な更新を確認
flutter pub outdated

# 必要に応じて pubspec.yaml の範囲を調整
# 例: ^2.5.1 → ^2.6.0

# 更新実行
flutter pub get
flutter analyze
flutter test
```

### **四半期作業**
- **メジャーバージョン**: 破壊的変更の評価・適用
- **非推奨API**: 新しいAPIへの移行
- **セキュリティ**: 脆弱性対応の確認

この方針により、安定性と最新性のバランスを保った依存関係管理を実現します。
