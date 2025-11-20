# Claude Code 用ターミナル作業リスト（最新版）

## 📋 作業概要

SOUP RewardsアプリのFirestore対応準備とUI改善が完了しました。
以下の手順で環境チェックと実機テストを進めてください。

---

## ✅ 事前確認チェックリスト

### 1. プロジェクトの基本状態確認

```bash
# プロジェクトディレクトリに移動
cd /Users/kanemurayuusaku/soup_rewards_app

# 現在のブランチとコミット状態を確認
git status

# 最新の変更を確認
git log --oneline -5
```

**確認ポイント:**
- 作業中の変更がコミットされているか
- 未コミットの変更がある場合は内容を確認

---

## 🔧 2. 依存関係の確認と更新

```bash
# 依存関係を取得
flutter pub get

# 依存関係の競合がないか確認
flutter pub outdated

# 静的解析を実行
flutter analyze
```

**確認ポイント:**
- `cloud_firestore` が正しくインストールされているか
- `firebase_core`, `firebase_auth` が最新か
- エラーが0件であること（infoレベルの警告は許容）

**期待される結果:**
```
No issues found! (ran in X.Xs)
```

---

## 🔥 3. Firebase設定ファイルの確認

### 3-1. firebase_options.dart の確認

```bash
# firebase_options.dart の存在確認
ls -la lib/firebase_options.dart

# 内容を確認（プロジェクトIDが正しいか）
grep -n "projectId" lib/firebase_options.dart
```

**確認ポイント:**
- ファイルが存在するか
- プロジェクトIDが `soup-rewrd-app` になっているか
- すべてのプラットフォーム（android, ios, macos, web）の設定が含まれているか

### 3-2. Android設定ファイルの確認

```bash
# google-services.json の存在確認
ls -la android/app/google-services.json

# 内容を確認（プロジェクトIDが正しいか）
grep -n "project_id" android/app/google-services.json
```

**確認ポイント:**
- ファイルが存在するか
- `android/app/build.gradle` に `google-services` プラグインが適用されているか

### 3-3. iOS設定ファイルの確認

```bash
# GoogleService-Info.plist の存在確認
ls -la ios/Runner/GoogleService-Info.plist
ls -la macos/Runner/GoogleService-Info.plist

# Xcodeプロジェクトに正しく追加されているか確認
# （手動でXcodeを開いて確認する必要がある場合あり）
```

**確認ポイント:**
- ファイルが存在するか
- Xcodeプロジェクトに正しく追加されているか
- `ios/Runner.xcodeproj/project.pbxproj` に参照が含まれているか

---

## 🔐 4. Firebase CLI の確認

```bash
# Firebase CLI のバージョン確認
firebase --version

# 現在のプロジェクト確認
firebase use

# プロジェクトが正しく設定されているか確認
firebase projects:list
```

**確認ポイント:**
- Firebase CLI がインストールされているか（v14.24.1以上推奨）
- プロジェクト `soup-rewrd-app` が選択されているか

**期待される結果:**
```
Now using project soup-rewrd-app
```

---

## 📜 5. Firestoreセキュリティルールの確認とデプロイ

### 5-1. 現在のルールを確認

```bash
# Firestoreルールファイルを確認
cat firestore.rules

# ルールの構文チェック
firebase deploy --only firestore:rules --dry-run
```

**確認ポイント:**
- `users/{userId}` コレクションのルールが正しく設定されているか
- 匿名認証を想定したルールになっているか（現時点では `isOwner` を使用）

### 5-2. ルールをデプロイ

```bash
# Firestoreルールをデプロイ
firebase deploy --only firestore:rules

# デプロイ結果を確認
```

**確認ポイント:**
- デプロイが成功したか
- エラーメッセージがないか

### 5-3. 日次くじ機能用のルール案（将来の匿名認証対応）

現在のルールはメール認証前提ですが、匿名認証導入時は以下に変更：

```javascript
// users/{userId} コレクション（匿名認証対応版）
match /users/{userId} {
  // 匿名認証済みユーザーは自分のデータのみ読み書き可能
  allow read, write: if isAuthenticated() && request.auth.uid == userId;
}
```

