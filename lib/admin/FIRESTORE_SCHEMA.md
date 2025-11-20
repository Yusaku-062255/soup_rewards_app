# Firestoreスキーマ設計（SOUP Admin用）

## 📋 概要

SOUP Admin管理画面で使用するFirestoreスキーマの設計書です。

## 🔄 データフロー図

### モバイル側（日次くじ）

```
1. User opens Points tab
   ↓
2. Daily draw → FirestorePointsRepository.drawToday(userId, shopId)
   ↓
3. Firestore更新（順次実行）:
   - users/{userId}.points += N
   - users/{userId}.lastDailyDrawAt = now
   - users/{userId}.todayDrawPoints = N
   - transactions に1件追加
     * type: earn
     * description: "日次くじ"
     * points: N
     * timestamp: now
```

### Admin側（ポイント付与）

```
1. Staff searches member → selects service menu
   ↓
2. AdminPointsRepository.grantPoints(userId, points, description, shopId)
   ↓
3. Firestore更新（トランザクション内で原子的に実行）:
   - users/{userId}.points += M
   - users/{userId}.lastVisitDate = now
   - users/{userId}.visitCount += 1
   - users/{userId}.updatedAt = now
   - transactions に1件追加
     * type: earn
     * description: サービス名（例: "洗車ライト"）
     * points: M
     * timestamp: now
```

### 共通事項

- 両方とも `TransactionModel` を使用
- `TransactionType.earn` でポイント獲得を記録
- `transactions` コレクションに履歴を保存
- `users/{userId}.points` を更新

## 🔥 既存コレクション

### `users/{userId}`

既存のユーザー情報を管理するコレクション。

**現在のフィールド:**
```typescript
{
  shopId: string;
  points: number;
  lastDailyDrawAt: Timestamp?;
  todayDrawPoints: number?;
  name: string;
  email: string;
  phoneNumber?: string;
  membershipLevel: string;  // 'bronze' | 'silver' | 'gold'
  createdAt: Timestamp;
  updatedAt?: Timestamp;
}
```

**追加が必要なフィールド（管理画面用）:**
```typescript
{
  // 既存フィールド...
  
  // 管理画面用（ポイント付与時に更新）
  lastVisitDate?: Timestamp;  // 最終来店日（最後にポイント付与した日時）
  visitCount?: number;        // 累計来店回数（ポイント付与時に +1）
  memberId?: string;         // 6桁の会員ID（検索用インデックス）
  
  // 将来の拡張
  carInfo?: {
    make?: string;      // メーカー
    model?: string;     // モデル
    year?: number;      // 年式
    plateNumber?: string; // ナンバープレート（個人情報のため慎重に）
  };
}
```

**フィールドの更新タイミング:**

- `lastVisitDate`: ポイント付与時（`AdminPointsRepository.grantPoints()`）に更新
- `visitCount`: ポイント付与時（`AdminPointsRepository.grantPoints()`）に +1
- `memberId`: ユーザー作成時または手動で設定（検索用）

**インデックス:**
- `memberId` フィールドに単一フィールドインデックスを作成（検索用）
  ```json
  {
    "collectionGroup": "users",
    "queryScope": "COLLECTION",
    "fields": [
      { "fieldPath": "memberId", "order": "ASCENDING" }
    ]
  }
  ```

---

### `transactions/{transactionId}`

取引履歴を管理するコレクション。

**現在のフィールド:**
```typescript
{
  userId: string;
  type: 'earn' | 'redeem';
  points: number;
  description: string;
  storeId?: string;
  timestamp: Timestamp;
}
```

**インデックス:**
- `userId` + `timestamp` の複合インデックス（既存）
- `userId` + `type` + `timestamp` の複合インデックス（将来の拡張用）

---

## 🆕 新規コレクション

### `reservations/{reservationId}`

予約情報を管理するコレクション。

**フィールド:**
```typescript
{
  userId?: string;              // 会員ID（オプション、ゲスト予約の場合はnull）
  name: string;                 // 予約者名
  phoneNumber?: string;          // 電話番号
  email?: string;                // メールアドレス
  menu: string;                 // メニュー名
  status: '予約' | '施工中' | '完了' | 'キャンセル';
  scheduledDate: Timestamp;      // 予約日時
  estimatedDuration?: number;     // 予想施工時間（分）
  notes?: string;                // 備考
  createdAt: Timestamp;
  updatedAt?: Timestamp;
  completedAt?: Timestamp;       // 完了日時
}
```

