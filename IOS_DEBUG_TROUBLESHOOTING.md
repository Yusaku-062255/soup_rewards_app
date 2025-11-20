# iOS デバッグタイムアウト問題 - トラブルシューティングガイド

## 🔴 発生したエラー

```
Error starting debug session in Xcode: Timed out waiting for
CONFIGURATION_BUILD_DIR to update.
Could not run build/ios/iphoneos/Runner.app
```

## 🎯 原因

このエラーは以下の原因で発生します：

1. **Xcode の自動化権限が不足**
   - macOS がターミナル/Flutter から Xcode を制御する権限がない

2. **デバイスの信頼設定**
   - iPhone が Mac を信頼していない
   - 開発証明書が期限切れまたは無効

3. **キャッシュの問題**
   - Derived Data や古いビルド成果物が残っている

4. **プロビジョニングプロファイルの問題**
   - 開発チーム設定が正しくない
   - 証明書の期限切れ

---

## ✅ 解決策（順番に試してください）

### 方法1: 自動修正スクリプトを実行

```bash
./ios_debug_fix.sh
```

### 方法2: 手動で段階的に修正

#### ステップ1: macOS の自動化権限を確認

1. **システム環境設定** を開く
2. **プライバシーとセキュリティ** → **オートメーション** へ移動
3. **Xcode** または **Terminal** の項目を探す
4. 以下にチェックが入っているか確認：
   - ✅ Finder
   - ✅ System Events
   - ✅ その他の関連アプリ

#### ステップ2: デバイスの信頼設定を確認

1. iPhone を USB ケーブルで Mac に接続
2. iPhone の画面に「このコンピュータを信頼しますか？」と表示されたら **信頼** をタップ
3. パスコードを入力

4. Mac 側でも確認：
```bash
# デバイスが認識されているか確認
xcrun xctrace list devices
```

#### ステップ3: Xcode の開発チーム設定を確認

1. Xcode を開く:
```bash
open ios/Runner.xcworkspace
```

2. **Runner** プロジェクトを選択
3. **Signing & Capabilities** タブを開く
4. **Team** が `JCK8C4LKG3` に設定されているか確認
5. **Automatically manage signing** がチェックされているか確認

#### ステップ4: 徹底的なクリーンアップ

```bash
# Xcode を完全に終了
killall Xcode

# すべてのキャッシュをクリア
flutter clean
rm -rf ios/build
rm -rf ios/Pods
rm -rf ios/Podfile.lock
rm -rf ios/.symlinks
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# 依存関係を再インストール
flutter pub get
cd ios && pod install && cd ..
```

#### ステップ5: Xcode から直接ビルド

1. Xcode を開く:
```bash
open ios/Runner.xcworkspace
```

2. メニューバーから **Product** → **Clean Build Folder** (Shift+Cmd+K)

3. デバイスを選択（左上のドロップダウン）

4. **Product** → **Run** (Cmd+R) を実行

5. 成功したら、Xcode を閉じて `flutter run` を試す

---

## 🔧 追加の修正内容

### Info.plist に権限を追加

以下の権限が追加されました：

```xml
<key>NSCameraUsageDescription</key>
<string>QRコードのスキャンにカメラを使用します</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>写真を選択するためにフォトライブラリへのアクセスが必要です</string>

<key>NSPhotoLibraryAddUsageDescription</key>
<string>写真を保存するためにフォトライブラリへのアクセスが必要です</string>
```

---

## 🚨 よくある追加エラー

### エラー: "Unable to boot device"
**解決策:**
```bash
killall -9 com.apple.CoreSimulator.CoreSimulatorService
xcrun simctl shutdown all
```

### エラー: "Code signing error"
**解決策:**
1. Xcode > Preferences > Accounts を開く
2. Apple ID を追加/再認証
3. Download Manual Profiles をクリック

### エラー: "The application's Info.plist does not contain CFBundleVersion"
**解決策:**
`pubspec.yaml` のバージョンを確認:
```yaml
version: 1.0.0+1
```

---

## 📱 デバイス実機デバッグのベストプラクティス

### 1. 初回セットアップ
- デバイスを接続
- 「このコンピュータを信頼」を承認
- Xcode でデバイスを選択してビルド
- 成功を確認してから `flutter run` を使用

### 2. 定期的なメンテナンス
```bash
# 週に1回程度実行
rm -rf ~/Library/Developer/Xcode/DerivedData/*
```

### 3. トラブル時のチェックリスト
- [ ] デバイスが接続され、信頼されているか
- [ ] Xcode が最新バージョンか
- [ ] 開発証明書が有効か
- [ ] Derived Data をクリアしたか
- [ ] Pod install を実行したか

---

## 💡 推奨ワークフロー

### 初回セットアップ時:
1. Xcode から直接ビルド → 成功確認
2. その後 `flutter run` を使用

### 日常開発時:
```bash
# ホットリロードが効くので開発が早い
flutter run

# コード変更を保存すると自動的にホットリロード
# 大きな変更があった場合は r を押してホットリスタート
```

### トラブル発生時:
```bash
# まずクイックフィックス
flutter clean && flutter pub get

# それでもダメなら徹底クリーンアップ
./ios_debug_fix.sh
```

---

## 📞 サポート

問題が解決しない場合:

1. エラーログ全体をコピー
2. 以下の情報を収集:
   - Xcode バージョン
   - Flutter バージョン (`flutter --version`)
   - デバイスの iOS バージョン
   - 実行したコマンド履歴

3. Flutter の公式トラブルシューティング:
   https://docs.flutter.dev/deployment/ios

---

## ✅ このガイドで実施済みの対策

- [x] Info.plist にカメラ・フォトライブラリ権限を追加
- [x] Derived Data のクリア
- [x] Pod の再インストール
- [x] 自動修正スクリプトの作成
- [x] トラブルシューティングガイドの作成

次は実機でのテストが必要です。
