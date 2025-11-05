# Epic 3: クーポンシステム

## 🎯 ドメイン要件

### ユースケース

#### UC3-1: クーポン一覧の確認
- **アクター**: ユーザー
- **前提条件**: ログイン済み
- **メインフロー**:
  1. ユーザーがクーポンタブを開く
  2. システムは所持クーポンを状態別に表示（利用可能/使用済/期限切れ）
  3. ユーザーはフィルタを適用できる
  4. ユーザーはクーポンをタップして詳細を確認
- **成功条件**: 全クーポンが正確に表示される

#### UC3-2: クーポンの使用
- **アクター**: ユーザー、店舗スタッフ
- **前提条件**: 利用可能なクーポンを所持
- **メインフロー**:
  1. ユーザーがクーポン詳細を開く
  2. 「このクーポンを使う」をタップ
  3. QRコードが生成される
  4. 店舗スタッフがQRコードをスキャン
  5. システムはクーポンを検証（有効期限、利用回数、店舗制限）
  6. クーポンを使用済みに更新
  7. ユーザーと店舗に通知
- **代替フロー**:
  - 4a. QRコード読み取り失敗 → 再表示
  - 5a. 既に使用済み → エラーメッセージ
  - 5b. 有効期限切れ → エラーメッセージ
  - 5c. 利用店舗が制限外 → エラーメッセージ
- **成功条件**: クーポンが正確に消費され、二重利用が防止される

#### UC3-3: クーポンの自動配布
- **アクター**: システム（日次バッチ）
- **前提条件**: 配布条件を満たすユーザーが存在
- **メインフロー**:
  1. 毎日JST 3:00にバッチ実行
  2. 配布条件を評価（初回登録、誕生日、ポイント達成等）
  3. 対象ユーザーにクーポン発行
  4. OneSignal通知送信
- **成功条件**: 条件マッチしたユーザー全員に配布される

#### UC3-4: 管理者によるクーポン発行
- **アクター**: 管理者
- **前提条件**: 管理者権限
- **メインフロー**:
  1. 管理者がクーポンテンプレートを作成
  2. 配布対象を指定（全ユーザー/特定ユーザー/セグメント）
  3. 有効期限、利用条件を設定
  4. 発行実行
  5. 対象ユーザーに即座に反映
- **成功条件**: 指定通りに発行される

### 非機能要件

| 項目 | 要件 |
|------|------|
| **パフォーマンス** | クーポン使用 < 1秒、QR生成 < 500ms |
| **可用性** | 99.9%（店舗オペレーション影響最小化） |
| **整合性** | トランザクションで二重利用を完全防止 |
| **監視** | 発行数、利用率、不正利用をGA4/Sentryで追跡 |
| **セキュリティ** | QRコードに署名、有効期限5分、ワンタイムトークン |
| **スケーラビリティ** | キャンペーン時に10万クーポン同時発行可能 |

## 🗄️ データモデル

### `couponTemplates/{templateId}`

```typescript
interface CouponTemplate {
  // 必須フィールド
  id: string;
  title: string;                    // "10%割引クーポン"
  description: string;              // "全サービスで利用可能"
  discountType: 'percentage' | 'fixed' | 'free_service';
  discountValue: number;            // 10 (%), 500 (円), 1 (回数)

  // 利用条件
  validityDays: number;             // 発行から何日有効か（30, 60, 90）
  usageLimit: number;               // 1（1回限り）or N（複数回）
  minPurchaseAmount?: number;       // 最小購入金額（円）
  targetServices?: string[];        // 対象サービス ['wash', 'coating']
  targetStores?: string[];          // 対象店舗ID（空なら全店舗）

  // メタデータ
  imageUrl?: string;                // クーポン画像
  termsUrl?: string;                // 利用規約URL
  priority: number;                 // 表示優先度（高い順）
  category: 'campaign' | 'birthday' | 'referral' | 'point_reward';

  // 配布設定
  distributionRules?: {
    autoDistribute: boolean;
    conditions: {
      type: 'registration' | 'birthday' | 'points_threshold' | 'booking_count';
      value?: any;
    }[];
  };

  // 統計
  issuedCount: number;              // 発行総数
  redeemedCount: number;            // 利用総数

  // タイムスタンプ
  createdAt: Timestamp;
  updatedAt: Timestamp;
  archivedAt?: Timestamp;           // アーカイブ日時
}
```

