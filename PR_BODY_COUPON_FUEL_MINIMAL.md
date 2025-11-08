# Epic 3: 給油券（クーポン最小）実装

## 📋 概要

Epic 3 最小スライスとして、ENEOS給油券（500円分）をポイント交換で取得し、店頭でスタッフPIN入力により1回限り消込みできる機能を実装しました。

## ✨ 実装内容

### 1. Firestore Rules 追加

**新規ルール**:
```javascript
// couponTemplates（公開読取、Functionsのみ書込）
match /couponTemplates/{templateId} {
  allow read: if true; // 全ユーザーが読取可能（テンプレート情報）
  allow write: if false; // Cloud Functionsのみ
}

// serviceCenters settings（管理者のみアクセス）
match /serviceCenters/{centerId}/settings {
  allow read: if isAdmin();
  allow write: if isAdmin();
}
```

**既存ルール確認**:
- `users/{userId}/coupons` は既に `write: false` で保護済み

### 2. Cloud Functions（3つ）

**ファイル**: `functions/src/coupons_fuel.ts`

#### ensureFuelVoucherTemplate

テンプレートが存在しない場合のみ作成（idempotent）。

```typescript
// テンプレート: fuel_voucher_500yen
{
  title: "Fuel Voucher (ENEOS)",
  type: "flat_yen",
  discountValueYen: 500,
  pointsCost: 500,
  validityDays: 30,
  active: true
}
```

#### redeemPointsForFuelVoucher

ポイント消費して給油券を発行。

**トランザクション処理**:
1. ポイント残高チェック（不足時は `insufficient_points` エラー）
2. `users.totalPoints` から 500pt 減算
3. `pointLedger` に `type: "coupon"` で記録
4. `users/{uid}/coupons` に新規クーポン追加
   - 8桁英数字コード生成
   - `issuedAt` + 30日 = `expiresAt`
   - `status: "active"`

**セキュリティ**:
- 認証必須（`unauthenticated` エラー）
- トランザクションによるポイント整合性保証
- 二重発行防止（テンプレート検証）

#### redeemFuelVoucherAtStore

店頭でスタッフPINを使ってクーポンを消込み。

**処理フロー**:
1. スタッフPIN検証（SHA-256 ハッシュ + salt 比較）
   - 不正時: `invalid_staff_pin` エラー
2. クーポン状態確認
   - Owner チェック
   - `status: "active"` チェック
   - 有効期限チェック（expired エラー）
3. トランザクションで更新
   - `status: "redeemed"`
   - `redeemedAt: Timestamp`
   - `redeemedBy: { centerId, staffId: "PIN" }`

**セキュリティ**:
- 同一クーポンの二重使用防止（status チェック）
- スタッフPINはハッシュ化保存
- トランザクションによる原子性保証

### 3. Flutter 実装

#### Coupon Model

**ファイル**: `lib/features/coupons/domain/models/coupon.dart`

```dart
class Coupon {
  final String id;
  final String templateId;
  final String code; // 8桁
  final String status; // 'active' | 'redeemed' | 'expired'
  final DateTime issuedAt;
  final DateTime expiresAt;
  final DateTime? redeemedAt;
  final Map<String, dynamic>? redeemedBy;
  final CouponMeta meta;
}

class CouponTemplate {
  final String id;
  final String title;
  final String type;
  final int discountValueYen;
  final int pointsCost;
  final int validityDays;
  final bool active;
}
```

#### CouponsRepository

**ファイル**: `lib/features/coupons/data/coupons_repository.dart`

**メソッド**:
- `Future<CouponTemplate?> getFuelVoucherTemplate()`
- `Future<Map<String, dynamic>> redeemPointsForFuelVoucher(String templateId)`
- `Future<Map<String, dynamic>> redeemAtStore({couponId, centerId, staffPin})`
- `Stream<List<Coupon>> myCoupons(String userId, {int limit = 20})`
- `Future<void> ensureFuelVoucherTemplate()` (dev helper)

#### CouponsScreen UI

**ファイル**: `lib/features/coupons/presentation/coupons_screen.dart`

**主要機能**:
1. **テンプレート自動読込**
   - 初回は `ensureFuelVoucherTemplate` で作成
   - 必要ポイント・券面額・有効期限を表示

2. **「給油券に交換」ボタン**
   - ポイント不足時: 日本語エラーメッセージ
   - 成功時: クーポンコードをスナックバーで表示

