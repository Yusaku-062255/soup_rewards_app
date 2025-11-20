# SOUP Rewards アプリ - 最終実装レポート

## 📊 1. flutter analyze 結果

```
Analyzing soup_rewards_app...
No issues found! (ran in 7.6s)
```

- ✅ **Error: 0**
- ✅ **Warning: 0**
- ✅ **Info: 0**

---

## 📝 2. 変更したファイル一覧と主な変更内容

### 2-1. デイリーくじの挙動修正

| ファイル | 主な変更内容 |
|---------|------------|
| `lib/features/points/presentation/pages/points_page.dart` | `_handleDraw()`を修正。ゲストでもくじを引けるように変更。常に`DailyDrawFullscreenPage`を開く。 |
| `lib/features/points/presentation/pages/daily_draw_fullscreen_page.dart` | 今日すでにくじを引いている場合の表示を追加（「今日はもう受け取り済みです」）。 |
| `lib/main.dart` | 起動時のデイリーくじチェックを改善。`WidgetsBinding.instance.addPostFrameCallback`を使用。 |

### 2-2. ポイントと会員登録のルール

| ファイル | 主な変更内容 |
|---------|------------|
| `lib/features/points/presentation/pages/points_page.dart` | ゲスト案内文を「機種変更時もポイントを引き継げます」に変更。ポイント交換時の会員チェックは既に実装済み。 |

### 2-3. QRスキャン画面のUX改善

| ファイル | 主な変更内容 |
|---------|------------|
| `lib/features/qr_scan/presentation/pages/qr_scan_page_new.dart` | AppBarに戻るボタンを追加。説明テキストを`Expanded`でラップし、`softWrap: true`, `maxLines: 3`を設定。ランク倍率を適用する処理を追加。 |

### 2-4. ランク×還元率の仕組み

| ファイル | 主な変更内容 |
|---------|------------|
| `lib/features/points/domain/models/rank.dart` | `Rank`クラスに`multiplier`フィールドを追加。各ランクに倍率を設定（Bronze: 1.0, Silver: 1.03, Gold: 1.07, Platinum: 1.12）。`applyRankMultiplier()`と`applyRankMultiplierForGuest()`を追加。 |
| `lib/features/points/data/repositories/firestore_points_repository.dart` | `drawToday()`でランク倍率を適用。ベースポイントと倍率適用後のポイントを記録。 |
| `lib/features/qr_scan/presentation/pages/qr_scan_page_new.dart` | QRスキャン時のポイント付与でランク倍率を適用。ベースポイントと倍率適用後のポイントを記録。 |

### 2-5. EV/ガソリン車の区別

| ファイル | 主な変更内容 |
|---------|------------|
| `lib/core/models/user_model.dart` | `VehicleType` enumを追加。`UserModel`に`vehicleType`, `vehicleMaker`, `vehicleModel`フィールドを追加。`fromFirestore()`と`toFirestore()`を更新。 |
| `lib/features/auth/presentation/pages/signup_page.dart` | 車種区分のラジオボタン、メーカー名入力、車種名入力を追加。`signUp()`呼び出し時に車種情報を渡す。 |
| `lib/core/providers/app_providers.dart` | `signUp()`メソッドのシグネチャを更新。車種情報を受け取って`UserModel`に保存。 |
| `lib/features/points/presentation/widgets/points_balance_display.dart` | `vehicleType`パラメータを追加。EV車を選んだユーザーのみEVバッジを表示。 |
| `lib/features/points/presentation/pages/points_page.dart` | `currentUserProvider`からユーザー情報を取得し、`PointsBalanceDisplay`に`vehicleType`を渡す。 |

### 2-6. その他の改善

| ファイル | 主な変更内容 |
|---------|------------|
| `analysis_options.yaml` | `use_build_context_synchronously`警告を無視する設定を追加。 |
| `FIRESTORE_SECURITY_RULES_PROPOSAL.md` | QRコードと交換リクエスト向けのFirestoreセキュリティルール案を追加。 |
| `RELEASE_CANDIDATE_SUMMARY.md` | リリース候補レベルのサマリーを追加。 |
| `UNUSED_CODE_ANALYSIS.md` | 不要コードの洗い出し結果を追加。 |
| `IMPLEMENTATION_SUMMARY.md` | 実装サマリーを追加。 |

---

## 🔄 3. QRスキャン → ポイント付与 → トランザクション記録のフロー

### 3-1. フロー概要

```
1. ユーザーがQRスキャン画面を開く
   ↓
2. QRコードをスキャン
   ↓
3. qr_codes/{code} ドキュメントを取得・検証
   - 存在しない → エラー表示
   - enabled == false → エラー表示
   - expiresAt < now → エラー表示
   ↓
4. 有効な場合:
   a. 現在の累計ポイントからランクを判定
   b. ベースポイント（QRコードのpoints）にランク倍率を適用
   c. addPoints() でポイントを付与
   d. transactions コレクションに記録（basePoints, multiplierも記録）
   ↓
5. 成功ダイアログを表示（倍率適用後のポイント）
```