### `users/{userId}/coupons/{couponId}`

```typescript
interface UserCoupon {
  // 必須フィールド
  id: string;
  userId: string;
  templateId: string;               // 元テンプレート参照
  code: string;                     // 8桁英数字（ABCD1234）

  // コピーされたクーポン内容（スナップショット）
  title: string;
  description: string;
  discountType: 'percentage' | 'fixed' | 'free_service';
  discountValue: number;

  // 状態管理
  status: 'active' | 'redeemed' | 'expired' | 'cancelled';

  // 利用情報
  issuedAt: Timestamp;              // 発行日時
  expiresAt: Timestamp;             // 有効期限
  redeemedAt?: Timestamp;           // 使用日時
  redeemedBy?: {
    storeId: string;
    staffId: string;
    staffName: string;
  };

  // QRコード関連（使用時のみ生成）
  qrToken?: string;                 // ワンタイムトークン（5分有効）
  qrGeneratedAt?: Timestamp;

  // メタデータ
  source: 'auto' | 'manual' | 'campaign' | 'point_exchange';
  conditions?: {
    minPurchaseAmount?: number;
    targetServices?: string[];
    targetStores?: string[];
  };

  // 統計
  viewedAt?: Timestamp;             // 最終閲覧日時
  viewCount: number;                // 閲覧回数
}
```

### インデックス

```json
{
  "collectionGroup": "coupons",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "userId", "order": "ASCENDING" },
    { "fieldPath": "status", "order": "ASCENDING" },
    { "fieldPath": "expiresAt", "order": "DESCENDING" }
  ]
},
{
  "collectionGroup": "coupons",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "code", "order": "ASCENDING" }
  ]
},
{
  "collectionGroup": "coupons",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "status", "order": "ASCENDING" },
    { "fieldPath": "expiresAt", "order": "ASCENDING" }
  ]
}
```

### TTL設定
- `users/{uid}/coupons/{id}` で `status: 'expired'` かつ `expiresAt < 90日前` → 自動削除（Cloud Scheduler）

## 🔐 Firestoreセキュリティルール

```javascript
// クーポンテンプレート：全ユーザー読み取り可、書き込みは管理者のみ
match /couponTemplates/{templateId} {
  allow read: if isSignedIn();
  allow write: if isAdmin();
}

// ユーザークーポン：本人のみ読み取り、書き込みはFunctionsのみ
match /users/{userId}/coupons/{couponId} {
  allow read: if isOwner(userId);
  allow write: if false; // Functionsのみ
}
```

## ☁️ Cloud Functions API

### `functions/src/coupons.ts`

#### 1. `issueCouponToUser` (Callable, 管理者専用)

**入力**:
```typescript
{
  templateId: string,
  targetUserIds: string[],        // or 'all' for全ユーザー
  customExpiresAt?: Timestamp,    // 上書き有効期限
  note?: string
}
```

**権限**: `context.auth.token.admin === true`

**出力**:
```typescript
{
  ok: true,
  issuedCount: number,
  couponIds: string[]
}
```

**ロジック**:
```typescript
export const issueCouponToUser = functions
  .region(region)
  .https.onCall(async (data, context) => {
    if (!context.auth?.token?.admin) {
      throw new functions.https.HttpsError("permission-denied", "Admin only");
    }

    const { templateId, targetUserIds, customExpiresAt, note } = data;

    const templateSnap = await admin.firestore()
      .collection("couponTemplates")
      .doc(templateId)
      .get();

    if (!templateSnap.exists) {
      throw new functions.https.HttpsError("not-found", "Template not found");
    }

    const template = templateSnap.data() as CouponTemplate;
    const batch = admin.firestore().batch();
    const couponIds: string[] = [];

    // ユーザーリスト取得
    let userIds: string[] = [];
    if (targetUserIds === 'all') {
      const usersSnap = await admin.firestore().collection("users").get();
      userIds = usersSnap.docs.map(doc => doc.id);
    } else {
      userIds = targetUserIds;
    }

    for (const userId of userIds) {
      const couponRef = admin.firestore()
        .collection("users")
        .doc(userId)
        .collection("coupons")
        .doc();

      const code = generateCouponCode(); // 8桁英数字
      const now = admin.firestore.Timestamp.now();
      const expiresAt = customExpiresAt || admin.firestore.Timestamp.fromMillis(
        now.toMillis() + template.validityDays * 24 * 60 * 60 * 1000
      );

      batch.set(couponRef, {
        userId,
        templateId,
        code,
        title: template.title,
        description: template.description,
        discountType: template.discountType,
        discountValue: template.discountValue,
        status: "active",
        issuedAt: admin.firestore.FieldValue.serverTimestamp(),
        expiresAt,
        source: "manual",
        conditions: {
          minPurchaseAmount: template.minPurchaseAmount,
          targetServices: template.targetServices,
          targetStores: template.targetStores,
        },
        viewCount: 0,
      });

      couponIds.push(couponRef.id);
    }

    // テンプレート統計更新
    batch.update(templateSnap.ref, {
      issuedCount: admin.firestore.FieldValue.increment(userIds.length),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await batch.commit();

    // OneSignal通知（バックグラウンド）
    userIds.forEach(userId => {
      sendCouponNotification(userId, template.title).catch(console.error);
    });

    return { ok: true, issuedCount: userIds.length, couponIds };
  });

function generateCouponCode(): string {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  let code = '';
  for (let i = 0; i < 8; i++) {
    code += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return code;
}
```

