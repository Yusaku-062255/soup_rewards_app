# M7: ポイント失効 & 月次集計

## 📋 概要

ポイントの自動失効機能と月次統計計算機能を実装しました。付与から1年経過したポイントは自動的に失効し、UIには失効予定のポイントが表示されます。

## ✨ 実装内容

### 1. Cloud Functions: ポイント失効処理

**ファイル**: `functions/src/points_expire.ts`

#### expirePointsScheduled（Scheduled Function）

```typescript
// スケジュール: 毎日 JST 03:00（UTC 18:00）
export const expirePointsScheduled = functions
  .region("asia-northeast1")
  .pubsub.schedule("0 18 * * *")
  .timeZone("UTC")
  .onRun(async (_context) => {
    // 実装内容:
    // 1. expiresAt <= now の pointLedger エントリを検索
    // 2. 失効対象があるユーザーに対してトランザクション実行:
    //    - users.totalPoints から減算
    //    - pointLedger に type: "expire" エントリを追加
    //    - expiredProcessed フラグを設定
    // 3. バッチサイズ: 500エントリ/実行
  });
```

**主要機能**:
- JST 基準での失効判定
- トランザクションによる整合性保証
- バッチ処理による大量データ対応
- 再処理防止のための expiredProcessed フラグ

#### expirePointsDev（Callable Function）

```typescript
// 開発用: 特定ユーザーの失効処理を手動実行
export const expirePointsDev = functions
  .region("asia-northeast1")
  .https.onCall(async (data, context) => {
    const uid = data.uid || context.auth?.uid;
    const result = await expirePointsForUser(uid);
    return { ok: true, uid, expired: result.expired, entries: result.entries };
  });
```

### 2. Cloud Functions: 月次統計計算

**ファイル**: `functions/src/points_stats.ts`

#### calculateMonthlyStatsScheduled（Scheduled Function）

```typescript
// スケジュール: 毎月1日 JST 03:00（UTC 18:00）
export const calculateMonthlyStatsScheduled = functions
  .region("asia-northeast1")
  .pubsub.schedule("0 18 1 * *")
  .timeZone("UTC")
  .onRun(async (_context) => {
    // 実装内容:
    // 1. 前月の YYYYMM を計算（JST基準）
    // 2. 全ユーザーに対して:
    //    - 前月の pointLedger を集計
    //    - granted/spent/expired/net を計算
    //    - users/{uid}/stats/{YYYYMM} に保存
    // 3. バッチサイズ: 100ユーザー/実行
  });
```

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

#### calculateMonthlyStatsDev（Callable Function）

```typescript
// 開発用: 特定ユーザーの統計を手動計算
export const calculateMonthlyStatsDev = functions
  .region("asia-northeast1")
  .https.onCall(async (data, context) => {
    const uid = data.uid || context.auth?.uid;
    const month = data.month || lastMonthYYYYMM();
    const stats = await calculateStatsForUser(uid, month);
    return { ok: true, uid, month, stats };
  });
```

### 3. Firestore Rules: stats コレクション

**ファイル**: `firestore.rules`

```javascript
// stats（月次統計、Cloud Functionsのみが書込可能）
match /users/{userId}/stats/{yyyymm} {
  allow read: if isOwner(userId) || isAdmin();
  allow write: if false; // Cloud Functionsのみ
}
```

### 4. Flutter: PointEntry モデル更新

**ファイル**: `lib/features/points/points_repository.dart`

```dart
class PointEntry {
  final String id;
  final String type;
  final int delta;
  final int balance;
  final String note;
  final DateTime createdAt;
  final DateTime? expiresAt;  // 新規追加

  PointEntry({
    required this.id,
    required this.type,
    required this.delta,
    required this.balance,
    required this.note,
    required this.createdAt,
    this.expiresAt,  // オプショナル
  });
}
```

### 5. Flutter: 失効予定ポイント取得

**ファイル**: `lib/features/points/points_repository.dart`

