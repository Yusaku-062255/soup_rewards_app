# 🚗 SOUP Rewards - 公式モバイルアプリ

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.24.0-02569B?logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-3.4.0-0175C2?logo=dart" alt="Dart">
  <img src="https://img.shields.io/badge/Firebase-Latest-FFCA28?logo=firebase" alt="Firebase">
  <img src="https://img.shields.io/badge/License-Private-red" alt="License">
</p>

**SOUP Rewards** は徳島発カーケアブランド「SOUP」の公式会員アプリです。ポイント管理、クーポン配布、QRスキャン、ニュース配信、PUSH通知などの機能を提供します。

---

## 🚀 iOS実機で最短起動（5分）

> このリポジトリには Firebase の秘密ファイルは含みません。各自で生成しローカルに配置してください。

### 1. Firebase ConsoleでiOSアプリ追加
- Bundle ID: `com.kanamurayusaku.soupRewards`
- ダウンロードした **GoogleService-Info.plist** を `ios/Runner/` に配置

### 2. FlutterFire CLIで `firebase_options.dart` を生成
```bash
dart pub global activate flutterfire_cli
flutterfire configure \
  --project <YOUR_PROJECT_ID> \
  --ios-bundle-id com.kanamurayusaku.soupRewards
```

生成後、`lib/firebase_options_loader.dart` を次に置き換える：
```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
FirebaseOptions? get firebaseOptions => DefaultFirebaseOptions.currentPlatform;
```

### 3. 依存インストール
```bash
flutter pub get
(cd ios && pod install --repo-update && cd ..)
```

### 4. Xcodeで Team/Bundle ID を設定し、実機を接続して `Run`

### 5. Functions/ルールのデプロイ（必須）
```bash
cd functions && npm install && npm run deploy
firebase deploy --only firestore:rules
```

> **重要**: Cloud Functions（claimDailyGacha/createBooking/redeemCoupon）はアプリ動作に必須です。

---
## 📱 主要機能

### 4タブ構成（ホーム／予約／ポイント／クーポン）

- ✅ **ホーム画面** - 進行中クエスト、ポイント残高、今日の予約確認
- ✅ **予約機能** - カレンダー選択、時間帯スロット予約（+50pt）、トランザクション対応
- ✅ **ポイントシステム** - リアルタイム残高、当月獲得、履歴表示、デイリーガチャ（+10pt）
- ✅ **クーポン管理** - 利用可能/使用済/期限切れフィルタ、即時使用機能
- ✅ **ahamo級UI** - 大きめ角丸カード、波形グラデ、ミントアクセント
- ✅ **Firebase安全起動** - 未設定でもクラッシュしない設計
- ✅ **Cloud Functions** - JST対応ガチャ/予約/クーポン（asia-northeast1）
- ✅ **Firestore Security** - 厳格なルール設定、所有者ベースアクセス制御

---

## 🏗️ アーキテクチャ

### 技術スタック

| カテゴリ | 技術 |
|---------|------|
| **フレームワーク** | Flutter 3.24.0 / Dart 3.4.0 |
| **状態管理** | Riverpod 2.5.1 |
| **ルーティング** | go_router 14.2.7（Deep Link対応） |
| **バックエンド** | Firebase (Auth/Firestore/Functions/Analytics/Messaging) |
| **エラー監視** | Sentry Flutter 7.18.0 |
| **ローカルDB** | sqflite 2.3.3 / SharedPreferences 2.3.2 |
| **通知** | Firebase Cloud Messaging 15.1.3 |
| **UI/UX** | Material Design 3 / Lottie / Cached Network Image |
| **CI/CD** | GitHub Actions / fastlane (予定) |

### ディレクトリ構造

```
lib/
├── main.dart                          # エントリーポイント
├── main_with_sentry.dart              # Sentry統合版
├── main_with_router.dart              # go_router統合版
├── core/
│   ├── constants/
│   │   └── app_constants.dart         # アプリ定数
│   ├── providers/
│   │   └── app_providers.dart         # グローバルプロバイダー
│   ├── router/
│   │   └── app_router.dart            # ルーティング設定
│   ├── services/
│   │   └── sentry_service.dart        # Sentryサービス
│   ├── theme/
│   │   ├── app_theme.dart             # テーマ設定
│   │   └── app_colors.dart            # カラーパレット
│   └── utils/
│       ├── error_handler.dart         # エラーハンドリング
│       ├── performance_utils.dart     # パフォーマンス最適化
│       └── security_utils.dart        # セキュリティユーティリティ
├── features/
│   ├── home/                          # ホーム機能
│   ├── points/                        # ポイント機能
│   ├── coupon/                        # クーポン機能
│   ├── qr_scan/                       # QRスキャン機能
│   └── profile/                       # プロフィール機能
└── firebase_options.dart              # Firebase設定（自動生成）
```