#### 2. `generateCouponQR` (Callable)

**入力**:
```typescript
{
  couponId: string
}
```

**出力**:
```typescript
{
  ok: true,
  qrToken: string,              // ワンタイムトークン
  expiresIn: number,            // 300秒（5分）
  couponCode: string
}
```

**ロジック**:
```typescript
export const generateCouponQR = functions
  .region(region)
  .https.onCall(async (data, context) => {
    const uid = context.auth?.uid;
    if (!uid) {
      throw new functions.https.HttpsError("unauthenticated", "Login required");
    }

    const { couponId } = data;
    const couponRef = admin.firestore()
      .collection("users")
      .doc(uid)
      .collection("coupons")
      .doc(couponId);

    const couponSnap = await couponRef.get();
    if (!couponSnap.exists) {
      throw new functions.https.HttpsError("not-found", "Coupon not found");
    }

    const coupon = couponSnap.data();

    if (coupon.status !== "active") {
      throw new functions.https.HttpsError("failed-precondition", "Coupon not active");
    }

    if (coupon.expiresAt.toMillis() < Date.now()) {
      throw new functions.https.HttpsError("failed-precondition", "Coupon expired");
    }

    // ワンタイムトークン生成（JWT or ランダム文字列 + HMAC署名）
    const qrToken = generateSecureToken(uid, couponId);

    await couponRef.update({
      qrToken,
      qrGeneratedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      ok: true,
      qrToken,
      expiresIn: 300,
      couponCode: coupon.code,
    };
  });

function generateSecureToken(userId: string, couponId: string): string {
  const crypto = require("crypto");
  const payload = `${userId}:${couponId}:${Date.now()}`;
  const secret = process.env.COUPON_SECRET || "default-secret";
  const signature = crypto.createHmac("sha256", secret)
    .update(payload)
    .digest("hex")
    .substring(0, 16);
  return `${Buffer.from(payload).toString("base64")}.${signature}`;
}
```

#### 3. `redeemCoupon` (Callable, 既存を強化)

**入力**:
```typescript
{
  qrToken: string,
  storeId: string,
  staffId: string,
  staffName: string
}
```

**出力**:
```typescript
{
  ok: true,
  coupon: {
    title: string,
    discountType: string,
    discountValue: number
  }
}
```