```dart
/// Get points expiring within the next 30 days
Future<({int totalPoints, DateTime? earliestExpiry})> getExpiringPoints(
    String userId) async {
  final now = DateTime.now();
  final thirtyDaysLater = now.add(const Duration(days: 30));

  final snapshot = await firestore
      .collection('users')
      .doc(userId)
      .collection('pointLedger')
      .where('expiresAt',
          isGreaterThan: Timestamp.fromDate(now),
          isLessThanOrEqualTo: Timestamp.fromDate(thirtyDaysLater))
      .where('delta', isGreaterThan: 0)
      .orderBy('expiresAt', descending: false)
      .get();

  // 合計ポイントと最も早い失効日を返す
  return (totalPoints: totalPoints, earliestExpiry: earliestExpiry);
}
```

### 6. Flutter: UI に失効予定インジケータ追加

**ファイル**: `lib/features/points/points_screen.dart`

```dart
// Expiring points indicator
FutureBuilder<({int totalPoints, DateTime? earliestExpiry})>(
  future: pointsRepo.getExpiringPoints(user.uid),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return const SizedBox.shrink();

    final data = snapshot.data!;
    if (data.totalPoints == 0 || data.earliestExpiry == null) {
      return const SizedBox.shrink();
    }

    final daysUntilExpiry = data.earliestExpiry!.difference(DateTime.now()).inDays;

    return SoupCard(
      backgroundColor: DesignTokens.warning.withOpacity(0.1),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_triangle,
            color: DesignTokens.warning,
            size: 24,
          ),
          const SizedBox(width: DesignTokens.spaceSmall),
          Expanded(
            child: Text(
              '${daysUntilExpiry}日後に ${data.totalPoints}pt 失効予定',
              style: const TextStyle(
                fontSize: DesignTokens.fontSizeBody,
                color: DesignTokens.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  },
),
```

**表示条件**:
- 30日以内に失効予定のポイントがある場合のみ表示
- 失効予定ポイントが0の場合は非表示

### 7. Cloud Functions: addPointsInTransaction 更新

**ファイル**: `functions/src/index.ts`

既存の `addPointsInTransaction` 関数を M5 + M7 に対応:

```typescript
async function addPointsInTransaction(
  tx: admin.firestore.Transaction,
  uid: string,
  type: "gacha" | "booking" | "manual" | "expire",
  delta: number,
  note: string,
  expiresAt?: admin.firestore.Timestamp
): Promise<void> {
  // M5: users.totalPoints を使用（points/total から移行）
  // M7: expiresAt フィールドを追加（ポイント付与時に1年後を自動設定）
  // M7: expiredProcessed フラグを追加（再処理防止）
}
```

**変更点**:
- ✅ users.totalPoints フィールドを使用（M5互換）
- ✅ balance フィールドを pointLedger に記録（M5互換）
- ✅ expiresAt パラメータを追加（M7新規）
- ✅ delta > 0 の場合、1年後に自動失効するよう expiresAt を設定
- ✅ expiredProcessed フラグを初期値 false で追加

### 8. README: Cloud Scheduler ドキュメント追加

**ファイル**: `README.md`

以下のセクションを追加:
- Cloud Scheduler 設定手順（gcloud コマンド付き）
- スケジュール詳細（Cron式、タイムゾーン、実行内容）
- UTC/JST 時刻換算表
- 手動デバッグ手順（callable 関数の使い方）
- トラブルシューティング（Q&A形式）

---

## 🧪 テスト手順

### 正常系

#### シナリオ1: 失効予定インジケータの表示確認

1. **前提条件**: 30日以内に失効予定のポイントがある
2. **手順**:
   - ポイントタブへ移動
   - 「今月の獲得」カードの下に失効予定インジケータが表示される
3. **期待結果**:
   - ✅ `⚠️ ◯日後に △pt 失効予定` と表示される
   - ✅ 警告色の背景で表示される

#### シナリオ2: 失効予定インジケータの非表示確認

1. **前提条件**: 失効予定ポイントが0、または30日より先
2. **手順**:
   - ポイントタブへ移動
3. **期待結果**:
   - ✅ 失効予定インジケータが表示されない

#### シナリオ3: expirePointsDev による手動失効処理

1. **前提条件**: テストユーザーに失効対象のポイントがある
2. **手順**:
   ```dart
   final functions = FirebaseFunctions.instanceFor(region: 'asia-northeast1');
   final result = await functions.httpsCallable('expirePointsDev').call({
     'uid': 'test-user-123',
   });
   print(result.data);
   ```
