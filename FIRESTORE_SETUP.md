# 🔥 Firestore セットアップ & デプロイ手順

**SOUP Rewards App** のFirestore Database設定とセキュリティルールのデプロイ手順です。

## 📋 前提条件

- Firebase プロジェクト作成済み
- Firebase CLI インストール済み

---

## 🚀 セットアップ手順

### Step 1: Firebase CLI インストール

```bash
# Node.jsがインストール済みの場合
npm install -g firebase-tools

# ログイン
firebase login

# プロジェクトリンク確認
firebase projects:list
```

---

### Step 2: Firebase プロジェクト初期化

```bash
# プロジェクトルートで実行
cd /path/to/soup_rewards_app

# Firebaseプロジェクト初期化
firebase init

# 選択項目:
# ✓ Firestore (Rules and indexes)
# ✓ 既存のプロジェクトを選択: soup-rewards-app
# ✓ Firestore rules file: firestore.rules
# ✓ Firestore indexes file: firestore.indexes.json
```

---

### Step 3: Firestore Database 作成

#### Firebase Consoleから作成

1. [Firebase Console](https://console.firebase.google.com/) にアクセス
2. プロジェクト選択: `soup-rewards-app`
3. **Firestore Database** → **データベースの作成**
4. **本番環境モード** で開始
5. ロケーション選択: `asia-northeast1` (東京) 推奨
6. 「有効にする」をクリック

---

### Step 4: セキュリティルールのデプロイ

```bash
# ルールのみデプロイ
firebase deploy --only firestore:rules

# インデックスも含めてデプロイ
firebase deploy --only firestore
```

**成功メッセージ**:
```
✔  Deploy complete!

Project Console: https://console.firebase.google.com/project/soup-rewards-app/overview
```

---

### Step 5: ルールの動作確認

#### Firebase Console で確認

1. Firestore Database → **ルール** タブ
2. デプロイされたルールが表示される
3. **公開日時** が最新になっていることを確認

#### ルールシミュレーター

1. **ルール** タブ → **シミュレーター**
2. テストケース:

**テスト1: 未認証ユーザーがニュースを読む**
```
Location: /databases/(default)/documents/news/news123
Simulation type: get
Auth: 未認証
→ 結果: ✅ Allow（全員読み取り可）
```

**テスト2: ユーザーが他人のプロファイルを読む**
```
Location: /databases/(default)/documents/users/user456
Simulation type: get
Auth: 認証済み (uid: user123)
→ 結果: ❌ Deny（本人のみ）
```

**テスト3: ユーザーが自分のポイント履歴を書き込む**
```
Location: /databases/(default)/documents/users/user123/points/point1
Simulation type: create
Auth: 認証済み (uid: user123)
→ 結果: ❌ Deny（Cloud Functionsのみ）
```

---

### Step 6: 管理者権限設定（オプション）

管理者ユーザーにカスタムクレームを付与：

```bash
# Firebase Admin SDK（Node.js）で実行
const admin = require('firebase-admin');
admin.initializeApp();

// 管理者権限を付与
await admin.auth().setCustomUserClaims('ADMIN_USER_UID', { admin: true });
```

または、Firebase Functions で実装：

```typescript
// functions/src/admin.ts
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export const makeAdmin = functions.https.onCall(async (data, context) => {
  // 既存の管理者のみ実行可能
  if (!context.auth?.token.admin) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Only admins can create new admins'
    );
  }

  await admin.auth().setCustomUserClaims(data.uid, { admin: true });
  return { message: 'Admin privileges granted' };
});
```

---

## 📊 データモデル設計

### ユーザープロファイル (`/users/{userId}`)

```json
{
  "uid": "user123",
  "email": "user@example.com",
  "displayName": "山田太郎",
  "phoneNumber": "+81-90-1234-5678",
  "profileImageUrl": "https://...",
  "points": 1500,
  "memberTier": "gold",
  "createdAt": "2024-01-01T00:00:00Z",
  "updatedAt": "2024-10-30T12:00:00Z"
}
```

### ポイント履歴 (`/users/{userId}/points/{pointId}`)

```json
{
  "pointId": "point_abc123",
  "userId": "user123",
  "amount": 100,
  "type": "earn",
  "reason": "QRスキャン",
  "transactionId": "trans_xyz789",
  "storeId": "store_tokushima",
  "createdAt": "2024-10-30T10:00:00Z"
}
```

### クーポン (`/coupons/{couponId}`)

```json
{
  "couponId": "coupon_wash20",
  "title": "洗車サービス20%OFF",
  "description": "次回洗車サービスが20%割引",
  "discountRate": 20,
  "discountType": "percentage",
  "minPoints": 0,
  "expiryDate": "2024-12-31T23:59:59Z",
  "isActive": true,
  "termsUrl": "https://soup.jp/terms/coupon_wash20"
}
```

### ニュース (`/news/{newsId}`)

```json
{
  "newsId": "news_20241030",
  "title": "新サービス開始のお知らせ",
  "content": "プレミアムコーティングサービスを開始しました...",
  "imageUrl": "https://...",
  "publishDate": "2024-10-30T09:00:00Z",
  "category": "service",
  "isPinned": false
}
```

---

## 🔐 セキュリティベストプラクティス

### 1. 最小権限の原則

- ✅ 読み取り/書き込みを必要最小限に制限
- ✅ Cloud Functionsで重要な処理を実行
- ❌ クライアント側でポイント加算は禁止

### 2. データ検証

```javascript
// ルール内でデータ検証
allow create: if incomingData().keys().hasAll(['email', 'createdAt']) &&
               incomingData().email is string &&
               incomingData().email.size() > 0;
```

### 3. タイムスタンプ検証

```javascript
// サーバータイムスタンプ強制
allow create: if incomingData().createdAt == request.time;
```

### 4. フィールド変更制限

```javascript
// 特定フィールドの変更を禁止
allow update: if !incomingData().diff(existingData())
                  .affectedKeys()
                  .hasAny(['uid', 'createdAt', 'points']);
```

---

## 🧪 テストケース

### Flutter側でのテスト

```dart
// test/firestore_rules_test.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Firestore Rules Tests', () {
    test('Authenticated user can read own profile', () async {
      final user = FirebaseAuth.instance.currentUser!;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      expect(doc.exists, true);
    });

    test('User cannot read other user profile', () async {
      expect(
        () => FirebaseFirestore.instance
            .collection('users')
            .doc('other_user_id')
            .get(),
        throwsA(isA<FirebaseException>()),
      );
    });

    test('User cannot write to points subcollection', () async {
      final user = FirebaseAuth.instance.currentUser!;
      expect(
        () => FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('points')
            .add({'amount': 100}),
        throwsA(isA<FirebaseException>()),
      );
    });
  });
}
```

---

## 📚 参考リンク

- [Firestore セキュリティルール](https://firebase.google.com/docs/firestore/security/get-started)
- [ルールシミュレーター](https://firebase.google.com/docs/firestore/security/test-rules-emulator)
- [Firebase CLI](https://firebase.google.com/docs/cli)

---

**次のステップ**: go_router実装（Deep Link対応）