**注意:** 現時点では既存のルールで動作しますが、匿名認証を実装する際は上記に更新してください。

---

## 📊 6. Firestoreインデックスの確認

```bash
# インデックス設定を確認
cat firestore.indexes.json

# インデックスをデプロイ（必要に応じて）
firebase deploy --only firestore:indexes
```

**確認ポイント:**
- 日次くじ機能で必要なインデックスが設定されているか
- 現時点では単純なクエリのみなので、追加のインデックスは不要な可能性が高い

---

## 🏗️ 7. コードの静的解析とビルド確認

### 7-1. 静的解析

```bash
# 全体のエラー確認
flutter analyze

# ポイント機能のみの確認
flutter analyze lib/features/points/

# エラーが0件であることを確認
```

**確認ポイント:**
- エラーが0件であること
- 警告があれば内容を確認（infoレベルの警告は許容）

### 7-2. iOS ビルド確認

```bash
# iOSシミュレータでビルド確認
flutter build ios --debug

# または直接実行
flutter run -d ios
```

**確認ポイント:**
- ビルドエラーがないか
- `GoogleService-Info.plist` が正しく読み込まれているか
- 「CLIENT OF UIKIT REQUIRES UPDATE」警告が出た場合の対処（後述）

**よくある警告と対処:**
- `CLIENT OF UIKIT REQUIRES UPDATE`: 無視してOK（iOS 18対応の警告）
- `bitcode`: 無視してOK（Xcode 14以降では不要）

### 7-3. Android ビルド確認

```bash
# Androidエミュレータでビルド確認
flutter build apk --debug

# または直接実行
flutter run -d android
```

**確認ポイント:**
- ビルドエラーがないか
- `google-services.json` が正しく読み込まれているか

---

## 🧪 8. モック実装での動作確認

### 8-1. アプリの起動

```bash
# 利用可能なデバイスを確認
flutter devices

# アプリを起動（推奨：実機またはシミュレータ）
flutter run

# または特定のデバイスで起動
flutter run -d <device-id>
```

### 8-2. ポイント画面の動作確認

**確認項目:**
- [ ] アプリが正常に起動するか
- [ ] 「ポイント」タブを開いて画面が表示されるか
- [ ] ポイント残高が `0P` と表示されるか（初回起動時）
- [ ] 「本日のポイントを受け取る」ボタンが表示されるか
- [ ] ボタンをタップしてくじが引けるか
- [ ] くじ結果のアニメーションが表示されるか
- [ ] ポイントが増えるか（例：+20P → 20P）
- [ ] ランク表示が正しく表示されるか（EV BRONZE）
- [ ] 2回目以降は「受け取り済み」表示になるか
- [ ] プルダウンリフレッシュが動作するか

### 8-3. UIの確認

**確認項目:**
- [ ] ポイント残高カードのグラデーションが美しく表示されるか
- [ ] 日次くじボタンのタップアニメーションが滑らかか
- [ ] ランク表示のバッジデザインが正しく表示されるか
- [ ] ライトモードとダークモードの両方で美しく見えるか
- [ ] フォントサイズと余白が適切か

---

## 🔄 9. Firestore実装への切り替え準備

### 9-1. 切り替え前の確認

```bash
# app_providers.dart の useFirestore フラグを確認
grep -n "useFirestore" lib/core/providers/app_providers.dart
```

**確認ポイント:**
- `useFirestore = false` になっていること（現時点ではモック実装を使用）

### 9-2. Firestore実装への切り替え（動作確認後）

1. `lib/core/providers/app_providers.dart` を開く
2. `const useFirestore = false;` を `const useFirestore = true;` に変更
3. アプリを再起動して動作確認

**確認項目:**
- [ ] Firestoreにデータが正しく保存されるか
- [ ] Firestoreコンソールで `users/{userId}` ドキュメントが作成されるか
- [ ] ポイントが正しく更新されるか
- [ ] 日次くじの状態が正しく保存・読み取りされるか

### 9-3. Firestoreコンソールでの確認

