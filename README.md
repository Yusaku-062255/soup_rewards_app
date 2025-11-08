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

### スクリーンショット撮影手順

PR作成時には以下の4枚のスクリーンショットを添付してください：

#### 1. ガチャ成功画面
```
手順:
1. ポイントタブへ移動
2. 「デイリーガチャを回す」ボタンをタップ
3. 成功メッセージが表示されたらスクリーンショット撮影

確認項目:
- ✅ スナックバーに「ガチャ成功！ +10ポイント獲得」と表示
- ✅ 画面上部の合計ポイントが更新されている
- ✅ ポイント履歴に新しいエントリーが追加されている
```

#### 2. 受取済み画面
```
手順:
1. ガチャ成功後、再度「デイリーガチャを回す」ボタンをタップ
2. 受取済みメッセージが表示されたらスクリーンショット撮影

確認項目:
- ✅ スナックバーに「本日分は既に受取済みです」と表示
- ✅ リセットまでの時間が表示されている（例: リセットまで約15時間）
- ✅ 合計ポイントは変わらない
```

#### 3. ポイント履歴画面
```
手順:
1. ポイント画面を下にスクロール
2. 「ポイント履歴」セクションが見える状態でスクリーンショット撮影

確認項目:
- ✅ 最新10件の履歴が表示されている
- ✅ 各エントリーに delta（+10など）と balance（残高: XXX pt）が表示
- ✅ 日時が表示されている（YYYY/MM/DD HH:MM形式）
- ✅ アイコンが type に応じて表示されている（ガチャは🎁アイコン）
```

#### 4. Firestore Console確認画面
```
手順:
1. Firebase Console → Firestore Database を開く
2. users/{uid}/pointLedger を展開
3. 最新のガチャエントリーを表示した状態でスクリーンショット撮影

確認項目:
- ✅ type: "gacha"
- ✅ delta: 10
- ✅ balance: (正しい残高)
- ✅ note: "デイリーガチャ"
- ✅ createdAt: Timestamp
- ✅ users/{uid}/gachaClaims/{dayId} が作成されている
```

### クライアント直書き禁止の確認

以下のコードはすべて権限エラーになります（想定通りの動作）：

#### テスト1: pointLedgerへの直接書込み
```dart
// ❌ このコードは権限エラーになる
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
// Expected Error: Missing or insufficient permissions
```

#### テスト2: gachaClaimsへの直接書込み
```dart
// ❌ このコードは権限エラーになる
await FirebaseFirestore.instance
  .collection('users')
  .doc(userId)
  .collection('gachaClaims')
  .doc('20250105')
  .set({
    'claimedAt': FieldValue.serverTimestamp(),
    'reward': 'points',
  });
// Expected Error: Missing or insufficient permissions
```

#### テスト3: users.totalPointsの直接更新
```dart
// ❌ このコードは権限エラーになる
await FirebaseFirestore.instance
  .collection('users')
  .doc(userId)
  .update({
    'totalPoints': 9999,  // 保護フィールド
  });
// Expected Error: Missing or insufficient permissions
```

#### テスト4: users.totalGachaPlaysの直接更新
```dart
// ❌ このコードは権限エラーになる
await FirebaseFirestore.instance
  .collection('users')
  .doc(userId)
  .update({
    'totalGachaPlays': 100,  // 保護フィールド
  });
// Expected Error: Missing or insufficient permissions
```

#### テスト5: users.totalBookingsの直接更新
```dart
// ❌ このコードは権限エラーになる
await FirebaseFirestore.instance
  .collection('users')
  .doc(userId)
  .update({
    'totalBookings': 50,  // 保護フィールド
  });
// Expected Error: Missing or insufficient permissions
```

#### ✅ 許可される更新例
```dart
// ✅ このコードは成功する（保護フィールド以外の更新）
await FirebaseFirestore.instance
  .collection('users')
  .doc(userId)
  .update({
    'displayName': '新しい名前',
    'notificationEnabled': false,
  });
// Success: 保護されていないフィールドの更新は許可される
```

#### Firestore Rules Playground での検証

Firebase Console → Firestore → Rules → Rules Playground で以下をテスト:

**シミュレーション1: totalPoints 更新試行**
```
Location: /users/{userId}
Type: update
Auth: Authenticated (Custom UID: test-user-123)

Data:
{
  "totalPoints": 9999,
  "displayName": "Test User"
}

Expected Result: ❌ Permission denied
Reason: totalPoints は保護フィールドのため更新不可
```

