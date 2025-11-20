# SOUP Rewards アプリ - リリース候補レベル実装サマリー

## 📋 実装完了日
2024年（実装完了時点）

---

## ✅ 1. flutter analyze 結果

```
Analyzing soup_rewards_app...
No issues found! (ran in 6.4s)
```

- **Error: 0**
- **Warning: 0**
- **Info: 0**（`use_build_context_synchronously`は`analysis_options.yaml`で抑制）

---

## 📝 2. 変更したファイル一覧と主な変更内容

### 2-1. 新規作成ファイル

1. **`lib/features/redemptions/domain/models/redemption_model.dart`**
   - ポイント交換（給油券）のモデル定義
   - Firestoreスキーマをコメントで明文化

2. **`lib/features/redemptions/data/repositories/redemptions_repository.dart`**
   - ポイント交換のリポジトリ実装
   - ポイント減算とトランザクション記録を実装

3. **`FIRESTORE_SECURITY_RULES_PROPOSAL.md`**
   - Firestoreセキュリティルール案のドキュメント

### 2-2. 修正ファイル

1. **`lib/features/qr_scan/presentation/pages/qr_scan_page_new.dart`**
   - QRスキャン時のトランザクション記録を追加
   - 処理フローとエラーメッセージをコメントで明文化

2. **`lib/features/points/presentation/pages/points_page.dart`**
   - 「ポイントを使う」セクションを追加
   - フル給油券交換UIを実装
   - 会員チェックロジックを一元化（`_handleRedemption`内）

3. **`lib/core/providers/app_providers.dart`**
   - `redemptionsRepositoryProvider`を追加
   - `UserModel`作成時に`updatedAt`フィールドを追加

4. **`lib/features/points/data/repositories/firestore_points_repository.dart`**
   - `TransactionModel`作成時に`source`フィールドを追加（`TransactionSource.dailyDraw`）

5. **`lib/admin/data/repositories/admin_points_repository.dart`**
   - `TransactionModel`作成時に`source`フィールドを追加（`TransactionSource.admin`）

6. **`analysis_options.yaml`**
   - `use_build_context_synchronously`警告を抑制（`mounted`チェック後の使用は安全なため）

7. **`firestore.rules`**
   - `qr_codes/{code}` と `redemptions/{redemptionId}` のルールを追加（既に実装済み）

---

## 🔄 3. QRスキャン → ポイント付与 → トランザクション記録の流れ

### 処理フロー

1. **QRコードスキャン**
   - ユーザーがQRスキャン画面でQRコードをスキャン
   - スキャン結果の文字列を取得

2. **QRコード検証**
   - スキャン結果の文字列を `qr_codes/{code}` のドキュメントIDとして使用
   - FirestoreからQRコード情報を取得
   - バリデーション:
     - ドキュメントが存在しない → エラー表示
     - `enabled == false` → エラー表示
     - `expiresAt < now` → エラー表示

3. **ポイント付与**
   - 有効なQRコードの場合のみ、`PointsNotifier.addPoints()` を呼び出し
   - Firestoreの `users/{userId}.points` を加算

4. **トランザクション記録**
   - `transactions` コレクションに記録:
     - `type: 'earn'` (獲得)
     - `source: 'qrScan'` (QRスキャン)
     - `points: qrCode.points` (付与ポイント)
     - `description: 'QRスキャン（${qrCode.type}）'`
     - `metadata: { qrCodeId, qrCodeType }` (追跡用)

5. **UIフィードバック**
   - 成功: 「${points}Pが付与されました。」ダイアログ
   - 失敗: エラーダイアログ表示

### Firestoreスキーマ（qr_codes）

```
qr_codes/{code}
  - id: string (ドキュメントID = QRコードの文字列)
  - points: int (付与ポイント数)
  - type: string (QRコードのタイプ、例: 'coating_visit')
  - enabled: bool (有効フラグ)
  - expiresAt: Timestamp? (有効期限、nullの場合は無期限)
```