**インデックス:**
- `scheduledDate` フィールドに単一フィールドインデックスを作成
  ```json
  {
    "collectionGroup": "reservations",
    "queryScope": "COLLECTION",
    "fields": [
      { "fieldPath": "scheduledDate", "order": "ASCENDING" }
    ]
  }
  ```
- `status` + `scheduledDate` の複合インデックスを作成（ステータスフィルター用）
  ```json
  {
    "collectionGroup": "reservations",
    "queryScope": "COLLECTION",
    "fields": [
      { "fieldPath": "status", "order": "ASCENDING" },
      { "fieldPath": "scheduledDate", "order": "ASCENDING" }
    ]
  }
  ```
- `userId` + `scheduledDate` の複合インデックスを作成（会員予約の場合）
  ```json
  {
    "collectionGroup": "reservations",
    "queryScope": "COLLECTION",
    "fields": [
      { "fieldPath": "userId", "order": "ASCENDING" },
      { "fieldPath": "scheduledDate", "order": "ASCENDING" }
    ]
  }
  ```

---

## 🔍 検索クエリの最適化

### 会員ID検索

**実装:**
- `users`コレクションの`memberId`フィールドで検索
- インデックスが必要（上記参照）

**クエリ例:**
```dart
_firestore
  .collection('users')
  .where('memberId', isEqualTo: memberId)
  .limit(1)
  .get();
```

### 名前検索

**現状:**
- 全ユーザーを取得してクライアント側でフィルタリング（非効率）

**改善案:**
- **短期的:** 現状維持（全件取得してフィルタリング）
- **長期的:** Algoliaなどの全文検索サービスを導入

### 電話番号検索

**実装:**
- `phoneNumber`フィールドで完全一致検索（実装済み）

**改善案:**
- 電話番号の正規化（ハイフン除去など）を実装

---

## 🔐 セキュリティルール（将来実装）

### 管理画面用ルール

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // ユーザー情報（管理者のみ読み書き可能）
    match /users/{userId} {
      allow read, write: if request.auth != null && 
        request.auth.token.admin == true;
    }
    
    // 取引履歴（管理者のみ作成可能、ユーザーは自分の履歴のみ読み取り可能）
    match /transactions/{transactionId} {
      allow create: if request.auth != null && 
        request.auth.token.admin == true;
      allow read: if request.auth != null && (
        request.auth.token.admin == true ||
        request.auth.uid == resource.data.userId
      );
    }
    
    // 予約情報（管理者は全件読み書き可能、ユーザーは自分の予約のみ読み取り可能）
    match /reservations/{reservationId} {
      allow read, write: if request.auth != null && 
        request.auth.token.admin == true;
      allow read: if request.auth != null && 
        request.auth.uid == resource.data.userId;
    }
  }
}
```

---

## 📊 データ移行手順（将来）

### `memberId`フィールドの追加

1. Cloud Functionsでバッチ処理を実行:
   ```javascript
   // usersコレクションの全ドキュメントを取得
   // userIdの末尾6桁をmemberIdとして設定
   ```

2. インデックスを作成:
   ```bash
   firebase deploy --only firestore:indexes
   ```

### `lastVisitDate` / `visitCount`フィールドの追加

1. 既存の`transactions`コレクションから最新の取引日時を取得
2. `users`コレクションの`lastVisitDate`フィールドを更新
3. `transactions`コレクションの件数をカウントして`visitCount`を設定

---

## 🚨 注意事項

1. **個人情報の取り扱い**
   - 電話番号、メールアドレスなどの個人情報は適切に保護する
   - セキュリティルールでアクセス制御を実装する

2. **パフォーマンス**
   - 大量のデータがある場合、検索クエリの最適化が必要
   - インデックスの作成を忘れずに

3. **データ整合性**
   - ポイント付与と取引履歴の追加はトランザクションで実行する
   - エラー時のロールバック処理を実装する

4. **既存アプリへの影響**
   - `lastVisitDate` / `visitCount`フィールドは管理画面専用
   - モバイルアプリ側の`FirestorePointsRepository`には影響しない

---

## 📝 TODO

- [x] `memberId`フィールドの追加とインデックス作成（設計完了）
- [x] `lastVisitDate` / `visitCount`フィールドの追加（設計完了）
- [x] `reservations`コレクションの作成（設計完了）
- [x] 日次くじとポイント付与の両立ロジック整合性確認（完了）
- [x] データフロー図の追加（完了）
- [ ] セキュリティルールの実装
- [ ] データ移行スクリプトの作成
- [ ] インデックスのデプロイ
- [ ] 日次くじのトランザクション処理（現状は順次実行、将来的にCloud Functionsで実装）