**シミュレーション2: displayName のみ更新**
```
Location: /users/{userId}
Type: update
Auth: Authenticated (Custom UID: test-user-123)

Data:
{
  "displayName": "New Name"
}

Expected Result: ✅ Allowed
Reason: 保護フィールド以外の更新は許可
```

---

## 🎟️ 給油券（クーポン最小）の使い方

### 概要

Epic 3 最小実装として、ENEOS給油券（500円分）をポイント交換で取得し、店頭でスタッフPIN入力により消込みできる機能を実装しました。

### 機能

- **ポイント交換**: 500pt で 500円分の給油券を発行
- **有効期限**: 発行から30日間
- **1回限り使用**: 同一クーポンは1度しか使用できません
- **店頭消込み**: スタッフが6桁PINを入力して使用確定

### テンプレート初期化

初回のみ、テンプレートを作成する必要があります：

```dart
// アプリ起動時に自動実行される、または手動で実行
final functions = FirebaseFunctions.instanceFor(region: 'asia-northeast1');
await functions.httpsCallable('ensureFuelVoucherTemplate').call();
```

または、Firestore Console で直接作成：

```
コレクション: couponTemplates
ドキュメントID: fuel_voucher_500yen

データ:
{
  title: "Fuel Voucher (ENEOS)",
  type: "flat_yen",
  discountValueYen: 500,
  pointsCost: 500,
  validityDays: 30,
  active: true,
  createdAt: [Timestamp],
  updatedAt: [Timestamp]
}
```

### スタッフPIN設定

店頭での消込みに使用する6桁PINを設定します：

```bash
# Node.js 環境で実行（salt生成とハッシュ計算）
node -e "
const crypto = require('crypto');
const pin = '123456'; // 実際のPINに変更
const salt = crypto.randomBytes(16).toString('hex');
const hash = crypto.createHash('sha256').update(pin + salt).digest('hex');
console.log('Salt:', salt);
console.log('Hash:', hash);
"
```

Firestore Console で設定を保存：

```
コレクション: serviceCenters/default/settings
ドキュメントID: redeem

データ:
{
  redeemPinHash: "[上記で生成したHash]",
  salt: "[上記で生成したSalt]"
}
```

### 使い方（ユーザー側）

#### 1. 給油券を発行

1. アプリを開き、ログイン
2. 「クーポン」タブをタップ
3. 現在のポイント残高が 500pt 以上あることを確認
4. 「給油券に交換」ボタンをタップ
5. 成功すると、8桁のクーポンコードが表示される

#### 2. 店頭で使用

1. 「マイクーポン」リストから使いたいクーポンを選択
2. 「店頭で使う」ボタンをタップ
3. スタッフに8桁のコードを提示
4. スタッフが6桁PINを入力
5. 使用完了！ ステータスが「使用済み」になる

### Firestore データ構造

#### クーポンテンプレート