---

## 🚀 セットアップ手順

### 1️⃣ 前提条件

- **Flutter SDK**: 3.24.0以上
- **Dart SDK**: 3.4.0以上
- **Xcode**: 15.0以上（iOS開発）
- **Android Studio**: 最新版（Android開発）
- **Firebase CLI**: インストール済み
- **Git**: インストール済み

### 2️⃣ リポジトリクローン

```bash
git clone https://github.com/Yusaku-062255/soup_rewards_app.git
cd soup_rewards_app
```

### 3️⃣ 依存関係インストール

```bash
# Flutter依存関係
flutter pub get

# iOS Pods（macOSのみ）
cd ios && pod install && cd ..
```

### 4️⃣ Firebase設定

**詳細は [FIREBASE_SETUP.md](FIREBASE_SETUP.md) を参照**

```bash
# FlutterFire CLI インストール
dart pub global activate flutterfire_cli

# Firebase設定ファイル生成
flutterfire configure --project=soup-rewards-app
```

### 5️⃣ 環境変数設定（オプション）

開発/本番環境を分ける場合：

```bash
# 開発環境
flutter run --dart-define=FLAVOR=development

# 本番環境
flutter run --dart-define=FLAVOR=production --dart-define=SENTRY_DSN=https://...
```

### 6️⃣ 実行

```bash
# デバッグモード
flutter run

# iOS実機
flutter run -d <device-id>

# Android実機
flutter run -d <device-id>
```

---

## 🧪 テスト

### 静的解析

```bash
flutter analyze
```

### ユニット/ウィジェットテスト

```bash
flutter test --coverage
```

### カバレッジ確認

```bash
# macOS/Linux
open coverage/lcov-report/index.html

# Windows
start coverage/lcov-report/index.html
```

---

## 🏭 ビルド

### Android

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release --split-per-abi

# Release App Bundle (Play Store用)
flutter build appbundle --release
```

### iOS

```bash
# Debug IPA（署名なし）
flutter build ios --debug --no-codesign

# Release IPA
flutter build ipa --release
```

---

## 📦 リリース手順

### Android（Google Play）

1. **署名設定**
   ```bash
   # Keystore生成（初回のみ）
   keytool -genkey -v -keystore ~/soup-rewards-upload.keystore \
     -alias upload -keyalg RSA -keysize 2048 -validity 10000

   # key.properties作成
   cp android/key.properties.example android/key.properties
   # 編集して正しいパスワード・パスを設定
   ```

2. **ビルド**
   ```bash
   flutter build appbundle --release
   ```

3. **アップロード**
   - Play Console → リリース → 内部テスト → 新しいリリースを作成
   - `build/app/outputs/bundle/release/app-release.aab` をアップロード

### iOS（App Store）

1. **Xcode設定**
   ```bash
   open ios/Runner.xcworkspace
   ```
   - Signing & Capabilities → チーム選択
   - Bundle Identifier確認

2. **ビルド**
   ```bash
   flutter build ipa --release
   ```

3. **アップロード**
   - Xcode → Organizer → Upload to App Store Connect
   - または `xcrun altool` で自動化

**詳細は各セットアップガイドを参照:**
- [FIREBASE_SETUP.md](FIREBASE_SETUP.md)
- [SENTRY_SETUP.md](SENTRY_SETUP.md)
- [FIRESTORE_SETUP.md](FIRESTORE_SETUP.md)

---

## 🔧 開発ツール

### VS Code 推奨拡張機能

- **Dart** - Dart language support
- **Flutter** - Flutter framework support
- **Awesome Flutter Snippets** - コードスニペット
- **Error Lens** - エラー表示強化
- **GitLens** - Git履歴可視化

### デバッグコマンド

```bash
# パフォーマンス計測
flutter run --profile

# リリースモードでのテスト
flutter run --release