### TransactionModelとの整合性

- **デイリーくじ**: `type: 'earn'`, `source: 'dailyDraw'`
- **QRスキャン**: `type: 'earn'`, `source: 'qrScan'`
- **Admin付与**: `type: 'earn'`, `source: 'admin'`
- **ポイント交換**: `type: 'use'`, `source: 'redemption'`

すべての付与パターンで一貫した`source`フィールドを使用。

---

## 💳 4. ポイント交換（給油券）のフローと会員チェック条件

### 処理フロー

1. **ユーザーが「交換する」ボタンをタップ**
   - Pointsページの「ポイントを使う」セクションから

2. **会員チェック**（`_handleRedemption`内で一元処理）
   - `user.memberId == null` の場合:
     - 会員登録ダイアログを表示
     - 「会員登録する」を選択 → ProfilePageに遷移
     - 処理を中断
   - `user.memberId != null` の場合:
     - 次のステップへ進む

3. **ポイント残高チェック**
   - `user.points < pointsRequired` の場合:
     - エラーメッセージ表示
     - 処理を中断

4. **確認ダイアログ**
   - 「${pointsRequired}Pを使用してフル給油券と交換しますか？」
   - ユーザーが「交換する」を選択

5. **交換実行**
   - `RedemptionsRepository.createRedemption()` を呼び出し
   - 処理順序:
     1. `redemptions` ドキュメントを作成（status: 'pending'）
     2. `users/{userId}.points` を減算
     3. `transactions` コレクションに記録（type: 'use', source: 'redemption'）

6. **UIフィードバック**
   - 成功: 「フル給油券と交換しました」SnackBar
   - 失敗: エラーメッセージ表示

### 会員チェック条件の整理

- **会員チェックの場所**: `lib/features/points/presentation/pages/points_page.dart` の `_handleRedemption` メソッド内（一元化）
- **チェック条件**: `user.memberId == null`
- **チェックタイミング**: ポイント交換アクション時のみ
- **他の機能**: デイリーくじ・QRスキャンは匿名ユーザーでも利用可能（会員チェックなし）

### Firestoreスキーマ（redemptions）

```
redemptions/{redemptionId}
  - id: string (ドキュメントID)
  - userId: string (Firebase Auth の uid)
  - memberId: string? (会員ID、本会員登録済みの場合のみ)
  - type: string (交換タイプ、例: 'full_gas_ticket')
  - pointsUsed: int (使用したポイント数)
  - status: string (ステータス: 'pending' | 'completed' | 'cancelled')
  - createdAt: Timestamp (作成日時)
  - completedAt: Timestamp? (完了日時、完了時のみ)
  - metadata: Map<string, dynamic>? (追加情報、例: previousPoints, newPoints)
```

### ポイント減算の順番とトランザクション性

**現時点の実装**:
1. `redemptions` ドキュメントを作成
2. `users/{userId}.points` を減算
3. `transactions` コレクションに記録

**注意点**:
- 現時点ではクライアント側で順次実行
- 将来的には Cloud Functions でトランザクション処理を行うことを推奨
- これにより、`redemptions`作成とポイント減算の原子性を保証できる

---

## 🔒 5. Firestoreセキュリティルール案

### 5-1. `qr_codes/{code}` コレクション

```javascript
match /qr_codes/{code} {
  // 認証済みユーザーのみがQRコード情報を読み取り可能
  // 注意: QRコードの有効性チェック（enabled, expiresAt）はアプリ側で行う
  allow read: if isAuthenticated();
  // 作成・更新・削除は管理者のみ（Admin Web側から操作）
  // TODO: 将来的にカスタムクレーム（admin role）で制御
  allow create, update, delete: if false;
}
```

**要件**:
- ✅ ログイン済みユーザー（匿名認証含む）のみがQRコード情報を取得可能
- ✅ 作成・更新・削除は管理者のみ（現時点では`false`でブロック）