1. [Firebase Console](https://console.firebase.google.com/project/soup-rewrd-app/firestore) にアクセス
2. Firestore データベースを開く
3. `users` コレクションを確認

**確認ポイント:**
- ドキュメント構造が正しいか
  - `shopId: string`
  - `points: number`
  - `lastDailyDrawAt: Timestamp`
  - `todayDrawPoints: number`
- データが正しく保存・更新されているか

---

## 📱 10. iOS実機ビルドの確認方法

### 10-1. リリースビルドの作成

```bash
# リリースビルドを作成
flutter build ios --release

# Xcodeで開く
open ios/Runner.xcworkspace
```

### 10-2. Xcodeでの確認

1. Xcodeでプロジェクトを開く
2. Product → Scheme → Runner を選択
3. Product → Destination → 実機を選択
4. Product → Archive を実行

**確認ポイント:**
- `GoogleService-Info.plist` がプロジェクトに追加されているか
- Signing & Capabilities で正しいTeamが選択されているか
- Provisioning Profile が正しく設定されているか

### 10-3. よくある警告の対処

**「CLIENT OF UIKIT REQUIRES UPDATE」警告:**
- これはiOS 18対応の警告で、現時点では無視してOK
- 将来的にXcodeを更新すれば解消される

**「bitcode」関連の警告:**
- Xcode 14以降ではbitcodeは不要
- 無視してOK

---

## 🎨 11. ポイント画面の実機UI確認手順

### 11-1. 基本動作確認

1. アプリを起動
2. 下部タブから「ポイント」をタップ
3. 以下を順番に確認：

**くじを引く前:**
- [ ] ポイント残高カードが美しく表示されるか
- [ ] 「本日のポイントを受け取る」ボタンが大きく表示されるか
- [ ] ボタンをタップした瞬間に拡大アニメーションが動作するか
- [ ] ランク表示（EV BRONZE）がバッジ風に表示されるか

**くじを引いた後:**
- [ ] くじ結果のアニメーション（+20P獲得！）が滑らかに表示されるか
- [ ] ポイント残高が正しく更新されるか
- [ ] 「受け取り済み」表示が美しく表示されるか
- [ ] ランク表示が正しく更新されるか

### 11-2. アニメーションの確認

**確認項目:**
- [ ] くじ結果表示のスケールアニメーションが滑らかか
- [ ] ボタンのタップ時の拡大アニメーションが自然か
- [ ] 3秒後にくじ結果が消えるか

### 11-3. Firestoreへの書き込み確認（useFirestore = true 時）

1. アプリでくじを引く
2. Firebase ConsoleでFirestoreを確認
3. `users/localUser` ドキュメントを確認

**確認項目:**
- [ ] ドキュメントが作成されるか
- [ ] `points` フィールドが正しく更新されるか
- [ ] `lastDailyDrawAt` が正しく保存されるか
- [ ] `todayDrawPoints` が正しく保存されるか

---

## 🔒 12. Firestoreセキュリティルールの暫定案

### 12-1. 開発環境用ルール（dev）

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 開発環境：全員が読み書き可能（テスト用）
    match /users/{userId} {
      allow read, write: if true;
    }
  }
}
```

**注意:** 本番環境では絶対に使用しないでください。

### 12-2. 本番環境用ルール（production）

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 本番環境：匿名認証済みユーザーは自分のデータのみ読み書き可能
    match /users/{userId} {
      allow read, write: if isAuthenticated() && request.auth.uid == userId;
    }
  }
}
```

**デプロイ方法:**
```bash
# ルールをデプロイ
firebase deploy --only firestore:rules
```

---

## 🔍 13. Mock版とFirestore版の動作差分チェックリスト

### 13-1. データ永続化

| 項目 | Mock版 | Firestore版 |
|------|--------|-------------|
| データ保存先 | SharedPreferences（ローカル） | Firestore（クラウド） |
| デバイス間同期 | ❌ なし | ✅ あり（同一userId） |
| オフライン対応 | ✅ あり | ⚠️ 制限あり |