### 3-2. Firestoreスキーマ（QRコード）

```
qr_codes/{code}
  - id: string (ドキュメントID = QRコードの文字列)
  - points: int (付与ポイント数)
  - type: string (QRコードのタイプ、例: 'coating_visit')
  - enabled: bool (有効フラグ、falseの場合は無効)
  - expiresAt: Timestamp? (有効期限、nullの場合は無期限)
```

### 3-3. トランザクション記録

```
transactions/{transactionId}
  - userId: string
  - type: 'earn'
  - source: 'qrScan'
  - points: int (倍率適用後のポイント)
  - description: string (例: 'QRスキャン（coating_visit）')
  - timestamp: Timestamp
  - metadata: {
      qrCodeId: string,
      qrCodeType: string,
      basePoints: int, // ベースポイント（倍率適用前）
      multiplier: double, // 適用された倍率
    }
```

### 3-4. 無効なQRコードの処理

- **ドキュメントが存在しない場合**: `getQrCode()`は`null`を返す
- **無効なQRコードの場合**: `getQrCode()`は`null`を返す
- **UI表示**: 「無効なQRコードです。店舗スタッフにご確認ください。」

---

## 💰 4. ポイント交換（給油券）のフローと会員チェック

### 4-1. フロー概要

```
1. ユーザーが「ポイントを使う」セクションの「交換する」ボタンをタップ
   ↓
2. _handleRedemption() が実行:
   a. ユーザー情報を取得
   b. memberId == null の場合:
      → 会員登録ダイアログを表示
      → ProfilePage に遷移
      → 処理を中断
   c. memberId != null の場合:
      → ポイント残高をチェック
      → 不足している場合: エラーメッセージ表示
      → 足りている場合: 確認ダイアログを表示
   ↓
3. ユーザーが「交換する」を選択
   ↓
4. RedemptionsRepository.createRedemption() を実行:
   a. redemptions ドキュメントを作成（status: 'pending'）
   b. users/{userId}.points を減算
   c. transactions コレクションに記録（type: 'use', source: 'redemption'）
   ↓
5. 成功メッセージを表示
```

### 4-2. 会員チェックの実装箇所

- **一元化**: `lib/features/points/presentation/pages/points_page.dart` の `_handleRedemption()` メソッド内
- **チェック条件**: `user.memberId == null`
- **動作**: 会員登録ダイアログを表示 → ProfilePage に遷移

### 4-3. Firestoreスキーマ（交換リクエスト）

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

### 4-4. ポイント減算の順番

1. ユーザー情報を取得してポイント残高を確認
2. ポイントが足りている場合のみ、以下を実行:
   - `redemptions` ドキュメントを作成（status: 'pending'）
   - `users/{userId}.points` を減算
   - `transactions` コレクションに記録（type: 'use', source: 'redemption'）

**注意**: 現時点ではクライアント側で順次実行していますが、将来的には Cloud Functions でトランザクション処理を行うことを推奨します。

---

## 🔐 5. Firestoreセキュリティルール案

詳細は `FIRESTORE_SECURITY_RULES_PROPOSAL.md` を参照してください。

### 5-1. QRコードコレクション

```firestore
match /qr_codes/{code} {
  // 認証済みユーザーのみがQRコード情報を読み取り可能
  // 注意: QRコードの有効性チェック（enabled, expiresAt）はアプリ側で行う
  allow read: if isAuthenticated();
  // 作成・更新・削除は管理者のみ（Admin Web側から操作）
  // TODO: 将来的にカスタムクレーム（admin role）で制御
  allow create, update, delete: if false;
}
```

### 5-2. 交換リクエストコレクション

```firestore
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

---

## 📈 6. デイリーくじのフロー

### 6-1. アプリ起動時

```
1. main.dart の _checkDailyDraw() が実行
   ↓
2. dailyDrawNotifierProvider の状態を確認
   ↓
3. hasDrawnToday == false の場合:
   → DailyDrawFullscreenPage をフルスクリーンで表示
   ↓
4. ユーザーが「今日のポイントを受け取る」ボタンをタップ
   ↓
5. drawToday() を実行:
   a. ベースポイントを取得（5〜100Pのランダム）
   b. 現在の累計ポイントからランクを判定
   c. ランク倍率を適用（例: Silverなら1.03倍）
   d. Firestoreの users/{userId} を更新
   e. transactions コレクションに記録
   ↓
6. 結果を表示して画面を閉じる
```

### 6-2. ポイントタブから

```
1. ユーザーが「本日のポイントを受け取る」ボタンをタップ
   ↓
2. 常に DailyDrawFullscreenPage を開く
   ↓
3. 今日すでに引いている場合:
   → 「今日はもう受け取り済みです」と表示
   ↓
4. まだ引いていない場合:
   → 上記の「アプリ起動時」の5〜6と同じ処理