```
couponTemplates/{templateId}
{
  title: string,           // "Fuel Voucher (ENEOS)"
  type: string,            // "flat_yen"
  discountValueYen: number, // 500
  pointsCost: number,       // 500
  validityDays: number,     // 30
  active: boolean,          // true
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

#### ユーザークーポン

```
users/{uid}/coupons/{couponId}
{
  templateId: string,       // "fuel_voucher_500yen"
  code: string,             // "ABCD1234" (8桁)
  status: string,           // "active" | "redeemed" | "expired"
  issuedAt: Timestamp,
  expiresAt: Timestamp,
  redeemedAt?: Timestamp,
  redeemedBy?: {
    centerId: string,
    staffId: string
  },
  meta: {
    discountValueYen: number,
    type: string,
    title: string
  }
}
```

### Cloud Functions

#### ensureFuelVoucherTemplate

テンプレートが存在しない場合のみ作成（idempotent）。

#### redeemPointsForFuelVoucher

ポイント消費して給油券を発行。

**入力**:
```json
{
  "templateId": "fuel_voucher_500yen"
}
```

**トランザクション処理**:
1. ポイント残高チェック（不足時は `insufficient_points` エラー）
2. `users.totalPoints` から減算
3. `pointLedger` に記録
4. `coupons` に新規クーポン追加（code生成、有効期限設定）

**出力**:
```json
{
  "ok": true,
  "couponId": "xxx",
  "code": "ABCD1234",
  "expiresAt": "2025-02-15T00:00:00Z",
  "discountValueYen": 500
}
```

#### redeemFuelVoucherAtStore

店頭でスタッフPINを使ってクーポンを消込み。

**入力**:
```json
{
  "couponId": "xxx",
  "centerId": "default",
  "staffPin": "123456"
}
```

**処理**:
1. スタッフPIN検証（ハッシュ比較、不正時は `invalid_staff_pin` エラー）
2. クーポン状態確認（owner, active, 有効期限内）
3. トランザクションで `status` を `redeemed` に更新

**出力**:
```json
{
  "ok": true,
  "redeemedAt": "2025-01-15T10:00:00Z",
  "discountValueYen": 500
}
```

### エラーメッセージ

すべてのエラーは日本語で表示されます：

| エラーコード | メッセージ |
|-------------|----------|
| `insufficient_points` | ポイントが不足しています |
| `invalid_staff_pin` | スタッフ用PINが正しくありません |
| `already_redeemed` | このクーポンは既に使用済みです |
| `expired` | このクーポンは有効期限が切れています |
| `functions/not-found` | クーポンが見つかりません |
| `functions/unauthenticated` | ログインが必要です。再度ログインしてください。 |
| `functions/permission-denied` | 権限がありません |
| `functions/unavailable` | サーバーに接続できません。ネットワーク接続を確認してください。 |
| `functions/deadline-exceeded` | 処理がタイムアウトしました。もう一度お試しください。 |

### デプロイ手順

#### 1. Cloud Functions デプロイ

```bash
cd functions
npm install
npm run build
npm run deploy
```

#### 2. Firestore Rules デプロイ

```bash
firebase deploy --only firestore:rules
```

#### 3. テンプレート初期化

アプリ起動時に自動実行、または手動で `ensureFuelVoucherTemplate` を呼び出し。

#### 4. スタッフPIN設定

上記「スタッフPIN設定」セクションの手順に従う。

### セキュリティ

- ✅ `users/{uid}/coupons` の直接書き込みは禁止（write: false）
- ✅ クーポン発行・消込みはすべて Cloud Functions 経由
- ✅ スタッフPINはハッシュ化して保存（salt付き SHA-256）
- ✅ トランザクションによるポイント残高の整合性保証
- ✅ 同一クーポンの二重使用を防止

### トラブルシューティング

#### Q1: 「ポイントが不足しています」と表示される

**原因**: 現在のポイント残高が 500pt 未満です

**解決方法**: デイリーガチャや予約完了でポイントを貯めてから再度交換してください

#### Q2: 「スタッフ用PINが正しくありません」と表示される

**原因**: 入力されたPINが設定されたPINと一致しません

**解決方法**: 正しい6桁PINを入力してください。設定を確認する場合は Firestore Console で `serviceCenters/default/settings/redeem` を確認

#### Q3: クーポンが「期限切れ」になっている

**原因**: 発行から30日経過しました

**解決方法**: 有効期限内に使用してください。期限切れのクーポンは使用できません

### 今後の拡張案

1. **交換レート変動**: 需要期はポイントコスト増、閑散期は減で誘導
2. **予約完了トースト**: 予約完了時に「今だけ給油券」交差導線を追加
3. **失効警告帯連携**: M7の失効予定表示から「今使う」でクーポン交換
4. **QR/HMACコード**: PIN方式からQRコード＋HMAC検証に拡張
5. **複数店舗対応**: centerId を選択可能にする
6. **複数クーポン種類**: オイル交換券、洗車券など追加

---

## ⏰ ポイント失効 & 月次集計（Cloud Scheduler）

### 概要

M7 実装により、以下の自動処理が追加されました：

1. **ポイント失効処理**: 付与から1年経過したポイントを自動失効（毎日 JST 03:00）
2. **月次統計計算**: 前月のポイント付与/消費/失効を集計（毎月1日 JST 03:00）
3. **失効予定表示**: UI に「◯日後に△pt失効予定」インジケータを表示（30日以内）

### Cloud Scheduler 設定

#### 1. ポイント失効処理（expirePointsScheduled）

```bash
# Cloud Scheduler 作成コマンド
gcloud scheduler jobs create pubsub expire-points-daily \
  --location=asia-northeast1 \
  --schedule="0 18 * * *" \
  --time-zone="UTC" \
  --topic="firebase-schedule-expirePointsScheduled-asia-northeast1" \
  --message-body="{}" \
  --description="Daily point expiration at JST 03:00"