# ログ出力
flutter logs
```

---

## 📊 CI/CD

### GitHub Actions

- **CI**: Push時に自動 analyze/test/build
- **Release**: タグ push 時に自動リリースビルド

ワークフロー:
- [.github/workflows/ci.yml](.github/workflows/ci.yml)
- [.github/workflows/release.yml](.github/workflows/release.yml)

### 必要なGitHub Secrets

| シークレット名 | 説明 |
|---------------|------|
| `ANDROID_KEYSTORE_BASE64` | Android Keystoreファイル（Base64エンコード） |
| `ANDROID_KEYSTORE_PASSWORD` | Keystoreパスワード |
| `ANDROID_KEY_ALIAS` | キーエイリアス |
| `ANDROID_KEY_PASSWORD` | キーパスワード |
| `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` | Play Console APIキー（JSON） |
| `SENTRY_DSN` | Sentry DSN（エラー監視） |
| `IOS_CERTIFICATE_BASE64` | iOS証明書（Base64エンコード） |
| `IOS_CERTIFICATE_PASSWORD` | 証明書パスワード |
| `IOS_PROVISIONING_PROFILE_BASE64` | プロビジョニングプロファイル（Base64） |

---

## 🔐 セキュリティ

### 重要な注意事項

⚠️ **以下のファイルは絶対にGitコミットしないこと**

- `google-services.json` / `GoogleService-Info.plist`
- `firebase_options.dart`
- `key.properties` / `*.keystore` / `*.jks`
- `.env` / `.env.*`
- `*.mobileprovision` / `*.p12`

これらは `.gitignore` に追加済みです。

### ベストプラクティス

1. **環境変数** - `--dart-define` で注入
2. **Firestore ルール** - 最小権限の原則
3. **API認証** - サーバーサイド検証必須
4. **Secrets管理** - GitHub Secrets / Firebase App Check

---

## 📚 ドキュメント

| ドキュメント | 説明 |
|------------|------|
| [FIREBASE_SETUP.md](FIREBASE_SETUP.md) | Firebase統合手順 |
| [SENTRY_SETUP.md](SENTRY_SETUP.md) | Sentryエラー監視設定 |
| [FIRESTORE_SETUP.md](FIRESTORE_SETUP.md) | Firestoreルール設定 |
| [CODE_IMPROVEMENT_REPORT.md](CODE_IMPROVEMENT_REPORT.md) | コード改善履歴 |
| [VSCODE_SETUP_GUIDE.md](VSCODE_SETUP_GUIDE.md) | VS Code開発環境 |

---

## 🐛 トラブルシューティング

### よくある問題

#### ❌ `firebase_options.dart` がない

```bash
flutterfire configure --project=soup-rewards-app
```

#### ❌ iOS Podエラー

```bash
cd ios
rm -rf Pods Podfile.lock
pod install --repo-update
cd ..
```

#### ❌ Android署名エラー

```bash
# key.propertiesが正しく設定されているか確認
cat android/key.properties

