# Cloud Functions デプロイガイド - Epic 2 Minimal

## 概要

Epic 2最小実装のためのCloud Functions（claimDailyGacha）デプロイ手順

## 前提条件

- Node.js 20以上
- Firebase CLI がインストールされている
- Firebase プロジェクトが作成されている
- asia-northeast1 リージョンを使用

## デプロイ手順

### 1. Functions ディレクトリへ移動

```bash
cd functions
```

### 2. 依存関係インストール

```bash
npm install
```

### 3. claimDailyGacha 実装確認

`functions/src/index.ts` に以下の実装があることを確認:

```typescript
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

const region = "asia-northeast1";

// JST基準でdayId生成
function getCurrentDayIdJST(): string {
  const now = new Date();
  const jstOffset = 9 * 60; // JST = UTC+9
  const jstDate = new Date(now.getTime() + jstOffset * 60 * 1000);
  return jstDate.toISOString().slice(0, 10).replace(/-/g, '');
}

// 次の日までの秒数を計算（JST基準）
function getSecondsUntilNextDayJST(): number {
  const now = new Date();
  const jstOffset = 9 * 60;
  const jstDate = new Date(now.getTime() + jstOffset * 60 * 1000);
  const tomorrow = new Date(jstDate);
  tomorrow.setUTCDate(tomorrow.getUTCDate() + 1);
  tomorrow.setUTCHours(0, 0, 0, 0);
  return Math.floor((tomorrow.getTime() - jstDate.getTime()) / 1000);
}

export const claimDailyGacha = functions
  .region(region)
  .https.onCall(async (data, context) => {
    const uid = context.auth?.uid;
    if (!uid) {
      throw new functions.https.HttpsError('unauthenticated', 'Login required.');
    }

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

      if (!userSnap.exists) {
        throw new functions.https.HttpsError('not-found', 'User not found.');
      }

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
```

### 4. デプロイ実行

```bash
npm run deploy
```

または

```bash
firebase deploy --only functions
```

### 5. デプロイ確認

```bash
# デプロイされたFunctionsを確認
firebase functions:list

# 期待される出力:
# ✔ functions: claimDailyGacha(asia-northeast1)
```

### 6. Firestore ルールのデプロイ

```bash
cd ..
firebase deploy --only firestore:rules
```

## テスト

### ローカルエミュレーターでテスト

```bash
# Firestore エミュレーター起動
firebase emulators:start --only functions,firestore

# 別のターミナルで
curl -X POST http://localhost:5001/<project-id>/asia-northeast1/claimDailyGacha \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <test-token>" \
  -d '{}'
```

### 本番環境でテスト

1. iOS実機でアプリを起動
2. ポイントタブへ移動
3. デイリーガチャボタンをタップ
4. 成功メッセージを確認

## トラブルシューティング

### エラー: Permission denied

**原因**: Firestore ルールがデプロイされていない

**解決策**:
```bash
firebase deploy --only firestore:rules
```

### エラー: Function not found

**原因**: Functionsがデプロイされていない、またはリージョンが異なる

**解決策**:
```bash
# Functionsを再デプロイ
npm run deploy

# Flutterコードでリージョンが一致しているか確認
# FirebaseFunctions.instanceFor(region: 'asia-northeast1')
```

### エラー: User not found

**原因**: users ドキュメントが存在しない

**解決策**:
- Epic 1の onUserCreate トリガーがデプロイされているか確認
- または、手動で users/{uid} ドキュメントを作成:
  ```javascript
  {
    uid: "{uid}",
    totalPoints: 0,
    totalGachaPlays: 0,
    totalBookings: 0,
    isAnonymous: true,
    authProviders: ["anonymous"],
    emailVerified: false,
    notificationEnabled: true,
    locale: "ja-JP",
    createdAt: (serverTimestamp),
    updatedAt: (serverTimestamp),
    lastLoginAt: (serverTimestamp)
  }
  ```

## ロールバック

問題が発生した場合、以前のバージョンにロールバック:

```bash
# デプロイ履歴を確認
firebase functions:log

# 特定のバージョンにロールバック（Firebase Console経由）
# Firebase Console → Functions → claimDailyGacha → バージョン履歴
```

## モニタリング

### ログ確認

```bash
# リアルタイムログ
firebase functions:log --only claimDailyGacha

# 特定期間のログ
firebase functions:log --only claimDailyGacha --limit 100
```

### Firebase Console

1. Firebase Console → Functions
2. claimDailyGacha を選択
3. ログ、メトリクス、エラー率を確認

## セキュリティ

- ✅ asia-northeast1 リージョン使用
- ✅ 認証必須（context.auth.uid チェック）
- ✅ Idempotency 保証（dayId による重複チェック）
- ✅ Transaction 使用（整合性保証）
- ✅ JST基準のdayId（タイムゾーン一貫性）

## パフォーマンス

- **実行時間**: 通常 < 500ms
- **コールドスタート**: 約 1-2秒
- **同時実行数**: デフォルト 1000（必要に応じて増加可）
- **タイムアウト**: 60秒（デフォルト）

## コスト見積もり

- **無料枠**: 月間 200万回の呼び出し
- **Epic 2 Minimal**: 1日1回/ユーザー
- **想定ユーザー数**: 1000人
- **月間呼び出し数**: 約 30,000回 << 無料枠内

## 次のステップ

- Epic 2 完全版: 確率分布実装（60%/30%/8%/2%）
- ポイント有効期限管理（1年）
- 月次集計バッチ（Cloud Scheduler）
- GA4イベント連携
- Sentry連携（エラー監視）