3. **期待結果**:
   - ✅ `{ ok: true, uid: 'test-user-123', expired: 120, entries: 3 }` が返る
   - ✅ users/{uid}.totalPoints が減算される
   - ✅ pointLedger に type: "expire" のエントリが追加される
   - ✅ 失効済みエントリに expiredProcessed: true が設定される

#### シナリオ4: calculateMonthlyStatsDev による手動統計計算

1. **前提条件**: テストユーザーに前月のポイント履歴がある
2. **手順**:
   ```dart
   final functions = FirebaseFunctions.instanceFor(region: 'asia-northeast1');
   final result = await functions.httpsCallable('calculateMonthlyStatsDev').call({
     'uid': 'test-user-123',
     'month': '202501',
   });
   print(result.data);
   ```
3. **期待結果**:
   - ✅ `{ ok: true, uid: '...', month: '202501', stats: {...} }` が返る
   - ✅ users/{uid}/stats/202501 ドキュメントが作成される
   - ✅ granted/spent/expired/net/closingBalance が正しく計算される

### 異常系

#### シナリオ5: stats コレクションへの直接書込み拒否

1. **手順**:
   ```dart
   await FirebaseFirestore.instance
       .collection('users')
       .doc(userId)
       .collection('stats')
       .doc('202501')
       .set({
         'month': '202501',
         'granted': 9999,
       });
   ```
2. **期待結果**:
   - ✅ `Missing or insufficient permissions` エラーが発生する

#### シナリオ6: Scheduled Function のタイムアウト処理

1. **前提条件**: 大量のユーザー（1000+）が存在する
2. **期待結果**:
   - ✅ タイムアウト（540秒）内に処理が完了する
   - ✅ バッチサイズ制限により、複数回の実行に分散される

### Firestore Console 確認

#### 確認1: pointLedger の expiresAt フィールド

1. Firebase Console → Firestore Database を開く
2. users/{uid}/pointLedger を展開
3. 最新のガチャエントリーを確認

**期待結果**:
- ✅ `expiresAt: Timestamp`（1年後の日時）
- ✅ `expiredProcessed: false`

#### 確認2: stats コレクション

1. Firebase Console → Firestore Database を開く
2. users/{uid}/stats/{YYYYMM} を確認

**期待結果**:
- ✅ `month: "202501"`
- ✅ `granted: 150`
- ✅ `spent: 50`
- ✅ `expired: 10`
- ✅ `net: 90`
- ✅ `closingBalance: 340`
- ✅ `createdAt: Timestamp`

#### 確認3: 失効処理後の pointLedger

1. expirePointsDev 実行後、pointLedger を確認
2. 最新エントリーを確認

**期待結果**:
- ✅ `type: "expire"`
- ✅ `delta: -120`（負の値）
- ✅ `balance: 220`（減算後の残高）
- ✅ `note: "ポイント失効（3件）"`

---

## 🎯 受入基準（DoD）

### 機能要件

- ✅ expirePointsScheduled が毎日 JST 03:00 に実行される設定
- ✅ calculateMonthlyStatsScheduled が毎月1日 JST 03:00 に実行される設定
- ✅ expirePointsDev で手動失効処理が正常に動作する
- ✅ calculateMonthlyStatsDev で手動統計計算が正常に動作する
- ✅ UI に失効予定インジケータが表示される（30日以内のみ）
- ✅ 失効予定ポイントが0の場合、インジケータが非表示

### セキュリティ要件

- ✅ stats コレクションの直接書込みが拒否される
- ✅ users.totalPoints の直接更新が拒否される（M5で実装済み）
- ✅ pointLedger の直接書込みが拒否される（M5で実装済み）

### データ整合性

- ✅ 失効処理で users.totalPoints と pointLedger が整合する
- ✅ 失効処理で balance フィールドが正しく計算される
- ✅ expiredProcessed フラグで再処理が防止される
- ✅ 統計計算で granted/spent/expired の合計が一致する

### ドキュメント

- ✅ README に Cloud Scheduler 設定手順が記載されている
- ✅ UTC/JST 時刻換算表が記載されている
- ✅ 手動デバッグ手順が記載されている
- ✅ トラブルシューティングが記載されている

### CI/CD

- ✅ CI（analyze/test/ios no-codesign）が Green
- ✅ TypeScript のコンパイルエラーがない
- ✅ Flutter の既存テストが全て PASS

---

## 📝 Cloud Scheduler 設定コマンド