**ロジック**:
```typescript
export const redeemCoupon = functions
  .region(region)
  .https.onCall(async (data, context) => {
    const { qrToken, storeId, staffId, staffName } = data;

    // トークン検証
    const { userId, couponId } = verifyQRToken(qrToken);

    const couponRef = admin.firestore()
      .collection("users")
      .doc(userId)
      .collection("coupons")
      .doc(couponId);

    const result = await admin.firestore().runTransaction(async (tx) => {
      const couponSnap = await tx.get(couponRef);
      if (!couponSnap.exists) {
        return { ok: false, error: "coupon_not_found" };
      }

      const coupon = couponSnap.data();

      // 検証
      if (coupon.status !== "active") {
        return { ok: false, error: "coupon_already_used" };
      }

      if (coupon.expiresAt.toMillis() < Date.now()) {
        return { ok: false, error: "coupon_expired" };
      }

      // QRトークン有効期限（5分）
      if (coupon.qrGeneratedAt) {
        const tokenAge = Date.now() - coupon.qrGeneratedAt.toMillis();
        if (tokenAge > 5 * 60 * 1000) {
          return { ok: false, error: "qr_expired" };
        }
      }

      // 店舗制限チェック
      if (coupon.conditions?.targetStores?.length > 0) {
        if (!coupon.conditions.targetStores.includes(storeId)) {
          return { ok: false, error: "store_not_allowed" };
        }
      }

      // 使用済みに更新
      tx.update(couponRef, {
        status: "redeemed",
        redeemedAt: admin.firestore.FieldValue.serverTimestamp(),
        redeemedBy: { storeId, staffId, staffName },
      });

      // テンプレート統計更新
      tx.update(
        admin.firestore().collection("couponTemplates").doc(coupon.templateId),
        {
          redeemedCount: admin.firestore.FieldValue.increment(1),
        }
      );

      return {
        ok: true,
        coupon: {
          title: coupon.title,
          discountType: coupon.discountType,
          discountValue: coupon.discountValue,
        },
      };
    });

    if (!result.ok) {
      throw new functions.https.HttpsError("failed-precondition", result.error);
    }

    return result;
  });

function verifyQRToken(token: string): { userId: string; couponId: string } {
  const [payloadB64, signature] = token.split(".");
  const payload = Buffer.from(payloadB64, "base64").toString();
  const [userId, couponId, timestamp] = payload.split(":");

  // 署名検証
  const crypto = require("crypto");
  const secret = process.env.COUPON_SECRET || "default-secret";
  const expectedSignature = crypto.createHmac("sha256", secret)
    .update(payload)
    .digest("hex")
    .substring(0, 16);

  if (signature !== expectedSignature) {
    throw new functions.https.HttpsError("invalid-argument", "Invalid token");
  }

  return { userId, couponId };
}
```

#### 4. `distributeCouponsAuto` (Scheduled)

```typescript
export const distributeCouponsAuto = functions
  .region(region)
  .pubsub.schedule("0 3 * * *")
  .timeZone("Asia/Tokyo")
  .onRun(async (context) => {
    const templates = await admin.firestore()
      .collection("couponTemplates")
      .where("distributionRules.autoDistribute", "==", true)
      .get();

    for (const templateDoc of templates.docs) {
      const template = templateDoc.data() as CouponTemplate;
      const conditions = template.distributionRules?.conditions || [];

      for (const condition of conditions) {
        let targetUsers: string[] = [];

        switch (condition.type) {
          case "birthday":
            // 今日誕生日のユーザー
            targetUsers = await findBirthdayUsers();
            break;
          case "points_threshold":
            // 一定ポイント達成ユーザー
            targetUsers = await findPointsThresholdUsers(condition.value);
            break;
          // ... 他の条件
        }

        // クーポン発行
        for (const userId of targetUsers) {
          await issueCouponToUserInternal(userId, templateDoc.id);
        }
      }
    }

    return null;
  });
```

#### 5. `cleanupExpiredCoupons` (Scheduled)

```typescript
export const cleanupExpiredCoupons = functions
  .region(region)
  .pubsub.schedule("0 4 * * *")
  .timeZone("Asia/Tokyo")
  .onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();

    // 期限切れかつactiveなクーポンを検索
    const expiredSnapshot = await admin.firestore()
      .collectionGroup("coupons")
      .where("status", "==", "active")
      .where("expiresAt", "<=", now)
      .get();

    const batch = admin.firestore().batch();

    expiredSnapshot.docs.forEach((doc) => {
      batch.update(doc.ref, { status: "expired" });
    });

    await batch.commit();

    functions.logger.info(`Marked ${expiredSnapshot.size} coupons as expired`);

    return null;
  });
```

## 🎨 Flutter実装方針

### ディレクトリ構造

```
lib/features/coupons/
├── domain/
│   └── models/
│       ├── coupon_template.dart
│       ├── user_coupon.dart
│       └── coupon_qr.dart
├── data/
│   └── repositories/
│       └── coupons_repository.dart   # 既存を強化
└── presentation/
    ├── providers/
    │   ├── coupons_list_provider.dart
    │   ├── coupon_detail_provider.dart
    │   └── coupon_qr_provider.dart
    ├── pages/
    │   ├── coupons_screen.dart       # 既存を強化
    │   └── coupon_detail_page.dart
    └── widgets/
        ├── coupon_card.dart
        ├── coupon_filter_chips.dart
        ├── coupon_qr_view.dart
        └── redeem_confirmation_sheet.dart
```