### 13-2. 初回起動時の動作

| 項目 | Mock版 | Firestore版 |
|------|--------|-------------|
| 初期ポイント | 0P | 0P（自動生成） |
| ドキュメント作成 | 自動 | 自動（初回アクセス時） |

### 13-3. エラーハンドリング

| 項目 | Mock版 | Firestore版 |
|------|--------|-------------|
| ネットワークエラー | 発生しない | 発生する可能性あり |
| 権限エラー | 発生しない | 発生する可能性あり |
| エラー時の動作 | 現在の値を維持 | 初期状態にフォールバック |

### 13-4. 確認すべき動作差分

**切り替え前に確認:**
- [ ] Mock版で正常に動作することを確認
- [ ] ポイントが正しく保存・読み取りされることを確認
- [ ] 日次くじが1日1回制限で動作することを確認

**切り替え後に確認:**
- [ ] Firestore版でも同様に動作することを確認
- [ ] Firestoreコンソールでデータが正しく保存されることを確認
- [ ] ネットワークエラー時の動作を確認（オフライン時など）

---

## 🚨 14. エラーハンドリングの確認

アプリ実行中に以下のエラーが発生した場合の対処：

### 14-1. Firebase初期化エラー

```
Firebase initialization skipped: ...
```

**対処:**
```bash
# firebase_options.dart を再生成
flutterfire configure --project=soup-rewrd-app
```

### 14-2. Firestore権限エラー

```
PERMISSION_DENIED: Missing or insufficient permissions.
```

**対処:**
1. `firestore.rules` を確認
2. ルールを再デプロイ: `firebase deploy --only firestore:rules`
3. Firebase ConsoleでFirestoreが有効になっているか確認

### 14-3. ビルドエラー（iOS）

```bash
# クリーンビルドを実行
flutter clean
cd ios && pod install && cd ..
flutter pub get
flutter build ios --debug
```

### 14-4. ビルドエラー（Android）

```bash
# クリーンビルドを実行
flutter clean
flutter pub get
flutter build apk --debug
```

**確認ポイント:**
- `android/app/build.gradle` で `google-services` プラグインが適用されているか
- `android/build.gradle` で `google-services` クラスパスが追加されているか

---

## 📝 15. 最終確認チェックリスト

### コード品質
- [ ] `flutter analyze` でエラー0件
- [ ] すべてのファイルが正しくインポートされている
- [ ] TODOコメントが適切に配置されている

### Firebase設定
- [ ] `firebase_options.dart` が存在し、正しく設定されている
- [ ] `google-services.json` が存在する（Android）
- [ ] `GoogleService-Info.plist` が存在する（iOS/macOS）
- [ ] Firestoreルールがデプロイ済み

### 機能動作
- [ ] アプリが正常に起動する
- [ ] ポイント画面が表示される
- [ ] 日次くじ機能が動作する
- [ ] ランク表示が正しく表示される
- [ ] UIが美しく表示される（ライト/ダークモード両方）

### Firestore対応（useFirestore = true 時）
- [ ] Firestoreにデータが保存される
- [ ] Firestoreからデータが読み取れる
- [ ] エラーハンドリングが適切に動作する

---

## 🎯 次のステップ（実装後）

1. **匿名認証の実装**
   - Firebase Auth の匿名認証を有効化
   - `points_controller.dart` の `_resolveUserId()` を実装
   - Firestoreルールを匿名認証対応に更新

2. **Cloud Functions の実装（オプション）**
   - 日次くじのトランザクション処理をサーバー側で実装
   - 二重実行の防止を強化

3. **エラーハンドリングの強化**
   - ネットワークエラー時のリトライ機能
   - オフライン対応（キャッシュ機能）

4. **UI/UXの最終調整**
   - ユーザーフィードバックに基づく微調整
   - パフォーマンス最適化

---

## 💡 トラブルシューティング

### よくあるエラーと対処法

1. **`firebase_options.dart` が見つからない**
   ```bash
   flutterfire configure --project=soup-rewrd-app
   ```

