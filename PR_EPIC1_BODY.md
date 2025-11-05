# Epic 1: Authentication & Profile Implementation

## 📋 概要

Epic 1（認証&プロフィール管理）の完全実装です。匿名認証 → Apple Sign-In → プロフィール編集の全フローを実装しました。

## ✨ 実装内容

### 1. 認証機能
- **匿名ログイン**: アプリ起動後即座に利用開始できる
- **Apple Sign-In**: 匿名アカウントから永続アカウントへのシームレスなリンク
- **アカウントリンク**: 既存アカウント（credential-already-in-use）への適切な対応
- **エラーハンドリング**: CredentialAlreadyInUse, canceled等の適切な処理

### 2. データモデル
- **AppUser**: Freezedによる不変モデル
  - uid, displayName, email, isAnonymous, authProviders
  - totalPoints, totalBookings, totalGachaPlays（統計情報）
  - notificationEnabled, locale（設定）
  - deletedAt（論理削除対応）

### 3. リポジトリパターン
- **AuthRepository**:
  - `signInAnonymously()`: 匿名ログイン
  - `signInWithApple(link: bool)`: Apple認証（リンク対応）
  - `updateProfile()`: 表示名・アバター更新
  - `updateNotificationSettings()`: 通知設定
  - `deleteAccount()`: 論理削除（Cloud Function呼び出し）

### 4. Riverpod状態管理
- `authStateProvider`: Firebase Auth状態のストリーム
- `currentUserIdProvider`: 現在のユーザーID
- `appUserProvider`: Firestore usersドキュメントのストリーム

### 5. UI実装
- **LoginPage** (`lib/features/auth/presentation/pages/login_page.dart`)
  - 匿名ログインボタン
  - Apple Sign-Inボタン
  - ローディングインジケーター
  - スナックバー通知

- **ProfilePage** (`lib/features/auth/presentation/pages/profile_page.dart`)
  - アカウント情報表示（アバター、表示名、統計）
  - 匿名アカウント向けリンク促進UI
  - プロフィール編集（表示名）
  - 通知設定トグル
  - ログアウト・削除ボタン

### 6. 5タブナビゲーション
- **更新前**: 4タブ（ホーム/予約/ポイント/クーポン）
- **更新後**: 5タブ（ホーム/予約/ポイント/クーポン/プロフィール）
- 未ログイン時はLoginPageを表示

### 7. Firestoreルール強化
```javascript
match /users/{userId} {
  // 読み取り: 本人のみ
  allow read: if isOwner(userId) || isAdmin();

  // 作成: 必須フィールド検証
  allow create: if isOwner(userId)
    && request.resource.data.uid == userId
    && request.resource.data.keys().hasAll(['uid', 'createdAt', 'isAnonymous', 'authProviders'])
    && request.resource.data.isAnonymous is bool
    && request.resource.data.authProviders is list;

  // 更新: 統計フィールド保護（Cloud Functionsのみ変更可）
  allow update: if isOwner(userId)
    && !request.resource.data.diff(resource.data).affectedKeys()
      .hasAny(['uid', 'createdAt', 'totalPoints', 'totalBookings', 'totalGachaPlays']);

  // 削除: 禁止（論理削除のみ）
  allow delete: if false;
}
```

### 8. テスト
- **Unit Test**: `test/features/auth/data/repositories/auth_repository_test.dart`
  - AuthRepositoryの基本構造確認
- **Widget Test**: `test/features/auth/presentation/pages/login_page_test.dart`
  - LoginPageのUI要素確認
  - ローディング状態の表示確認

### 9. パッケージ追加
```yaml
dependencies:
  cloud_functions: ^5.1.3
  sign_in_with_apple: ^6.1.3
  freezed_annotation: ^2.4.1
  json_annotation: ^4.9.0

dev_dependencies:
  freezed: ^2.5.2
  json_serializable: ^6.8.0
```

### 10. ドキュメント更新
- **README.md**: Apple Sign-In設定手順を追加
- 主要機能セクション更新（5タブ構成）
- ディレクトリ構造にauth機能を追加

## 📸 スクリーンショット

### 1. ログイン画面（LoginPage）
<!-- TODO: スクショを追加 -->
![Login Screen](path/to/screenshot1.png)
- 匿名ログインボタン
- Apple Sign-Inボタン
- SOUPブランディング