```

**スケジュール詳細**:
- **Cron式**: `0 18 * * *` (UTC 18:00 = JST 03:00)
- **タイムゾーン**: UTC（重要: JST 変換が必要）
- **実行内容**:
  1. 全ユーザーの pointLedger から `expiresAt <= now` のエントリを検索
  2. 失効対象がある場合、トランザクションで以下を実行:
     - users/{uid}.totalPoints から減算
     - pointLedger に type: "expire" のエントリを追加
     - 失効済みエントリに expiredProcessed フラグを設定
  3. バッチサイズ: 500エントリ/実行

**注意事項**:
- JST 03:00 = UTC 18:00（前日）
- Cloud Scheduler のタイムゾーンは UTC で設定
- 夏時間は日本にないため、年間を通じて同じ換算

#### 2. 月次統計計算（calculateMonthlyStatsScheduled）

```bash
# Cloud Scheduler 作成コマンド
gcloud scheduler jobs create pubsub calculate-monthly-stats \
  --location=asia-northeast1 \
  --schedule="0 18 1 * *" \
  --time-zone="UTC" \
  --topic="firebase-schedule-calculateMonthlyStatsScheduled-asia-northeast1" \
  --message-body="{}" \
  --description="Monthly stats calculation at JST 03:00 on 1st"
```

**スケジュール詳細**:
- **Cron式**: `0 18 1 * *` (毎月1日 UTC 18:00 = JST 03:00)
- **タイムゾーン**: UTC
- **実行内容**:
  1. 前月の YYYYMM を計算（JST基準）
  2. 全ユーザーに対して以下を実行:
     - 前月の pointLedger を集計
     - granted（付与）、spent（消費）、expired（失効）、net（純増）を計算
     - users/{uid}/stats/{YYYYMM} に保存
  3. バッチサイズ: 100ユーザー/実行

**stats ドキュメント構造**:
```typescript
{
  month: "202501",        // YYYYMM
  granted: 150,           // 付与ポイント合計
  spent: 50,              // 消費ポイント合計
  expired: 10,            // 失効ポイント合計
  net: 90,                // 純増（granted - spent - expired）
  closingBalance: 340,    // 月末残高
  createdAt: Timestamp    // 作成日時
}
```

### 手動デバッグ手順

開発用の callable 関数が用意されています：

#### 特定ユーザーのポイント失効処理

```dart
// Flutter から実行
final functions = FirebaseFunctions.instanceFor(region: 'asia-northeast1');
final result = await functions.httpsCallable('expirePointsDev').call({
  'uid': 'user123',
});

print(result.data);
// { ok: true, uid: 'user123', expired: 120, entries: 3 }
```

#### 特定ユーザーの月次統計計算

```dart
// Flutter から実行
final functions = FirebaseFunctions.instanceFor(region: 'asia-northeast1');
final result = await functions.httpsCallable('calculateMonthlyStatsDev').call({
  'uid': 'user123',
  'month': '202501',  // オプション、省略時は前月
});

print(result.data);
// { ok: true, uid: 'user123', month: '202501', stats: {...} }
```

#### Firebase Emulator での動作確認

```bash
# Emulator起動
firebase emulators:start

# 別ターミナルで curl実行
curl -X POST http://localhost:5001/soup-rewards-app/asia-northeast1/expirePointsDev \
  -H "Content-Type: application/json" \
  -d '{"data": {"uid": "test-user-123"}}'