2. **Firestore接続エラー**
   - Firebase ConsoleでFirestoreが有効になっているか確認
   - インターネット接続を確認
   - Firestoreルールを確認

3. **ビルドエラー（iOS）**
   ```bash
   cd ios && pod install && cd ..
   flutter clean
   flutter pub get
   ```

4. **ビルドエラー（Android）**
   - `android/app/build.gradle` で `google-services` プラグインが適用されているか確認
   - `android/build.gradle` で `google-services` クラスパスが追加されているか確認

5. **「CLIENT OF UIKIT REQUIRES UPDATE」警告**
   - これはiOS 18対応の警告で、現時点では無視してOK
   - アプリの動作には影響しない

---

## 📊 実装ファイル一覧

### 新規作成
- `lib/features/points/domain/utils/points_initializer.dart`
- `lib/features/points/data/repositories/firestore_points_repository.dart`
- `lib/core/constants/app_config.dart`

### 編集
- `lib/core/providers/app_providers.dart`
- `lib/features/points/application/points_controller.dart`
- `lib/features/points/data/repositories/mock_points_repository.dart`
- `lib/features/points/presentation/widgets/points_balance_display.dart`
- `lib/features/points/presentation/widgets/daily_draw_button.dart`
- `lib/features/points/presentation/widgets/draw_result_display.dart`
- `lib/features/points/presentation/widgets/next_rank_display.dart`
- `lib/features/points/presentation/pages/points_page.dart`

---

## 🔐 16. ログイン導線のリデザイン確認

### 16-1. 起動時の画面確認

**確認項目:**
- [ ] アプリ起動時に `MainPage`（ホームタブ）が表示されるか
- [ ] ログイン画面が自動的に表示されないか
- [ ] ゲスト状態でもアプリが正常に動作するか

**確認方法:**
```bash
# アプリを起動
flutter run

# 起動直後の画面を確認
# → ホームタブが表示されることを確認
# → ログイン画面が表示されないことを確認
```

### 16-2. マイページからのログイン導線確認

**確認項目:**
- [ ] マイページタブを開いて「現在：ゲスト利用中」が表示されるか
- [ ] 「ログイン / 会員登録」ボタンが表示されるか
- [ ] ボタンをタップして `LoginPage` に遷移できるか

**確認方法:**
1. アプリを起動
2. 下部タブから「マイページ」をタップ
3. 「ログイン / 会員登録」ボタンをタップ
4. `LoginPage` が表示されることを確認

### 16-3. LoginPage の確認

**確認項目:**
- [ ] メールアドレスとパスワードの入力フォームが表示されるか
- [ ] 「新規会員登録」ボタンが下部に表示されるか
- [ ] 「新規会員登録」ボタンをタップして `SignupPage` に遷移できるか
- [ ] エラーメッセージが日本語で分かりやすく表示されるか

**確認方法:**
1. マイページから `LoginPage` に遷移
2. フォーム下部の「新規会員登録」ボタンを確認
3. ボタンをタップして `SignupPage` に遷移できることを確認
4. 間違ったメールアドレス/パスワードでログインを試みて、エラーメッセージを確認

### 16-4. SignupPage の確認

**確認項目:**
- [ ] お名前、メールアドレス、パスワード、パスワード（確認）の入力フォームが表示されるか
- [ ] パスワードの表示/非表示を切り替えられるか
- [ ] バリデーションが正しく動作するか（空欄、メール形式、パスワード一致など）
- [ ] エラーメッセージが日本語で分かりやすく表示されるか

**確認方法:**
1. `LoginPage` から「新規会員登録」ボタンをタップ
2. 各入力フィールドの動作を確認
3. バリデーションエラーを確認
4. 正しい情報で登録を試みる

### 16-5. ゲスト状態でのポイント機能確認

**確認項目:**
- [ ] ゲスト状態（ログインしていない状態）でポイントタブを開けるか
- [ ] 日次くじ機能が正常に動作するか
- [ ] ポイントが正しく保存・表示されるか（ローカル or 匿名ユーザー）
- [ ] アプリがクラッシュしないか

