# 🔥 Firebase セットアップ手順書

**SOUP Rewards App** のFirebase統合手順です。この手順を完了するとアプリが正常にビルド・実行できます。

## 📋 前提条件

- Googleアカウント（Firebase Console用）
- Flutter SDK 3.4.0以上
- FlutterFire CLI

## 🚀 セットアップ手順

### Step 1: Firebase プロジェクト作成

1. [Firebase Console](https://console.firebase.google.com/) にアクセス
2. 「プロジェクトを追加」をクリック
3. プロジェクト名: `soup-rewards-app`（または任意）
4. Google Analytics を有効化（推奨）
5. プロジェクト作成完了

---

### Step 2: FlutterFire CLI インストール

```bash
# FlutterFire CLIをグローバルインストール
dart pub global activate flutterfire_cli

# PATHを通す（未設定の場合）
export PATH="$PATH":"$HOME/.pub-cache/bin"
```

---

### Step 3: Firebase アプリ登録 & 設定ファイル生成

```bash
# プロジェクトルートで実行
cd /path/to/soup_rewards_app

# Firebase設定（対話形式）
flutterfire configure \
  --project=soup-rewards-app \
  --platforms=ios,android \
  --ios-bundle-id=com.kanamurayusaku.soup_rewards \
  --android-package-name=com.kanamurayusaku.soup_rewards
```

**実行後、以下のファイルが自動生成されます：**
- ✅ `lib/firebase_options.dart` - Flutter用設定
- ✅ `ios/Runner/GoogleService-Info.plist` - iOS用設定
- ✅ `android/app/google-services.json` - Android用設定
- ✅ `ios/firebase_app_id_file.json` - Firebase App ID

---

### Step 4: iOS 設定追加

#### 4-1. Xcode プロジェクト設定

```bash
open ios/Runner.xcworkspace
```

Xcodeで以下を確認：
1. **Runner** → **TARGETS** → **Runner** → **General**
2. **Bundle Identifier**: `com.kanamurayusaku.soup_rewards` に設定
3. **GoogleService-Info.plist** が `Runner/` ディレクトリに存在することを確認

#### 4-2. Podfile 更新（必要に応じて）

```ruby
# ios/Podfile に以下が含まれているか確認
platform :ios, '14.0'
```

```bash
cd ios && pod install --repo-update && cd ..
```

---

### Step 5: Android 設定追加

#### 5-1. google-services プラグイン追加

`android/build.gradle` に以下を追加（未追加の場合）：

```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

`android/app/build.gradle` に以下を追加（最下行）：

```gradle
apply plugin: 'com.google.gms.google-services'
```

#### 5-2. google-services.json 確認

```bash
ls -la android/app/google-services.json
# ファイルが存在すればOK
```

---

### Step 6: main.dart 修正

`lib/main.dart` を以下のように修正：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // ← 追加
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'features/home/presentation/pages/main_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase初期化（修正）
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // ← 修正
  );

  runApp(
    const ProviderScope(
      child: SoupRewardsApp(),
    ),
  );
}

class SoupRewardsApp extends StatelessWidget {
  const SoupRewardsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const MainPage(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.2),
            ),
          ),
          child: child!,
        );
      },
    );
  }
}
```

---

### Step 7: Firebase サービス有効化

Firebase Consoleで以下のサービスを有効化：

#### 7-1. Authentication
1. Firebase Console → **Authentication** → **始める**
2. **Sign-in method** タブ → **メール/パスワード** を有効化
3. （オプション）**Google認証** も有効化

#### 7-2. Firestore Database
1. Firebase Console → **Firestore Database** → **データベースの作成**
2. **本番環境モード** で開始（後でセキュリティルール設定）
3. ロケーション: `asia-northeast1`（東京）推奨

#### 7-3. Cloud Messaging
1. Firebase Console → **Cloud Messaging** → **始める**
2. **APNs認証キー** アップロード（iOS用）
   - Apple Developer → Certificates → Keys → 新規作成
   - **Apple Push Notifications service (APNs)** を選択
   - ダウンロードした `.p8` ファイルをアップロード

#### 7-4. Analytics（自動有効）
- プロジェクト作成時にAnalyticsを有効化していれば自動設定

---

### Step 8: ビルド確認

```bash
# iOS
flutter build ios --debug --no-codesign

# Android
flutter build apk --debug

# 実機実行
flutter run
```

**成功すれば、Firebase接続完了！** 🎉

---

## 🔐 セキュリティ設定

### .gitignore 確認

以下のファイルが `.gitignore` に含まれているか確認：

```gitignore
# Firebase
google-services.json
GoogleService-Info.plist
firebase_options.dart
ios/Runner/GoogleService-Info.plist
ios/firebase_app_id_file.json
```

**⚠️ 重要**: これらのファイルにはAPIキーが含まれるため、Gitにコミット**しないでください**。

---

## 📊 Firestore セキュリティルール設定

Firebase Console → **Firestore Database** → **ルール** タブ：

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function isAuthenticated() {
      return request.auth != null;
    }

    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }

    // ユーザープロファイル
    match /users/{userId} {
      allow read, write: if isOwner(userId);
    }

    // ポイント履歴（読み取りのみ）
    match /users/{userId}/points/{pointId} {
      allow read: if isOwner(userId);
      allow write: if false; // 管理者のみ
    }

    // クーポン
    match /coupons/{couponId} {
      allow read: if isAuthenticated();
      allow write: if false; // 管理者のみ
    }

    // ニュース
    match /news/{newsId} {
      allow read: if true; // 全員閲覧可
      allow write: if false; // 管理者のみ
    }
  }
}
```

「**公開**」ボタンでデプロイ。

---

## 🧪 動作確認

### テストコード追加

```dart
// test/firebase_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:soup_rewards_app/firebase_options.dart';

void main() {
  test('Firebase options are configured', () {
    expect(DefaultFirebaseOptions.currentPlatform, isNotNull);
  });
}
```

```bash
flutter test test/firebase_test.dart
```

---

## 🆘 トラブルシューティング

### ❌ エラー: "No Firebase App '[DEFAULT]' has been created"

**原因**: `Firebase.initializeApp()` が実行されていない

**解決策**:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(...);
}
```

---

### ❌ iOS ビルドエラー: "GoogleService-Info.plist not found"

**原因**: Xcodeプロジェクトに追加されていない

**解決策**:
1. Xcodeで `ios/Runner.xcworkspace` を開く
2. `GoogleService-Info.plist` を **Runner** フォルダにドラッグ&ドロップ
3. **Copy items if needed** にチェック
4. **Add to targets: Runner** にチェック

---

### ❌ Android ビルドエラー: "google-services.json is missing"

**原因**: ファイルが正しい場所にない

**解決策**:
```bash
# 正しい配置場所を確認
ls -la android/app/google-services.json

# ない場合は flutterfire configure を再実行
flutterfire configure
```

---

## 📚 参考リンク

- [FlutterFire 公式ドキュメント](https://firebase.flutter.dev/)
- [Firebase Console](https://console.firebase.google.com/)
- [FlutterFire CLI](https://github.com/invertase/flutterfire_cli)

---

**次のステップ**: iOS/Android の権限設定（FIREBASE_SETUP.md → PERMISSIONS_SETUP.md）
