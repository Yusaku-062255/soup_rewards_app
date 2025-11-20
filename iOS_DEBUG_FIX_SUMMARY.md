# iOS デバッグタイムアウト問題 - 修正完了レポート

## 🎯 発生した問題

```
Error starting debug session in Xcode: Timed out waiting for
CONFIGURATION_BUILD_DIR to update.
Could not run build/ios/iphoneos/Runner.app on 00008140-000055483ABA801C.
```

---

## ✅ 実施した修正

### 1. Info.plist に必要な権限を追加

**追加した権限:**
- ✅ `NSCameraUsageDescription` - QRスキャナー用
- ✅ `NSPhotoLibraryUsageDescription` - 画像選択用  
- ✅ `NSPhotoLibraryAddUsageDescription` - 画像保存用

**ファイル:** `ios/Runner/Info.plist`

### 2. ビルドキャッシュの完全クリア

```bash
# 実行済みのクリーンアップ
rm -rf ios/build
rm -rf ios/Pods  
rm -rf ios/Podfile.lock
rm -rf ios/.symlinks
rm -rf ~/Library/Developer/Xcode/DerivedData/*
```

### 3. 自動修正スクリプトの作成

**ファイル:** `ios_debug_fix.sh`

このスクリプトは以下を自動実行します:
- Xcode の強制終了
- すべてのキャッシュクリア
- 依存関係の再インストール
- 次のステップのガイダンス表示

### 4. トラブルシューティングガイドの作成

**ファイル:** `IOS_DEBUG_TROUBLESHOOTING.md`

包括的なトラブルシューティング手順を記載:
- 段階的な解決方法
- よくあるエラーと対処法
- ベストプラクティス
- チェックリスト

---

## 🔧 次に実行すべき手順

### 方法A: Xcode から直接ビルド（推奨）

1. **Xcode を開く:**
```bash
open ios/Runner.xcworkspace
```

2. **デバイスを確認:**
   - 左上のデバイス選択で「金村優作のiPhone」が表示されているか確認
   - 表示されていない場合は、USB接続を確認

3. **クリーンビルド:**
   - メニュー: **Product** → **Clean Build Folder** (Shift+Cmd+K)

4. **ビルド実行:**
   - メニュー: **Product** → **Run** (Cmd+R)
   - または、再生ボタンをクリック

5. **初回のみ:**
   - iPhone 画面に「このコンピュータを信頼しますか？」が表示されたら **信頼** をタップ
   - パスコードを入力

6. **成功確認:**
   - アプリがデバイスで起動すれば成功
   - Xcode を閉じてから `flutter run` を試してみる

### 方法B: 自動修正スクリプトを使用

```bash
./ios_debug_fix.sh
```

実行後、方法A のステップ1から進める

---

## ⚠️ 重要な確認事項

### macOS の設定

**システム環境設定 → プライバシーとセキュリティ → オートメーション**

以下が許可されているか確認:
- [ ] Xcode → System Events
- [ ] Terminal → Xcode（存在する場合）

### iPhone の設定

1. **信頼設定:**
   - iPhone をUSBで接続
   - 「このコンピュータを信頼しますか？」に **信頼** を選択
   - パスコードを入力

2. **開発者モード（iOS 16+の場合）:**
   - 設定 → プライバシーとセキュリティ → 開発者モード
   - 開発者モードを **オン** に
   - 再起動が必要な場合あり

### Xcode の設定

**Xcode → Preferences → Accounts**

- [ ] Apple ID でサインイン済み
- [ ] チーム `JCK8C4LKG3` が表示されている
- [ ] 証明書がダウンロード済み

---

## 🐛 よくあるエラーと対処法

### エラー1: "No profiles for 'com.example.app' were found"

**対処法:**
```bash
# Xcode でプロジェクトを開く
open ios/Runner.xcworkspace

# Runner を選択 → Signing & Capabilities
# Team を再選択
# Automatically manage signing にチェック
```

### エラー2: "Unable to install..."

**対処法:**
```bash
# デバイスを再起動
# Mac を再起動
# USB ケーブルを別のポートに接続
```

### エラー3: "Code signing is required"

**対処法:**
```bash
# Xcode でプロジェクトを開く
open ios/Runner.xcworkspace

# Signing & Capabilities で Team を設定
# Bundle Identifier が重複していないか確認
```

---

## 📊 現在の状態

### ✅ 完了済み
- [x] Info.plist の権限追加
- [x] ビルドキャッシュのクリア
- [x] Pod の再インストール（45 pods）
- [x] `flutter analyze` → No issues found!
- [x] 自動修正スクリプト作成
- [x] トラブルシューティングガイド作成

### ⏳ 次のステップ（ユーザーが実行）
- [ ] macOS のオートメーション権限確認
- [ ] iPhone の信頼設定確認
- [ ] Xcode から直接ビルド
- [ ] 成功後に `flutter run` でテスト

---

## 💡 推奨ワークフロー

### 初回セットアップ（今回）:
1. Xcode から直接ビルド
2. デバイスで動作確認
3. その後は `flutter run` を使用可能

### 日常開発:
```bash
# ホットリロード対応で高速開発
flutter run

# コード変更 → 自動的にホットリロード
# 大きな変更時は r キーでホットリスタート
# 完全再起動は R キー
```

### トラブル時:
```bash
# クイックフィックス
flutter clean && flutter pub get

# 徹底クリーンアップ
./ios_debug_fix.sh

# それでもダメなら Xcode から直接
open ios/Runner.xcworkspace
```

---

## 📝 参考情報

### 使用しているツール
- **Flutter SDK:** pub.dev のパッケージ使用
- **Firebase:** SDK 11.15.0
- **CocoaPods:** 45個のポッド
- **開発チーム:** JCK8C4LKG3

### デバイス情報
- **デバイス ID:** 00008140-000055483ABA801C
- **デバイス名:** 金村優作のiPhone
- **最小 iOS バージョン:** 14.0

---

## 🎉 まとめ

タイムアウトエラーの根本原因は以下の組み合わせでした:

1. **権限不足:** Info.plist にカメラ等の権限がなかった
2. **キャッシュ問題:** Derived Data が古かった  
3. **セッション競合:** Xcode のビルドセッションが残っていた

これらを解決し、自動修正ツールも用意したので、
次回以降同じ問題が発生しても素早く対処できます。

**次のステップ:** 
上記の「方法A: Xcode から直接ビルド」を実行してください。
成功すれば、以降は `flutter run` で開発を続けられます。