3. **マイクーポン一覧**
   - ステータス別表示（active / 使用済み / 期限切れ）
   - 8桁コードを大きく表示
   - 有効期限を表示

4. **「店頭で使う」ダイアログ**
   - centerId 選択（現在は "default" 固定）
   - スタッフ6桁PIN入力
   - 使用後は「使用済み」バッジ表示

**エラーメッセージ（日本語）**:
- `insufficient_points` → 「ポイントが不足しています」
- `invalid_staff_pin` → 「スタッフ用PINが正しくありません」
- `already_redeemed` → 「このクーポンは既に使用済みです」
- `expired` → 「このクーポンは有効期限が切れています」
- ネットワーク/Functions エラーも M6 同品質で整備

### 4. README 更新

**新規セクション**: `🎟️ 給油券（クーポン最小）の使い方`

**内容**:
- 概要・機能説明
- テンプレート初期化手順
- スタッフPIN設定手順（salt + SHA-256）
- ユーザー側の使い方（発行→店頭使用）
- Firestore データ構造
- Cloud Functions 詳細仕様
- エラーメッセージ一覧
- デプロイ手順
- セキュリティ詳細
- トラブルシューティング
- 今後の拡張案（6項目）

---

## 🧪 テスト手順

### 事前準備

#### 1. スタッフPIN設定

```bash
# Node.js で salt と hash を生成
node -e "
const crypto = require('crypto');
const pin = '123456'; // テスト用PIN
const salt = crypto.randomBytes(16).toString('hex');
const hash = crypto.createHash('sha256').update(pin + salt).digest('hex');
console.log('Salt:', salt);
console.log('Hash:', hash);
"
```

Firestore Console で設定:
```
serviceCenters/default/settings/redeem
{
  redeemPinHash: "[生成したHash]",
  salt: "[生成したSalt]"
}
```

#### 2. Cloud Functions デプロイ

```bash
cd functions
npm install
npm run build
npm run deploy
```

#### 3. Firestore Rules デプロイ

```bash
firebase deploy --only firestore:rules
```

### 正常系テスト

#### シナリオ1: 給油券発行（成功）

**前提条件**: ポイント残高 >= 500pt

**手順**:
1. アプリを起動し、ログイン
2. 「クーポン」タブをタップ
3. 現在のポイント残高を確認（500pt 以上）
4. 「給油券に交換」ボタンをタップ
5. スクリーンショット撮影

**期待結果**:
- ✅ スナックバー「給油券を発行しました！ コード: ABCD1234」が表示される
- ✅ マイクーポン一覧に新しいクーポンが追加される
- ✅ クーポンカードに以下が表示される:
  - タイトル: "Fuel Voucher (ENEOS)"
  - 券面額: "500円割引"
  - コード: 8桁英数字
  - 有効期限: 発行日 + 30日
  - ステータス: active（バッジなし）
- ✅ Firestore の `users/{uid}/coupons/{couponId}` にドキュメントが作成される
- ✅ Firestore の `users/{uid}.totalPoints` が 500pt 減る
- ✅ Firestore の `users/{uid}/pointLedger` に type: "coupon" のエントリが追加される

#### シナリオ2: 店頭で使用（成功）

**前提条件**: シナリオ1で発行したクーポンが active 状態

**手順**:
1. マイクーポン一覧から active なクーポンをタップ
2. 「店頭で使う」ボタンをタップ
3. ダイアログが表示される
4. スタッフ用PIN に `123456` を入力
5. 「使用する」ボタンをタップ
6. スクリーンショット撮影

**期待結果**:
- ✅ スナックバー「クーポンを使用しました！ 500円割引」が表示される
- ✅ クーポンカードのステータスが「使用済み」バッジに変わる
- ✅ 「店頭で使う」ボタンが消える
- ✅ 使用日時が表示される
- ✅ Firestore の `users/{uid}/coupons/{couponId}` が以下のように更新される:
  - `status: "redeemed"`
  - `redeemedAt: Timestamp`
  - `redeemedBy: { centerId: "default", staffId: "PIN" }`

### 異常系テスト

#### シナリオ3: ポイント不足で発行失敗

**前提条件**: ポイント残高 < 500pt

**手順**:
1. 「クーポン」タブをタップ
2. 「給油券に交換」ボタンをタップ
3. スクリーンショット撮影

**期待結果**:
- ✅ スナックバー「ポイントが不足しています」が表示される（赤色背景）
- ✅ クーポンは発行されない
- ✅ ポイント残高は変わらない