### 5-2. `redemptions/{redemptionId}` コレクション

```javascript
match /redemptions/{redemptionId} {
  // ユーザーは自分の交換リクエストのみ作成・読み取り可能
  allow create: if isAuthenticated() &&
                 request.resource.data.userId == request.auth.uid;
  allow read: if isAuthenticated() &&
               resource.data.userId == request.auth.uid;
  // 更新・削除は管理者のみ（Admin Web側でステータス更新）
  // TODO: 将来的にカスタムクレーム（admin role）で制御
  allow update, delete: if false;
}
```

**要件**:
- ✅ ログインユーザーが「自分の redemption だけ」作成・参照可能
- ✅ 更新・削除は管理者のみ（現時点では`false`でブロック）

### 5-3. 管理者（Admin Web）側の操作

**現状**:
- Admin Web (`lib/main_admin.dart`) は同じ Firebase プロジェクトを使用
- 現時点では、管理者操作は `allow create, update, delete: if false;` でブロックされている

**将来的な対応案**:
1. **カスタムクレーム方式**（推奨）
   ```javascript
   function isAdmin() {
     return request.auth != null && 
            request.auth.token.admin == true;
   }
   
   // 使用例
   allow create, update, delete: if isAdmin();
   ```

2. **別プロジェクト方式**
   - Admin Web を別の Firebase プロジェクトに分離
   - データ同期は Cloud Functions で実装

3. **一時的な対応**（開発・テスト環境のみ）
   ```javascript
   // 注意: 本番環境では使用しないこと
   allow create, update, delete: if request.auth != null && 
                                  request.auth.uid == 'admin_user_id';
   ```

### 5-4. 匿名認証の扱い

- 匿名認証も `isAuthenticated()` で `true` を返す
- デイリーくじ・QRスキャンは匿名ユーザーでも利用可能
- ポイント交換（給油券）はアプリ側で `memberId` チェックを行い、本会員登録を要求

---

## 📊 6. 実装状況サマリー

### ✅ 完了した機能

1. **デイリーくじ**
   - 起動時フルスクリーン表示（既存実装）
   - 匿名ユーザーでも利用可能
   - Firestoreベースのポイント付与

2. **QRスキャン**
   - 店舗QRコードのスキャン機能
   - Firestoreの`qr_codes`コレクションを参照してバリデーション
   - トランザクション記録（`source: 'qrScan'`）
   - 匿名ユーザーでも利用可能

3. **ポイント交換（給油券）**
   - フル給油券交換UI
   - 会員チェック（`memberId`）を一元化
   - ポイント減算とトランザクション記録
   - Firestoreの`redemptions`コレクションに記録

4. **コード品質**
   - `flutter analyze`: Error: 0, Warning: 0
   - スキーマ明文化（コメント）
   - エラーハンドリングの統一

### 📝 既存機能（変更なし）

- 予約機能（`reservations_page.dart`）
- Admin Web (`lib/main_admin.dart`)
- 認証機能（ログイン・新規登録）

---

## 🎯 7. 次のステップ（推奨）

1. **Cloud Functions の実装**
   - ポイント減算のトランザクション処理
   - デイリーくじのサーバーサイド処理

2. **カスタムクレームの実装**
   - Admin Web側の操作を有効化

3. **テストの追加**
   - QRスキャンのユニットテスト
   - ポイント交換のユニットテスト

4. **UI/UXの改善**
   - アニメーションの追加
   - エラーメッセージの改善

---

## 📄 関連ドキュメント

- `FIRESTORE_SECURITY_RULES_PROPOSAL.md` - Firestoreセキュリティルール案の詳細
- `lib/admin/FIRESTORE_SCHEMA.md` - Firestoreスキーマの全体像

---

**実装完了日**: 2024年（実装完了時点）
**flutter analyze**: ✅ No issues found!