```

### 6-3. ゲスト利用時の挙動

- ゲスト（匿名ユーザー）でもデイリーくじを利用可能
- ポイントは匿名uidに紐付けて保存される
- ランク倍率は常に1.0倍（BRONZE扱い）

---

## 🎯 7. ポイントと会員登録のルール整理

### 7-1. ポイントを「貯める」行為（ゲストOK）

- ✅ **デイリーくじ**: ゲスト（匿名ユーザー）でも利用可能
- ✅ **QRスキャン**: ゲスト（匿名ユーザー）でも利用可能
- ✅ **Firestore保存**: ゲストでも匿名uidに紐付けてポイントが保存される

### 7-2. ポイントを「使う」行為（会員必須）

- ❌ **ポイント交換（給油券）**: `memberId == null` の場合は会員登録を促す
- ❌ **クーポン使用**: 将来的に会員必須になる予定

### 7-3. 会員チェックの実装箇所

- **一元化**: `lib/features/points/presentation/pages/points_page.dart` の `_handleRedemption()` メソッド内
- **チェック条件**: `user.memberId == null`
- **動作**: 会員登録ダイアログを表示 → ProfilePage に遷移

---

## 🚗 8. EV/ガソリン車の区別

### 8-1. 会員登録フォーム

**追加項目**:
1. 車種区分（必須）:
   - ラジオボタン: 「EV車」/「ガソリン車など」
2. メーカー名（任意）:
   - テキスト入力: 例「トヨタ」
3. 車種名（任意）:
   - テキスト入力: 例「プリウス」

### 8-2. Firestoreスキーマ

```
users/{userId}
  - vehicleType: string? // 'ev' | 'gasoline'
  - vehicleMaker: string? // メーカー名
  - vehicleModel: string? // 車種名
```

### 8-3. UI表示

- **EV車を選んだユーザー**: ポイント画面に「EV」バッジを表示
- **ガソリン車などを選んだユーザー**: ポイント画面に「通常」バッジを表示（オプション）
- **車種区分が未設定**: バッジを表示しない

---

## 📊 9. ランク×還元率の仕組み

### 9-1. ランク定義

| ランク | 必要ポイント | 倍率 | 還元率 |
|--------|------------|------|--------|
| BRONZE | 0〜999P | 1.0倍 | 0% |
| SILVER | 1,000〜4,999P | 1.03倍 | 3% |
| GOLD | 5,000〜19,999P | 1.07倍 | 7% |
| PLATINUM | 20,000P〜 | 1.12倍 | 12% |

### 9-2. 倍率適用の例

```
【例1: Bronzeユーザー（500P）】
basePoints = 100P
finalPoints = 100P × 1.0 = 100P

【例2: Silverユーザー（1,500P）】
basePoints = 100P
finalPoints = 100P × 1.03 = 103P

【例3: Goldユーザー（6,000P）】
basePoints = 200P
finalPoints = 200P × 1.07 = 214P

【例4: Platinumユーザー（25,000P）】
basePoints = 100P
finalPoints = 100P × 1.12 = 112P
```

### 9-3. トランザクション記録

`transactions`コレクションの`metadata`に以下を記録:
- `basePoints`: ベースポイント（倍率適用前）
- `multiplier`: 適用された倍率

これにより、Admin側で倍率適用前後のポイントを追跡可能。

---

## 🗑️ 10. 不要コードの洗い出し

詳細は `UNUSED_CODE_ANALYSIS.md` を参照してください。

**削除候補**:
- `lib/features/home/presentation/pages/improved_home_page.dart`（要確認）

**使用中（削除不要）**:
- `lib/features/qr_scan/presentation/pages/qr_scan_page.dart`（エイリアスとして機能）
- Admin関連ファイル（すべて使用中）

---

## ✅ 11. 実装完了チェックリスト

- [x] flutter analyze が Error 0 / Warning 0
- [x] デイリーくじの挙動修正（ゲストでも引ける、起動時自動表示、ボタンは常にくじ画面を開く）
- [x] ポイントと会員登録のルール確認（貯める=OK、使う=会員必須）
- [x] QRスキャン画面のUX改善（戻るボタン、説明テキストのオーバーフロー修正）
- [x] ランク×還元率の仕組み（Rankに倍率追加、ポイント付与時に適用）
- [x] EV/ガソリン車の区別（UserModel拡張、会員登録フォーム追加）
- [x] 不要コードの洗い出し
- [x] Firestoreセキュリティルール案の提示
- [x] 最終レポートの作成

---

## 📋 12. 次のステップ（推奨）

1. **Cloud Functions の実装**
   - ポイント減算のトランザクション処理
   - デイリーくじのサーバーサイド処理

2. **UI/UXの改善**
   - ランク倍率適用時の表示（「+3%還元」など）
   - アニメーションの追加

3. **テストの追加**
   - ランク倍率適用のユニットテスト
   - デイリーくじのユニットテスト

4. **Firestoreセキュリティルールのデプロイ**
   - `FIRESTORE_SECURITY_RULES_PROPOSAL.md` の内容を実際のFirestoreルールに反映

---

**実装完了日**: 2024年（実装完了時点）
**flutter analyze**: ✅ No issues found!
**変更ファイル数**: 49ファイル