### 前提条件

```bash
# Cloud Scheduler API を有効化
gcloud services enable cloudscheduler.googleapis.com
```

### ポイント失効処理

```bash
gcloud scheduler jobs create pubsub expire-points-daily \
  --location=asia-northeast1 \
  --schedule="0 18 * * *" \
  --time-zone="UTC" \
  --topic="firebase-schedule-expirePointsScheduled-asia-northeast1" \
  --message-body="{}" \
  --description="Daily point expiration at JST 03:00"
```

### 月次統計計算

```bash
gcloud scheduler jobs create pubsub calculate-monthly-stats \
  --location=asia-northeast1 \
  --schedule="0 18 1 * *" \
  --time-zone="UTC" \
  --topic="firebase-schedule-calculateMonthlyStatsScheduled-asia-northeast1" \
  --message-body="{}" \
  --description="Monthly stats calculation at JST 03:00 on 1st"
```

### 確認コマンド

```bash
# Scheduler ジョブ一覧表示
gcloud scheduler jobs list --location=asia-northeast1

# Pub/Sub トピック確認
gcloud pubsub topics list --filter="name:firebase-schedule"

# Functions ログ確認
gcloud functions logs read expirePointsScheduled --limit 50
gcloud functions logs read calculateMonthlyStatsScheduled --limit 50
```

---

## 🔍 変更ファイル一覧

### 新規ファイル

- `functions/src/points_expire.ts` (200行): ポイント失効処理
- `functions/src/points_stats.ts` (186行): 月次統計計算
- `PR_M7_BODY.md` (本ファイル): PR本文

### 更新ファイル

- `functions/src/index.ts`: 新規関数のエクスポート、addPointsInTransaction 更新
- `firestore.rules`: stats コレクションのルール追加
- `lib/features/points/points_repository.dart`: expiresAt フィールド追加、getExpiringPoints メソッド追加
- `lib/features/points/points_screen.dart`: 失効予定インジケータ追加
- `README.md`: Cloud Scheduler ドキュメント追加

### 差分サマリー

```
 functions/src/index.ts                           |  62 ++++--
 functions/src/points_expire.ts                   | 200 ++++++++++++++++
 functions/src/points_stats.ts                    | 186 +++++++++++++++
 firestore.rules                                  |   5 +
 lib/features/points/points_repository.dart       |  45 +++-
 lib/features/points/points_screen.dart           |  41 ++++
 README.md                                        | 191 +++++++++++++++
 PR_M7_BODY.md                                    | 500 +++++++++++++++++++++++++++++++++++++
 8 files changed, 1,200 insertions(+), 30 deletions(-)
```

---

## 🚀 デプロイ手順

### 1. Cloud Functions デプロイ

```bash
cd functions
npm install
npm run build
npm run deploy
```

### 2. Firestore Rules デプロイ

```bash
firebase deploy --only firestore:rules
```

### 3. Cloud Scheduler 設定

上記の「Cloud Scheduler 設定コマンド」を実行

### 4. 動作確認

```bash
# expirePointsDev で手動テスト
# calculateMonthlyStatsDev で手動テスト
# UI で失効予定インジケータを確認
```

---

## 📊 セルフチェック（M7用）

### 必須確認項目

- ✅ Functions 2本が region=asia-northeast1 で統一
- ✅ Cloud Scheduler の UTC/JST 換算を README に明記
- ✅ expirePoints の Tx で users.totalPoints / pointLedger の整合 OK
- ✅ stats 直書き Denied、users.totalPoints 直更新 Denied
- ✅ PointsScreen に失効予定帯が出て、0 のときは非表示
- ✅ CI（analyze/test/ios no-codesign）Green

---

## 🎬 次のステップ

1. **レビュー**: @Yusaku-062255 によるコードレビュー
2. **実機テスト**: 失効予定インジケータの表示確認
3. **Cloud Scheduler 設定**: 本番環境で Scheduler ジョブを作成
4. **モニタリング**: Functions のログを監視（初回実行時）
5. **マージ**: レビュー承認後、develop ブランチにマージ

---

**実装者**: Claude Code
**レビュアー**: @Yusaku-062255
**ブランチ**: `claude/m7-points-expiry-stats-011CUd6FuRV8GpugKptPeYVX`
**ベースブランチ**: `develop` (または `main`)
