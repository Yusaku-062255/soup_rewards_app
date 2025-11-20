# Firestore セキュリティルール案

## 概要

SOUP Rewards アプリで使用する Firestore コレクション向けのセキュリティルール案です。
現在の `firestore.rules` に追加・修正が必要な部分をまとめています。

---

## 1. `qr_codes/{code}` コレクション

### 現在のルール（firestore.rules 82-91行目）

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

### 推奨事項

- ✅ **現在のルールで問題なし**
- 認証済みユーザー（匿名認証含む）のみがQRコード情報を読み取れる
- 作成・更新・削除は管理者のみ（現時点では `false` でブロック、将来的にカスタムクレームで制御）

### スキーマ

```
qr_codes/{code}
  - id: string (ドキュメントID = QRコードの文字列)
  - points: int (付与ポイント数)
  - type: string (QRコードのタイプ、例: 'coating_visit')
  - enabled: bool (有効フラグ、falseの場合は無効)
  - expiresAt: Timestamp? (有効期限、nullの場合は無期限)
```

---

## 2. `redemptions/{redemptionId}` コレクション

### 現在のルール（firestore.rules 93-104行目）

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

### 推奨事項

- ✅ **現在のルールで問題なし**
- ログインユーザー（匿名認証含む）が自分の `redemption` のみ作成・参照可能
- 更新・削除は管理者のみ（現時点では `false` でブロック、将来的にカスタムクレームで制御）

### スキーマ

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

---

## 3. 管理者（Admin Web）側の操作について

### 現状

- Admin Web (`lib/main_admin.dart`) は同じ Firebase プロジェクトを使用
- 現時点では、管理者操作は `allow create, update, delete: if false;` でブロックされている

### 将来的な対応案

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

---

## 4. 匿名認証の扱い

### 現状

- 匿名認証も `isAuthenticated()` で `true` を返す
- デイリーくじ・QRスキャンは匿名ユーザーでも利用可能
- ポイント交換（給油券）は `memberId` チェックで制御

### セキュリティルールでの制御

- ✅ **現在のルールで問題なし**
- 匿名認証ユーザーも `request.auth != null` で認証済みとして扱われる
- アプリ側で `memberId` チェックを行い、ポイント交換時のみ本会員登録を要求

---

## 5. 実装済みのルール

以下のコレクションは既に `firestore.rules` に実装済みです：

- ✅ `users/{userId}` - ユーザー情報
- ✅ `transactions/{transactionId}` - 取引履歴
- ✅ `coupons/{couponId}` - クーポン情報
- ✅ `userCoupons/{userCouponId}` - ユーザーが獲得したクーポン
- ✅ `stores/{storeId}` - 店舗情報
- ✅ `news/{newsId}` - ニュース
- ✅ `reservations/{reservationId}` - 予約情報
- ✅ `qr_codes/{code}` - QRコード情報（上記1を参照）
- ✅ `redemptions/{redemptionId}` - 交換リクエスト（上記2を参照）

---

## 6. デプロイ方法

```bash
# Firestore セキュリティルールをデプロイ
firebase deploy --only firestore:rules
```

---

## 7. テスト方法

Firebase Console の「Firestore Database」→「ルール」タブで、ルールシミュレーターを使用してテストできます。

### テストケース例

1. **QRコード読み取り**
   - 認証済みユーザー: ✅ 成功
   - 未認証ユーザー: ❌ 失敗

2. **交換リクエスト作成**
   - 自分の `userId` で作成: ✅ 成功
   - 他人の `userId` で作成: ❌ 失敗

3. **交換リクエスト読み取り**
   - 自分の `redemption`: ✅ 成功
   - 他人の `redemption`: ❌ 失敗

---

## まとめ

- ✅ `qr_codes` と `redemptions` のルールは既に実装済み
- ✅ 匿名認証ユーザーも適切に扱われる
- ✅ 管理者操作は将来的にカスタムクレームで制御予定
- ✅ 現在のルールで本番環境にデプロイ可能