#### シナリオ4: 誤ったスタッフPINで消込み失敗

**前提条件**: active なクーポンが存在

**手順**:
1. 「店頭で使う」ボタンをタップ
2. スタッフ用PIN に `999999` (誤ったPIN) を入力
3. 「使用する」ボタンをタップ

**期待結果**:
- ✅ スナックバー「スタッフ用PINが正しくありません」が表示される（赤色背景）
- ✅ クーポンのステータスは active のまま
- ✅ Firestore のデータは変更されない

#### シナリオ5: 二重使用を防止

**前提条件**: redeemed 状態のクーポンが存在

**手順**:
1. 使用済みクーポンカードを確認
2. 「店頭で使う」ボタンが表示されないことを確認

**期待結果**:
- ✅ クーポンカードに「使用済み」バッジが表示される
- ✅ 「店頭で使う」ボタンが表示されない
- ✅ 使用日時が表示される

#### シナリオ6: 有効期限切れクーポン

**前提条件**: `expiresAt` が現在日時より前のクーポン（テストデータで作成）

**手順**:
1. マイクーポン一覧を表示

**期待結果**:
- ✅ クーポンカードに「期限切れ」バッジが表示される（赤色背景）
- ✅ 「店頭で使う」ボタンが表示されない

#### シナリオ7: 直接書き込みは禁止

**Rules Playground で検証**:

```
Location: /users/test-user-123/coupons/coupon-001
Type: create
Auth: Authenticated (UID: test-user-123)

Data:
{
  "templateId": "fuel_voucher_500yen",
  "code": "HACKED11",
  "status": "active",
  "issuedAt": "2025-01-15T10:00:00Z",
  "expiresAt": "2025-02-15T10:00:00Z",
  "meta": {
    "discountValueYen": 500,
    "type": "flat_yen",
    "title": "Fuel Voucher (ENEOS)"
  }
}

Expected Result: ❌ Permission denied
Reason: coupons への書き込みは Functions のみ
```

### Firestore Console 確認

#### 確認1: クーポンテンプレート

```
couponTemplates/fuel_voucher_500yen

期待されるデータ:
{
  title: "Fuel Voucher (ENEOS)",
  type: "flat_yen",
  discountValueYen: 500,
  pointsCost: 500,
  validityDays: 30,
  active: true,
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

#### 確認2: 発行されたクーポン

```
users/{uid}/coupons/{couponId}

期待されるデータ（active 時）:
{
  templateId: "fuel_voucher_500yen",
  code: "ABCD1234", // 8桁英数字
  status: "active",
  issuedAt: Timestamp,
  expiresAt: Timestamp, // issuedAt + 30日
  meta: {
    discountValueYen: 500,
    type: "flat_yen",
    title: "Fuel Voucher (ENEOS)"
  }
}

期待されるデータ（redeemed 時）:
{
  ...上記のフィールド,
  status: "redeemed",
  redeemedAt: Timestamp,
  redeemedBy: {
    centerId: "default",
    staffId: "PIN"
  }
}
```

#### 確認3: ポイント減算記録

```
users/{uid}/pointLedger/{entryId}

期待されるデータ:
{
  type: "coupon",
  delta: -500,
  balance: [現在の残高],
  note: "Fuel Voucher (500円)",
  createdAt: Timestamp,
  expiredProcessed: false
}
```

#### 確認4: スタッフPIN設定

```
serviceCenters/default/settings/redeem