# Keystoreファイルのパスが正しいか確認
ls -la /path/to/keystore
```

#### ❌ ビルドエラー: "Minimum iOS version 14.0"

Podfileの `platform :ios, '14.0'` を確認

---

## 🤝 コントリビューション

現在プライベートリポジトリのため、外部貢献は受け付けていません。

### 開発ブランチ戦略

- `main` - 本番環境
- `develop` - 開発環境
- `feature/*` - 新機能開発
- `bugfix/*` - バグ修正
- `claude/*` - AI支援開発（自動生成）

---

## 📄 ライセンス

Copyright © 2024 SOUP Inc. All rights reserved.

このソフトウェアはプロプライエタリライセンスです。無断複製・配布を禁じます。

---

## 🎁 ポイント/ガチャの利用方法

### デイリーガチャの実行

1. **ログイン**: 匿名ログインまたはApple Sign-Inでログイン
2. **ポイントタブへ移動**: 下部ナビゲーションから「ポイント」タブをタップ
3. **ガチャボタンをタップ**: 「デイリーガチャを回す」ボタンをタップ
4. **結果確認**:
   - 成功: スナックバーで獲得ポイント数が表示される（+10pt など）
   - 既に受取済み: 「本日分は既に受取済みです」とリセット時間が表示される

### ポイント残高と台帳の確認

- **残高表示**: ポイント画面上部に合計ポイントが大きく表示
- **当月獲得**: 今月獲得したポイント合計を表示
- **ポイント履歴**: 最新10件の取引履歴を表示
  - 各履歴には **delta**（増減）と **balance**（その時点の残高）が表示される
  - 台帳の整合性を確認可能

### Cloud Functions実装要件

デイリーガチャを動作させるには、以下のCloud Functionが必要です：

```typescript
// functions/src/index.ts
export const claimDailyGacha = functions
  .region('asia-northeast1')
  .https.onCall(async (data, context) => {
    const uid = context.auth?.uid;
    if (!uid) throw new functions.https.HttpsError('unauthenticated', 'Login required.');

    // JST基準でdayIdを生成
    const dayId = getCurrentDayIdJST();

    // Idempotency: 既に受け取っているかチェック
    const gachaClaimRef = admin.firestore()
      .collection('users').doc(uid)
      .collection('gachaClaims').doc(dayId);

    const gachaSnap = await gachaClaimRef.get();
    if (gachaSnap.exists) {
      return {
        ok: false,
        reason: 'already_claimed',
        resetInSeconds: getSecondsUntilNextDayJST(),
        dayId
      };
    }

    // Transaction: ガチャ実行 + ポイント付与
    await admin.firestore().runTransaction(async (tx) => {
      const userRef = admin.firestore().collection('users').doc(uid);
      const userSnap = await tx.get(userRef);
      const currentPoints = userSnap.data()?.totalPoints || 0;
      const amount = 10; // 固定10ポイント（Epic 2最小実装）

      // ポイント加算
      tx.update(userRef, {
        totalPoints: currentPoints + amount,
        totalGachaPlays: admin.firestore.FieldValue.increment(1),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // 台帳記録
      const ledgerRef = userRef.collection('pointLedger').doc();
      tx.set(ledgerRef, {
        type: 'gacha',
        delta: amount,
        balance: currentPoints + amount,
        note: 'デイリーガチャ',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // ガチャ受取記録
      tx.set(gachaClaimRef, {
        claimedAt: admin.firestore.FieldValue.serverTimestamp(),
        reward: 'points',
      });
    });

    return {
      ok: true,
      reward: { type: 'points', amount: 10 },
      resetInSeconds: getSecondsUntilNextDayJST(),
      dayId
    };
  });

function getCurrentDayIdJST(): string {
  const now = new Date();
  const jstOffset = 9 * 60; // JST = UTC+9
  const jstDate = new Date(now.getTime() + jstOffset * 60 * 1000);
  return jstDate.toISOString().slice(0, 10).replace(/-/g, '');
}

function getSecondsUntilNextDayJST(): number {
  const now = new Date();
  const jstOffset = 9 * 60;
  const jstDate = new Date(now.getTime() + jstOffset * 60 * 1000);
  const tomorrow = new Date(jstDate);
  tomorrow.setUTCDate(tomorrow.getUTCDate() + 1);
  tomorrow.setUTCHours(0, 0, 0, 0);
  return Math.floor((tomorrow.getTime() - jstDate.getTime()) / 1000);
}
```

### Firestoreセキュリティルール

```javascript
// firestore.rules

// pointLedger: Cloud Functionsのみ書込可能
match /users/{userId}/pointLedger/{entryId} {
  allow read: if isOwner(userId) || isAdmin();
  allow write: if false; // Cloud Functionsのみ
}

// gachaClaims: Cloud Functionsのみ書込可能
match /users/{userId}/gachaClaims/{yyyymmdd} {
  allow read: if isOwner(userId) || isAdmin();
  allow write: if false; // Cloud Functionsのみ
}

// users: totalPoints等の統計フィールドはCloud Functionsのみ更新可
match /users/{userId} {
  allow read: if isOwner(userId) || isAdmin();
  allow update: if isOwner(userId)
    && !request.resource.data.diff(resource.data).affectedKeys()
      .hasAny(['uid', 'createdAt', 'totalPoints', 'totalBookings', 'totalGachaPlays']);
}
```

### 実機テスト手順

```bash
# 1. Cloud Functionsデプロイ
cd functions
npm install
npm run deploy

# 2. Firestoreルールデプロイ
firebase deploy --only firestore:rules

# 3. iOS実機ビルド
flutter run -d <device-id>

# 4. テストフロー
#    - 匿名ログイン or Appleログイン
#    - ポイントタブへ移動
#    - デイリーガチャボタンをタップ
#    - 成功メッセージとポイント残高更新を確認
#    - もう一度タップ → 「受取済み」メッセージを確認
#    - ポイント履歴で delta と balance が整合していることを確認
```

### クライアント直書き禁止の確認

```dart
// このコードは権限エラーになる（想定通り）
await FirebaseFirestore.instance
  .collection('users')
  .doc(userId)
  .collection('pointLedger')
  .add({
    'type': 'manual',
    'delta': 100,
    'balance': 200,
    'note': 'テスト',
    'createdAt': FieldValue.serverTimestamp(),
  });
// Error: Missing or insufficient permissions
```

---

## 📞 サポート

### 開発者向け

- **リポジトリ**: https://github.com/Yusaku-062255/soup_rewards_app
- **Issues**: GitHub Issues
- **Slack**: #soup-rewards-dev

### エンドユーザー向け

- **サポートメール**: support@soup.tokushima.jp
- **公式サイト**: https://soup.tokushima.jp/
- **電話**: 088-123-4567

---

## 🎯 ロードマップ

### Phase 1: MVP（完了）
- ✅ 基本UI実装
- ✅ Firebase統合
- ✅ ポイント・クーポン機能

### Phase 2: 品質向上（進行中）
- ✅ CI/CD構築
- ✅ Sentry統合
- ⏳ テストカバレッジ80%達成
- ⏳ パフォーマンス最適化

### Phase 3: リリース準備（予定）
- ⏳ App Store審査対応
- ⏳ Google Play審査対応
- ⏳ ストア説明文・スクリーンショット作成
- ⏳ プライバシーポリシー最終確認

### Phase 4: 本番リリース
- ⏳ TestFlight配信
- ⏳ 内部テスト（100名）
- ⏳ 公開リリース

---

**Built with ❤️ by SOUP Development Team**