```

### UTC/JST 時刻換算表

| JST      | UTC（前日） | Cron式         | 説明                 |
|----------|-------------|----------------|----------------------|
| 00:00    | 15:00       | `0 15 * * *`   | 深夜0時              |
| 03:00    | 18:00       | `0 18 * * *`   | 深夜3時（推奨）      |
| 06:00    | 21:00       | `0 21 * * *`   | 早朝6時              |
| 09:00    | 00:00       | `0 0 * * *`    | 朝9時                |
| 12:00    | 03:00       | `0 3 * * *`    | 正午                 |

**換算式**: `JST時刻 - 9時間 = UTC時刻`

### UI: 失効予定インジケータ

PointsScreen に自動的に表示されます：

```
┌─────────────────────────────────────────┐
│ ⚠️  14日後に 120pt 失効予定              │
└─────────────────────────────────────────┘
```

**表示条件**:
- 30日以内に失効予定のポイントがある場合のみ表示
- 失効予定ポイントの合計を表示
- 最も早い失効日までの日数を表示

**非表示条件**:
- 失効予定ポイントが0の場合
- 失効予定日が30日より先の場合

### トラブルシューティング

#### Q1: Scheduler が実行されない

**確認事項**:
1. Cloud Scheduler API が有効化されているか確認
   ```bash
   gcloud services enable cloudscheduler.googleapis.com
   ```
2. Pub/Sub トピックが正しく作成されているか確認
   ```bash
   gcloud pubsub topics list --filter="name:firebase-schedule"
   ```
3. Functions のログを確認
   ```bash
   gcloud functions logs read expirePointsScheduled --limit 50
   ```

#### Q2: タイムゾーンがずれている

**解決方法**:
- Cloud Scheduler のタイムゾーンは必ず `UTC` に設定
- Cron式で9時間前の時刻を指定（JST 03:00 → UTC 18:00）
- Functions 内部の日時計算は JST 基準で実装済み

#### Q3: expirePointsDev が認証エラーになる

**解決方法**:
- Firebase Auth でログイン済みであることを確認
- uid パラメータを正しく指定
- 本番環境では管理者のみ実行可能にする設定を追加推奨

---

## 🔐 Firestore Rules 検証（Rules Playground）

### 概要

Firestore Security Rules は、クライアント側からの不正な書き込みを防ぐ最後の砦です。
以下の Rules Playground 検証手順を使用して、ルールが正しく機能していることを確認してください。

### Rules Playground アクセス方法

1. Firebase Console を開く
2. Firestore Database → Rules タブをクリック
3. 右上の「Rules Playground」ボタンをクリック

### 検証シナリオ

#### ✅ シナリオ1: 自分の vehicles を読み取り（Allowed）

```
Location: /users/test-user-123/vehicles/vehicle-001
Type: get
Auth: Authenticated (Custom UID: test-user-123)

Expected Result: ✅ Allowed
Reason: 本人は自分の車両情報を読み取れる
```

**手順**:
1. Location に `/users/test-user-123/vehicles/vehicle-001` を入力
2. Simulation type: `get` を選択
3. Auth: `Authenticated` を選択
4. Provider: `Custom` を選択
5. UID に `test-user-123` を入力
6. 「Run」をクリック

**期待結果**: ✅ **Allow** が表示される

---

#### ❌ シナリオ2: vehicles の物理削除（Denied）

```
Location: /users/test-user-123/vehicles/vehicle-001
Type: delete
Auth: Authenticated (Custom UID: test-user-123)

Expected Result: ❌ Permission denied
Reason: 物理削除は禁止（論理削除フラグで運用）
```

**手順**:
1. Location に `/users/test-user-123/vehicles/vehicle-001` を入力
2. Simulation type: `delete` を選択
3. Auth: `Authenticated` を選択
4. UID に `test-user-123` を入力
5. 「Run」をクリック

**期待結果**: ❌ **Permission denied** が表示される

---

#### ❌ シナリオ3: serviceHistory への書き込み（Denied）

```
Location: /users/test-user-123/vehicles/vehicle-001/serviceHistory/history-001
Type: create
Auth: Authenticated (Custom UID: test-user-123)

Data:
{
  "serviceAt": "2025-01-15T10:00:00Z",
  "odometer": 50000,
  "items": ["オイル交換", "タイヤローテーション"],
  "shop": "SOUP 徳島店",
  "createdAt": "2025-01-15T10:00:00Z"
}

Expected Result: ❌ Permission denied
Reason: 整備履歴は店舗/Functions のみが書き込める
```

**手順**:
1. Location に `/users/test-user-123/vehicles/vehicle-001/serviceHistory/history-001` を入力
2. Simulation type: `create` を選択
3. Auth: `Authenticated` を選択
4. UID に `test-user-123` を入力
5. Data に上記 JSON を入力
6. 「Run」をクリック

**期待結果**: ❌ **Permission denied** が表示される

---

#### ❌ シナリオ4: warranties への書き込み（Denied）

```
Location: /users/test-user-123/vehicles/vehicle-001/warranties/warranty-001
Type: create
Auth: Authenticated (Custom UID: test-user-123)