期待されるデータ:
{
  redeemPinHash: "[SHA-256ハッシュ値]",
  salt: "[ランダムsalt値]"
}
```

---

## 📸 スクリーンショット要件

PR作成時に以下の4枚のスクリーンショットを添付してください：

### 1. 発行前画面

**手順**:
1. 「クーポン」タブを開く
2. ポイント残高が 500pt 以上あることを確認
3. スクリーンショット撮影

**確認項目**:
- ✅ 「Fuel Voucher (ENEOS)」タイトル表示
- ✅ 「500円割引」表示
- ✅ 必要ポイント「500 pt」表示
- ✅ 有効期限「発行から30日間」表示
- ✅ 「給油券に交換」ボタン表示

### 2. 発行後のクーポンカード

**手順**:
1. 「給油券に交換」ボタンをタップ
2. 成功後、マイクーポン一覧が表示される
3. スクリーンショット撮影

**確認項目**:
- ✅ クーポンカードが表示される
- ✅ タイトル「Fuel Voucher (ENEOS)」
- ✅ 券面額「500円割引」
- ✅ 8桁コードが大きく表示される
- ✅ 有効期限が表示される（発行日 + 30日）
- ✅ 「店頭で使う」ボタンが表示される
- ✅ 説明文「※店頭でスタッフがPINを入力します」が表示される

### 3. 店頭PIN入力ダイアログ

**手順**:
1. 「店頭で使う」ボタンをタップ
2. ダイアログが表示される
3. スクリーンショット撮影

**確認項目**:
- ✅ タイトル「店頭での使用」
- ✅ 説明文「スタッフにクーポンコードを提示し、スタッフ用6桁PINを入力してください。」
- ✅ テキストフィールド「スタッフ用PIN（6桁）」
- ✅ プレースホルダー「123456」
- ✅ 「キャンセル」ボタン
- ✅ 「使用する」ボタン

### 4. 使用済み状態

**手順**:
1. 正しいPIN（123456）を入力して使用
2. マイクーポン一覧を確認
3. スクリーンショット撮影

**確認項目**:
- ✅ 「使用済み」バッジが表示される（グレー背景）
- ✅ 「店頭で使う」ボタンが消えている
- ✅ 使用日時が表示される（「使用日時: YYYY/MM/DD HH:MM」）
- ✅ コードと券面額は引き続き表示される
- ✅ クーポンカード全体がグレーアウトされている

---

## 🎯 受入基準（DoD）

### 機能要件

- ✅ ポイント 500pt で給油券（500円分）を発行できる
- ✅ ポイント不足時は日本語エラーメッセージが表示される
- ✅ 発行されたクーポンに8桁の英数字コードが生成される
- ✅ 発行から30日間が有効期限として設定される
- ✅ 店頭でスタッフPIN（6桁）入力により消込みできる
- ✅ 誤ったPIN入力時は日本語エラーメッセージが表示される
- ✅ 同一クーポンは1回のみ使用可能（二重使用防止）
- ✅ 使用済みクーポンは「使用済み」バッジが表示される
- ✅ 有効期限切れクーポンは「期限切れ」バッジが表示される

### セキュリティ要件

- ✅ `users/{uid}/coupons` への直接書き込みが禁止される（write: false）
- ✅ `couponTemplates` への書き込みが禁止される（write: false）
- ✅ `serviceCenters/{centerId}/settings` は管理者のみアクセス可能
- ✅ スタッフPINはハッシュ化して保存（salt + SHA-256）
- ✅ クーポン発行・消込みはすべて Cloud Functions 経由
- ✅ トランザクションによるポイント残高の整合性保証

### データ整合性

- ✅ クーポン発行時に `users.totalPoints` が正しく減算される
- ✅ `pointLedger` に type: "coupon" のエントリが追加される
- ✅ クーポン消込み時に `status` が "redeemed" に更新される
- ✅ `redeemedAt` と `redeemedBy` が正しく記録される

### ドキュメント要件

- ✅ README に「給油券の使い方」セクションが追加されている
- ✅ テンプレート初期化手順が記載されている
- ✅ スタッフPIN設定手順が記載されている（salt + hash 生成）
- ✅ ユーザー側の使い方が記載されている
- ✅ Cloud Functions の詳細仕様が記載されている
- ✅ エラーメッセージ一覧が記載されている
- ✅ セキュリティ詳細が記載されている
- ✅ トラブルシューティングが記載されている
- ✅ 今後の拡張案が記載されている

### CI/CD要件

- ✅ CI（analyze/test/ios no-codesign）が Green
- ✅ TypeScript のコンパイルエラーがない
- ✅ Flutter の既存テストが全て PASS
- ✅ Firestore Rules のデプロイが成功する

---

## 🔍 変更ファイル一覧

### 新規ファイル (5)

1. **functions/src/coupons_fuel.ts** (350行)
   - ensureFuelVoucherTemplate
   - redeemPointsForFuelVoucher
   - redeemFuelVoucherAtStore

2. **lib/features/coupons/domain/models/coupon.dart** (100行)
   - Coupon モデル
   - CouponMeta モデル
   - CouponTemplate モデル

3. **lib/features/coupons/data/coupons_repository.dart** (85行)
   - CouponsRepository
   - Riverpod provider

4. **lib/features/coupons/presentation/coupons_screen.dart** (680行)
   - CouponsScreen
   - _CouponCard
   - _StaffPinDialog

5. **PR_BODY_COUPON_FUEL_MINIMAL.md** (本ファイル)

### 更新ファイル (3)

6. **firestore.rules**
   - couponTemplates ルール追加
   - serviceCenters/{centerId}/settings ルール追加

7. **functions/src/index.ts**
   - coupons_fuel のexport追加

8. **README.md**
   - 「給油券（クーポン最小）の使い方」セクション追加（270行）

### 差分サマリー

```
 firestore.rules                                      |  11 +
 functions/src/coupons_fuel.ts                        | 350 ++++++++++++++++
 functions/src/index.ts                               |   3 +
 lib/features/coupons/domain/models/coupon.dart       | 100 +++++
 lib/features/coupons/data/coupons_repository.dart    |  85 ++++
 lib/features/coupons/presentation/coupons_screen.dart| 680 ++++++++++++++++++++++++++++++
 README.md                                            | 270 ++++++++++++
 PR_BODY_COUPON_FUEL_MINIMAL.md                       | 800 ++++++++++++++++++++++++++++++++++
 8 files changed, 2,299 insertions(+), 0 deletions(-)
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