### Repository強化

```dart
class CouponsRepository {
  // 既存
  Stream<List<Coupon>> myCoupons(String userId, {CouponFilter filter});

  // 新規追加
  Future<CouponQR> generateQR(String couponId) async {
    final callable = functions.httpsCallable('generateCouponQR');
    final result = await callable.call({'couponId': couponId});
    return CouponQR.fromJson(result.data);
  }

  Future<void> redeemWithQR({
    required String qrToken,
    required String storeId,
    required String staffId,
    required String staffName,
  }) async {
    final callable = functions.httpsCallable('redeemCoupon');
    await callable.call({
      'qrToken': qrToken,
      'storeId': storeId,
      'staffId': staffId,
      'staffName': staffName,
    });
  }
}
```

### Widget: `coupon_qr_view.dart`

```dart
class CouponQRView extends ConsumerStatefulWidget {
  final UserCoupon coupon;

  const CouponQRView({super.key, required this.coupon});

  @override
  ConsumerState<CouponQRView> createState() => _CouponQRViewState();
}

class _CouponQRViewState extends ConsumerState<CouponQRView> {
  CouponQR? _qrData;
  Timer? _expiryTimer;
  int _remainingSeconds = 300;

  @override
  void initState() {
    super.initState();
    _generateQR();
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    super.dispose();
  }

  Future<void> _generateQR() async {
    try {
      final repo = ref.read(couponsRepositoryProvider);
      final qrData = await repo.generateQR(widget.coupon.id);

      setState(() {
        _qrData = qrData;
        _remainingSeconds = qrData.expiresIn;
      });

      // カウントダウンタイマー
      _expiryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _remainingSeconds--;
          if (_remainingSeconds <= 0) {
            timer.cancel();
            _qrData = null;
          }
        });
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('QRコード生成に失敗しました: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_qrData == null) {
      return Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _generateQR,
            child: const Text('QRコードを生成'),
          ),
        ],
      );
    }

    return Column(
      children: [
        // QRコード表示
        QrImageView(
          data: _qrData!.qrToken,
          version: QrVersions.auto,
          size: 250,
        ),
        const SizedBox(height: 16),
        Text(
          'クーポンコード: ${_qrData!.couponCode}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '残り時間: ${_formatTime(_remainingSeconds)}',
          style: TextStyle(
            fontSize: 16,
            color: _remainingSeconds < 60
                ? DesignTokens.error
                : DesignTokens.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          '店舗スタッフにこのQRコードを提示してください',
          style: TextStyle(
            fontSize: 14,
            color: DesignTokens.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
```

## 🧪 テスト戦略

### Unit Tests
- クーポンコード生成の一意性テスト
- QRトークン署名検証テスト
- 有効期限チェックロジックテスト

### Widget Tests
- クーポンカード表示テスト
- フィルタチップ動作テスト
- QRコードカウントダウンテスト

### Integration Tests
- クーポン発行から使用までのE2Eフロー
- QRコード生成と検証フロー
- 期限切れクーポンの自動更新

## 📦 CI/CD

`.github/workflows/epic3-ci.yml` (Epic 2と同様の構成)

## ✅ 受け入れ基準（DoD）

### 機能要件
- [ ] クーポン一覧が状態別に表示される
- [ ] QRコード生成が5秒以内に完了
- [ ] QRコードが5分で自動失効
- [ ] 二重利用が完全に防止される
- [ ] 期限切れクーポンが自動的にexpiredに更新
- [ ] 自動配布が条件マッチしたユーザーに実行される

### セキュリティ
- [ ] QRトークンに署名があり改ざん不可
- [ ] 店舗制限が正しく機能
- [ ] 管理者権限チェックが機能

### コード品質
- [ ] Test coverage > 80%
- [ ] QRライブラリ（qr_flutter）統合

## ⏱️ 工数見積り

**合計: 48時間（6日間）**

### フェーズ1: 基盤実装（2日 / 16h）
- データモデル＋ルール（6h）
- Cloud Functions（10h）

### フェーズ2: UI実装（2日 / 16h）
- Repository＋Provider（8h）
- QR生成Widget（8h）

### フェーズ3: テスト（2日 / 16h）
- Unit/Widget test（10h）
- Integration test（6h）