Data:
{
  "provider": "SOUP保証プラン",
  "policyNumber": "W-2025-001",
  "startAt": "2025-01-01T00:00:00Z",
  "endAt": "2026-01-01T00:00:00Z",
  "coverage": "3年間総合保証",
  "createdAt": "2025-01-15T10:00:00Z"
}

Expected Result: ❌ Permission denied
Reason: 保証情報は店舗/Functions のみが書き込める
```

**手順**:
1. Location に `/users/test-user-123/vehicles/vehicle-001/warranties/warranty-001` を入力
2. Simulation type: `create` を選択
3. Auth: `Authenticated` を選択
4. UID に `test-user-123` を入力
5. Data に上記 JSON を入力
6. 「Run」をクリック

**期待結果**: ❌ **Permission denied** が表示される

---

#### ❌ シナリオ5: bookings への書き込み（Denied）

```
Location: /bookings/booking-001
Type: create
Auth: Authenticated (Custom UID: test-user-123)

Data:
{
  "userId": "test-user-123",
  "centerId": "default",
  "date": "20250120",
  "slotId": "1000",
  "serviceType": "オイル交換",
  "status": "confirmed",
  "createdAt": "2025-01-15T10:00:00Z"
}

Expected Result: ❌ Permission denied
Reason: 予約作成は Functions のみ（createBooking Callable）
```

**手順**:
1. Location に `/bookings/booking-001` を入力
2. Simulation type: `create` を選択
3. Auth: `Authenticated` を選択
4. UID に `test-user-123` を入力
5. Data に上記 JSON を入力
6. 「Run」をクリック

**期待結果**: ❌ **Permission denied** が表示される

---

#### ✅ シナリオ6: 自分の bookings を読み取り（Allowed）

```
Location: /bookings/booking-001
Type: get
Auth: Authenticated (Custom UID: test-user-123)

Existing Data:
{
  "userId": "test-user-123",
  "centerId": "default",
  "date": "20250120",
  "slotId": "1000",
  "serviceType": "オイル交換",
  "status": "confirmed"
}

Expected Result: ✅ Allowed
Reason: 本人は自分の予約を読み取れる
```

**手順**:
1. Location に `/bookings/booking-001` を入力
2. Simulation type: `get` を選択
3. Auth: `Authenticated` を選択
4. UID に `test-user-123` を入力
5. Existing data に上記 JSON を入力（`get` では必要）
6. 「Run」をクリック

**期待結果**: ✅ **Allow** が表示される

---

#### ❌ シナリオ7: 他人の bookings を読み取り（Denied）

```
Location: /bookings/booking-001
Type: get
Auth: Authenticated (Custom UID: other-user-456)

Existing Data:
{
  "userId": "test-user-123",
  "centerId": "default",
  "status": "confirmed"
}

Expected Result: ❌ Permission denied
Reason: 他人の予約は読み取れない
```

**手順**:
1. Location に `/bookings/booking-001` を入力
2. Simulation type: `get` を選択
3. Auth: `Authenticated` を選択
4. UID に `other-user-456` を入力（重要: userId と異なる）
5. Existing data に上記 JSON を入力
6. 「Run」をクリック

**期待結果**: ❌ **Permission denied** が表示される

---

### 検証チェックリスト

すべてのシナリオで期待通りの結果が得られることを確認してください：

- ✅ シナリオ1: vehicles 読み取り → **Allowed**
- ❌ シナリオ2: vehicles 削除 → **Permission denied**
- ❌ シナリオ3: serviceHistory 作成 → **Permission denied**
- ❌ シナリオ4: warranties 作成 → **Permission denied**
- ❌ シナリオ5: bookings 作成 → **Permission denied**
- ✅ シナリオ6: 自分の bookings 読み取り → **Allowed**
- ❌ シナリオ7: 他人の bookings 読み取り → **Permission denied**

### トラブルシューティング

#### Q1: すべてのシナリオで "simulated" と表示される

**原因**: Playground はシミュレーションモードです

**解決方法**: これは正常です。"Allow" または "Permission denied" の結果を確認してください

#### Q2: Allowed/Denied が期待と逆になる

**原因**: ルールが正しくデプロイされていない可能性があります

**解決方法**:
```bash
firebase deploy --only firestore:rules
```
でルールを再デプロイし、数分待ってから再度テストしてください

#### Q3: UID の設定方法がわからない

**解決方法**:
1. Simulation type で `Authenticated` を選択
2. Provider で `Custom` を選択
3. UID フィールドに任意のユーザーID（例: `test-user-123`）を入力

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