**期待される出力**:
```
✔  functions[ensureFuelVoucherTemplate(asia-northeast1)] Successful create operation.
✔  functions[redeemPointsForFuelVoucher(asia-northeast1)] Successful create operation.
✔  functions[redeemFuelVoucherAtStore(asia-northeast1)] Successful create operation.
```

### 2. Firestore Rules デプロイ

```bash
firebase deploy --only firestore:rules
```

**期待される出力**:
```
✔  firestore: released rules firestore.rules to cloud.firestore
```

### 3. スタッフPIN設定

```bash
node -e "
const crypto = require('crypto');
const pin = '123456';
const salt = crypto.randomBytes(16).toString('hex');
const hash = crypto.createHash('sha256').update(pin + salt).digest('hex');
console.log('Salt:', salt);
console.log('Hash:', hash);
"
```

Firestore Console で設定を保存（`serviceCenters/default/settings/redeem`）

### 4. テンプレート初期化

アプリ起動時に自動実行されるか、手動で：

```dart
final functions = FirebaseFunctions.instanceFor(region: 'asia-northeast1');
await functions.httpsCallable('ensureFuelVoucherTemplate').call();
```

---

## 💡 今後の拡張案（伸ばし方）

### 1. 交換レート変動

需要期はポイントコスト増、閑散期は減で誘導：

```typescript
// テンプレートに dynamicPricing フィールドを追加
{
  pointsCost: 500, // 基準値
  dynamicPricing: {
    peak: 600,    // 需要期（例: GW、お盆）
    offPeak: 400  // 閑散期（例: 平日午前）
  }
}
```

### 2. 予約完了トーストで交差導線

予約完了時に「今だけ給油券」を提案：

```dart
// BookingScreen で予約完了後
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('予約完了！ 今なら給油券が400ptで交換できます'),
    action: SnackBarAction(
      label: '交換する',
      onPressed: () => Navigator.push(...CouponsScreen),
    ),
  ),
);
```

### 3. 失効警告帯からワンタップ交換

M7の失効予定表示から「今使う」で動機付け：

```dart
// PointsScreen の失効予定インジケータに追加
ElevatedButton(
  onPressed: () => _redeemBeforeExpiry(context),
  child: Text('失効前に給油券に交換'),
)
```

### 4. QR/HMACコード

PIN方式からQRコード + HMAC検証に拡張：

```typescript
// HMAC生成（Functions側）
const hmac = crypto.createHmac('sha256', secret)
  .update(couponId + centerId + timestamp)
  .digest('hex');

// QRコードデータ
const qrData = JSON.stringify({
  couponId,
  centerId,
  timestamp,
  hmac
});
```

### 5. 複数店舗対応

centerId を選択可能にする：

```dart
// CouponsScreen で店舗選択ダイアログを追加
final centerId = await showDialog<String>(
  context: context,
  builder: (context) => _StoreSelectorDialog(),
);
```

### 6. 複数クーポン種類

オイル交換券、洗車券など追加：

```typescript
// 新規テンプレート
{
  id: 'oil_change_1000yen',
  title: 'Oil Change Voucher',
  type: 'flat_yen',
  discountValueYen: 1000,
  pointsCost: 800,
  validityDays: 60
}
```

---

**実装者**: Claude Code
**レビュアー**: @Yusaku-062255
**ブランチ**: `claude/epic3-coupon-fuel-minimal-011CUd6FuRV8GpugKptPeYVX`
**ベースブランチ**: `develop` (または `main`)