**確認方法:**
1. アプリを起動（ログインしない状態）
2. 下部タブから「ポイント」をタップ
3. 「本日のポイントを受け取る」ボタンをタップ
4. くじ結果が表示され、ポイントが増えることを確認
5. アプリを再起動して、ポイントが保持されていることを確認

### 16-6. ログイン後の動作確認

**確認項目:**
- [ ] ログイン後、マイページに「ログイン済み」と表示されるか
- [ ] ログイン後のメールアドレスが表示されるか
- [ ] 「ログアウト」ボタンが表示されるか
- [ ] ログアウト後、ゲスト状態に戻るか

**確認方法:**
1. マイページからログイン
2. ログイン後のマイページを確認
3. 「ログアウト」ボタンをタップ
4. ゲスト状態に戻ることを確認

### 16-7. Firebase Auth の設定確認

**確認項目:**
- [ ] Firebase Console で Email/Password 認証が有効になっているか
- [ ] テスト用のユーザーアカウントを作成できるか

**確認方法:**
1. [Firebase Console](https://console.firebase.google.com/project/soup-rewrd-app/authentication) にアクセス
2. Authentication → Sign-in method を開く
3. 「メール/パスワード」が有効になっているか確認
4. 有効になっていない場合は有効化

**Firebase Auth の有効化手順:**
1. Firebase Console → Authentication → Sign-in method
2. 「メール/パスワード」をクリック
3. 「有効にする」を選択
4. 「保存」をクリック

---

## 📝 17. ログイン導線リデザインの最終確認チェックリスト

### コード品質
- [ ] `flutter analyze` でエラー0件
- [ ] `LoginPage` と `SignupPage` が正しく作成されている
- [ ] `ProfilePage` にログイン導線が追加されている
- [ ] エラーメッセージが日本語で表示される

### 機能動作
- [ ] アプリ起動時に `MainPage` が表示される（ログイン画面ではない）
- [ ] マイページから `LoginPage` に遷移できる
- [ ] `LoginPage` から `SignupPage` に遷移できる
- [ ] ゲスト状態でポイントタブが正常に動作する
- [ ] ログイン/ログアウトが正常に動作する

### UI/UX
- [ ] 「現在：ゲスト利用中」が表示される
- [ ] 「ログイン / 会員登録」ボタンが分かりやすい位置にある
- [ ] 「新規会員登録」への導線が明確
- [ ] エラーメッセージが分かりやすい

### Firebase設定
- [ ] Firebase Auth の Email/Password が有効になっている
- [ ] テスト用のユーザーアカウントを作成できる

---

---

## 🎨 18. ゲスト利用前提UIの確認

### 18-1. 各タブの表示確認（ゲスト状態）

**確認項目:**
- [ ] ホームタブが「Please log in to...」ではなく、SOUP Rewardsの紹介が表示されるか
- [ ] ポイントタブが「Please log in to...」ではなく、日次くじ機能が表示されるか
- [ ] クーポンタブが「Please log in to...」ではなく、仕様説明が表示されるか
- [ ] 予約タブが「Please log in to...」ではなく、説明と連絡手段が表示されるか
- [ ] すべてのタブが真っ白にならないか

**確認方法:**
1. アプリを起動（ログインしない状態）
2. 各タブを順番に開いて確認
3. 各タブで適切なコンテンツが表示されることを確認

### 18-2. ポイントタブの日次くじ機能確認（ゲスト状態）

**確認項目:**
- [ ] ゲスト状態でポイントタブを開けるか
- [ ] 日次くじ機能が正常に動作するか
- [ ] 「本日のポイントを受け取る」ボタンが表示されるか
- [ ] くじを引いてポイントが増えるか
- [ ] ランク表示が正しく表示されるか
- [ ] 「※ゲスト利用中です...」の案内が表示されるか

**確認方法:**
1. アプリを起動（ログインしない状態）
2. ポイントタブを開く
3. 「本日のポイントを受け取る」ボタンをタップ
4. くじ結果が表示され、ポイントが増えることを確認
5. ランク表示が更新されることを確認

### 18-3. ログイン状態での表示確認

**確認項目:**
- [ ] ログイン後も各タブが正常に表示されるか
- [ ] ポイントタブで「※ゲスト利用中です...」の案内が消えるか
- [ ] ホームタブで会員登録案内が消えるか（ログイン済みの場合）

**確認方法:**
1. マイページからログイン
2. 各タブを順番に開いて確認
3. ログイン状態に応じた表示になることを確認

### 18-4. 会員登録導線の確認

**確認項目:**
- [ ] ホームタブ下部の「会員ログイン / 新規登録」ボタンが表示されるか（ゲスト時）
- [ ] クーポンタブの「会員ログイン / 新規登録」ボタンが表示されるか
- [ ] ボタンをタップして LoginPage に遷移できるか

**確認方法:**
1. ゲスト状態で各タブを開く
2. 会員登録案内ボタンを確認
3. ボタンをタップして LoginPage に遷移できることを確認

---

## 📝 19. ゲスト利用前提UIの最終確認チェックリスト

### コード品質
- [ ] `flutter analyze` でエラー0件
- [ ] 各タブがログイン状態に依存せず表示される
- [ ] 「Please log in to...」メッセージが表示されない

### 機能動作
- [ ] ゲスト状態でHome/Booking/Points/Couponsがそれぞれ仕様どおり表示される
- [ ] Pointsタブで日次くじがゲスト利用でも正常に動作する
- [ ] ログインしてもしなくても、これらタブが真っ白にならない
- [ ] 会員登録導線が適切に配置されている

### UI/UX
- [ ] 各タブでSOUP Rewardsの世界観が伝わる
- [ ] ゲスト状態の案内が適切に表示される
- [ ] 会員登録のメリットが分かりやすく説明されている

---

---

## 🔍 20. "Please log in"系文言の完全除去確認

### 20-1. コードベース全体の検索

**確認項目:**
- [ ] "Please log in" 系の文言がコードベースに残っていないか
- [ ] 各タブのメインUI部分に英語のログイン要求メッセージがないか

**確認方法:**
```bash
# プロジェクトディレクトリに移動
cd /Users/kanemurayuusaku/soup_rewards_app

# "Please log in" 系の文言を検索
rg "Please log in" lib || echo "✅ No 'Please log in' found"
rg "Please log-in" lib || echo "✅ No 'Please log-in' found"
rg "Log in to" lib || echo "✅ No 'Log in to' found"
rg "Please sign in" lib || echo "✅ No 'Please sign in' found"
rg "Sign in to" lib || echo "✅ No 'Sign in to' found"
rg "Please login" lib || echo "✅ No 'Please login' found"

# 検索結果がすべて 0 件であることを確認
```

**期待される結果:**
```
✅ No 'Please log in' found
✅ No 'Please log-in' found
✅ No 'Log in to' found
✅ No 'Please sign in' found
✅ No 'Sign in to' found
✅ No 'Please login' found
```

**注意:** LoginPage / SignupPage 内の文言は、会員機能用として残しておいてOKです。

---

## 📱 21. 各タブのUI確認チェックリスト（最新版）

### 21-1. ホームタブ（HomePage）の確認

**確認項目:**
- [ ] SOUP Rewards の紹介文が日本語で表示されている
- [ ] 「カーコーティングで給油券が貯まる」の説明が表示されている
- [ ] 「SOUP Rewardsとは」セクションが表示されている
- [ ] 機能紹介カード（日次くじ／ポイント管理／ランクシステム）が並んでいる
- [ ] 各機能カードの説明文が日本語で分かりやすく表示されている
- [ ] 「会員ログイン / 新規登録」導線がある（ゲスト時のみ）
- [ ] ログイン済みの場合は会員登録案内が表示されない

**確認方法:**
1. アプリを起動（ログインしない状態）
2. ホームタブを開く
3. 上記の項目がすべて表示されることを確認
4. マイページからログイン後、会員登録案内が消えることを確認

---

### 21-2. ポイントタブ（PointsPage）の確認

**確認項目:**
- [ ] 「ゲスト利用中です。会員登録するとポイントをクラウドに保存できます。」の案内文が表示されている（ゲスト時のみ）
- [ ] ポイント残高カードが表示されている
- [ ] ポイント残高が正しく表示される（例：0P）
- [ ] 「本日のポイントを受け取る」ボタンが表示される（未受け取り時）
- [ ] くじを引くとアニメーション付きで結果が表示される
- [ ] くじ結果が表示され、ポイントが増える
- [ ] 「本日のポイントは受け取り済みです」表示が表示される（受け取り済み時）
- [ ] ランク表示（EV BRONZE / SILVER / GOLD / PLATINUM）が正しく表示される
- [ ] 次のランクまでのポイント数が表示される

**確認方法:**
1. アプリを起動（ログインしない状態）
2. ポイントタブを開く
3. 「本日のポイントを受け取る」ボタンをタップ
4. くじ結果が表示され、ポイントが増えることを確認
5. ランク表示が更新されることを確認
6. アプリを再起動して、ポイントが保持されていることを確認

---

### 21-3. クーポンタブ（CouponsPage）の確認

**確認項目:**
- [ ] 給油券クーポンに関する説明文が日本語で表示されている
- [ ] 「カーコーティング施工や日次くじで貯めたポイントは、給油券クーポンに交換できます。」の説明が表示されている
- [ ] 「現在はテスト期間中のため、クーポンの配布は順次公開予定です。」の案内がある
- [ ] 「会員登録すると、クーポン履歴を保存できます」の案内が表示されている
- [ ] 「会員ログイン / 新規登録」ボタンが表示されている（ゲスト時）
- [ ] ボタンをタップして LoginPage に遷移できる

**確認方法:**
1. アプリを起動（ログインしない状態）
2. クーポンタブを開く
3. 上記の項目がすべて表示されることを確認
4. 「会員ログイン / 新規登録」ボタンをタップして LoginPage に遷移できることを確認

---

### 21-4. 予約タブ（QrScanPage）の確認

**確認項目:**
- [ ] 予約方法の説明文が日本語で表示されている
- [ ] 「SOUPカーコーティング・洗車のご予約は、現在はお電話または店頭で受け付けています。」の説明が表示されている
- [ ] 「アプリからのWEB予約機能は順次追加予定です。」の案内がある
- [ ] 「電話で予約する」ボタンが表示されている
- [ ] 「店舗情報を見る」ボタンが表示されている
- [ ] ボタンをタップして適切なアクションが実行される（電話発信、店舗情報表示など）

**確認方法:**
1. アプリを起動（ログインしない状態）
2. 予約タブを開く
3. 上記の項目がすべて表示されることを確認
4. 「電話で予約する」ボタンをタップして電話発信が試みられることを確認（実機のみ）
5. 「店舗情報を見る」ボタンをタップして案内メッセージが表示されることを確認

---

## 📝 22. ゲスト利用前提UIの最終確認チェックリスト（更新版）

### コード品質
- [ ] `flutter analyze` でエラー0件
- [ ] 各タブがログイン状態に依存せず表示される
- [ ] 「Please log in to...」メッセージが表示されない
- [ ] すべての文言が日本語で統一されている

### 機能動作
- [ ] ゲスト状態でHome/Booking/Points/Couponsがそれぞれ仕様どおり表示される
- [ ] Pointsタブで日次くじがゲスト利用でも正常に動作する
- [ ] ログインしてもしなくても、これらタブが真っ白にならない
- [ ] 会員登録導線が適切に配置されている

### UI/UX
- [ ] 各タブでSOUP Rewardsの世界観が伝わる
- [ ] ゲスト状態の案内が適切に表示される
- [ ] 会員登録のメリットが分かりやすく説明されている
- [ ] 文言のトーンが「高級感はあるけど、堅苦しくない」感じになっている

### 文言の統一性
- [ ] 英語の残骸がない
- [ ] すべての説明文が自然な日本語になっている
- [ ] SOUPらしいトーン（カーコーティング × カフェ × EVフレンドリー）が反映されている

---

以上です。この手順に従って環境チェックと実機テストを進めてください。