### 2. プロフィール画面（匿名ユーザー）
<!-- TODO: スクショを追加 -->
![Profile Anonymous](path/to/screenshot2.png)
- アカウント情報表示
- リンク促進メッセージ
- 統計情報（ポイント/予約/ガチャ）

### 3. プロフィール編集
<!-- TODO: スクショを追加 -->
![Profile Edit](path/to/screenshot3.png)
- 表示名入力フィールド
- 通知設定トグル
- ログアウト・削除ボタン

### 4. Apple Sign-Inフロー
<!-- TODO: スクショを追加 -->
![Apple Sign In](path/to/screenshot4.png)
- Apple認証画面
- アカウントリンク成功メッセージ

## 🧪 テスト方法

### 前提条件
```bash
# パッケージインストール
flutter pub get

# Freezedコード生成
flutter pub run build_runner build --delete-conflicting-outputs
```

### 実機テスト手順
1. **匿名ログイン**
   ```bash
   flutter run -d <device-id>
   ```
   - 「今すぐ始める（ゲスト）」をタップ
   - → メインアプリ画面（5タブ）に遷移
   - → プロフィールタブで「匿名アカウント」と表示

2. **Apple Sign-Inリンク**
   - プロフィール画面で「Appleアカウントとリンク」をタップ
   - → Apple認証画面でサインイン
   - → プロフィールに戻り、Emailアドレスが表示される

3. **プロフィール編集**
   - 表示名を入力して「保存」
   - → 成功メッセージ表示
   - → アバターの頭文字が更新される

4. **通知設定**
   - 通知トグルをOFF → ON
   - → Firestoreに即座に反映

5. **ログアウト**
   - 「ログアウト」ボタンをタップ
   - → LoginPageに戻る

6. **再ログイン（Apple Sign-In）**
   - 「Appleでサインイン」をタップ
   - → 既存アカウントでログイン成功

## 🔒 セキュリティ考慮事項

- ✅ Firestoreルールで本人のみアクセス許可
- ✅ totalPoints/totalBookings/totalGachaPlaysはCloud Functionsのみ更新可
- ✅ CredentialAlreadyInUse時は既存アカウントへサインイン
- ✅ 論理削除（deletedAt）で30日間復元可能
- ✅ パスワード不要（Apple Sign-In / 匿名認証）

## ⚠️ 既知の制限事項

1. **Cloud Functions未実装**
   - `updateProfileAfterLink`: Functionsが存在しない場合はフォールバック処理
   - `softDeleteAccount`: 同上
   - → M5でFunctions実装予定

2. **Email認証**
   - 今回の実装では含まれない（最小実装）
   - 必要に応じて追加可能

3. **テストカバレッジ**
   - 基本的なテストのみ実装
   - モックを使った詳細テストは後続フェーズ

4. **Freezedコード生成**
   - `app_user.freezed.dart` / `app_user.g.dart` は未生成
   - ユーザーがローカルで `flutter pub run build_runner build` を実行する必要あり

## 📦 デプロイ前の確認事項

- [ ] Apple Developer CenterでSign in with Appleを有効化
- [ ] XcodeでSign in with Apple capabilityを追加
- [ ] Firebase ConsoleでApple認証を有効化
- [ ] GoogleService-Info.plistを配置
- [ ] firebase_options.dartを生成
- [ ] Freezedコード生成を実行
- [ ] iOS実機でテスト実行
- [ ] Firestore rulesをデプロイ

## 🔗 関連ドキュメント

- [Epic 1 詳細設計](.github/EPIC_1_AUTH.md)
- [Firestore Rules](firestore.rules)
- [README: Apple Sign-In設定](README.md#apple-sign-in設定ios)

## 📝 次のステップ（M5: Epic 2 ミニマム）

1. Cloud Functions実装
   - `onUserCreate`: ユーザー作成時の自動ドキュメント生成
   - `updateProfileAfterLink`: リンク後のプロフィール同期
   - `softDeleteAccount`: 論理削除処理
2. claimDailyGacha Callableの実装
3. GachaRepositoryとUI実装
4. Epic 2 PRの作成

---

**Estimated Review Time**: 30-40 minutes
**Epic**: Epic 1 (Authentication & Profile)
**Type**: Feature Implementation
**Priority**: High
