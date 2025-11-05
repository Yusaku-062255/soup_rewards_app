# Epic 2: ポイント台帳 & デイリーガチャ統合

## 🎯 ドメイン要件

### ユースケース

#### UC2-1: ポイント履歴の確認
- **アクター**: ユーザー
- **前提条件**: ログイン済み
- **メインフロー**:
  1. ユーザーがポイント画面を開く
  2. システムは直近50件の履歴を表示
  3. ユーザーはスクロールで過去の履歴を読み込む（無限スクロール）
  4. ユーザーはフィルタ（タイプ別、期間別）を適用できる
- **成功条件**: 全履歴が正確に表示される

#### UC2-2: デイリーガチャの実行
- **アクター**: ユーザー
- **前提条件**: ログイン済み、本日未実行
- **メインフロー**:
  1. ユーザーが「デイリーガチャ」ボタンをタップ
  2. システムは日次制限をチェック（JST基準）
  3. 抽選を実行し、ポイントを付与
  4. アニメーションで結果を表示
  5. ポイント台帳に記録
- **代替フロー**:
  - 2a. 本日既に実行済み → エラーメッセージとリセット時刻を表示
  - 3a. サーバーエラー → リトライ可能なエラーメッセージ
- **成功条件**: ポイントが正確に加算され、二重取得が防止される

#### UC2-3: ポイント有効期限の管理
- **アクター**: システム（日次バッチ）
- **前提条件**: JST 3:00に実行
- **メインフロー**:
  1. 1年前に付与されたポイントを検索
  2. 失効ポイントを台帳に記録（delta: -X）
  3. ユーザーの総ポイントから減算
  4. 失効通知をOneSignal経由で送信
- **成功条件**: 正確に失効し、ユーザーに通知される

#### UC2-4: 月次ポイントサマリーの表示
- **アクター**: ユーザー
- **前提条件**: ログイン済み
- **メインフロー**:
  1. ユーザーがポイント画面を開く
  2. システムは当月獲得ポイントを集計表示
  3. 前月との比較を表示
- **成功条件**: 集計が正確

### 非機能要件

| 項目 | 要件 |
|------|------|
| **パフォーマンス** | ガチャ実行 < 2秒、履歴取得 < 1秒 |
| **可用性** | 99.5%（Firebase依存） |
| **整合性** | トランザクションで二重取得を完全防止 |
| **監視** | ガチャ実行回数、エラー率、レイテンシをGA4で追跡 |
| **セキュリティ** | IP記録で不正検知、レート制限（1日1回厳守） |
| **スケーラビリティ** | 10万ユーザー同時アクセスに耐える |

## 🗄️ データモデル

### `users/{userId}/pointLedger/{entryId}`

```typescript
interface PointLedgerEntry {
  // 必須フィールド
  id: string;                       // Auto-generated
  type: 'gacha' | 'booking' | 'coupon_use' | 'referral' | 'manual' | 'expire';
  delta: number;                    // ±100, ±50, -10 (失効時マイナス)
  balance: number;                  // スナップショット残高（検証用）
  note: string;                     // "デイリーガチャ", "予約完了", "クーポン使用"
  createdAt: Timestamp;             // 作成日時（JST変換用）

  // 任意フィールド
  expiresAt?: Timestamp;            // 有効期限（1年後、失効時のみnull）
  relatedId?: string;               // 関連ID（bookingId, couponId等）
  metadata?: {                      // 拡張メタデータ
    ipAddress?: string;             // 不正検知用
    userAgent?: string;
    gachaResult?: string;           // 'reward_tier_1'
  };
}
```

### `users/{userId}/gachaClaims/{YYYYMMDD}`

```typescript
interface GachaClaim {
  claimedAt: Timestamp;             // 実行時刻
  reward: {
    type: 'points';
    amount: number;                 // 10, 20, 50, 100
    tier: 'common' | 'rare' | 'epic' | 'legendary';
  };
  ipAddress: string;                // 不正検知用
  userAgent?: string;
  resetInSeconds: number;           // 次回実行まで（返却用）
}
```

### `users/{userId}/pointsSummary/monthly_{YYYYMM}`

```typescript
interface MonthlyPointsSummary {
  month: string;                    // 'YYYYMM'
  totalEarned: number;              // 当月獲得
  totalSpent: number;               // 当月消費
  totalExpired: number;             // 当月失効
  transactionCount: number;         // 取引回数
  gachaCount: number;               // ガチャ実行回数
  lastUpdated: Timestamp;
}
```

### インデックス

```json
{
  "collectionGroup": "pointLedger",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "userId", "order": "ASCENDING" },
    { "fieldPath": "createdAt", "order": "DESCENDING" }
  ]
},
{
  "collectionGroup": "pointLedger",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "userId", "order": "ASCENDING" },
    { "fieldPath": "type", "order": "ASCENDING" },
    { "fieldPath": "createdAt", "order": "DESCENDING" }
  ]
},
{
  "collectionGroup": "pointLedger",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "expiresAt", "order": "ASCENDING" },
    { "fieldPath": "delta", "order": "ASCENDING" }
  ]
}
```

### TTL設定
- `gachaClaims/{YYYYMMDD}`: 90日後に自動削除（Cloud Schedulerで実装）
- `pointLedger`: 永続保存（法的記録要件）

## 🔐 Firestoreセキュリティルール

```javascript
// firestore.rules に追加

// ポイント台帳：読み取りのみ許可（書き込みはFunctionsのみ）
match /users/{userId}/pointLedger/{entryId} {
  allow read: if isOwner(userId);
  allow write: if false; // Functionsのみ
}

// ガチャ請求：読み取りのみ許可
match /users/{userId}/gachaClaims/{dayId} {
  allow read: if isOwner(userId);
  allow write: if false; // Functionsのみ
}

// 月次サマリー：読み取りのみ許可
match /users/{userId}/pointsSummary/{summaryId} {
  allow read: if isOwner(userId);
  allow write: if false; // Functionsのみ
}

// users/{userId} の totalPoints 更新もFunctionsのみ
match /users/{userId} {
  allow update: if isOwner(userId)
    && !request.resource.data.diff(resource.data).affectedKeys().hasAny(['totalPoints', 'totalGachaPlays']);
}
```

## ☁️ Cloud Functions API

### `functions/src/points.ts`

#### 1. `claimDailyGacha` (Callable, 既存を強化)

**入力**: なし（context.auth.uid から取得）

**出力**:
```typescript
{
  ok: true,
  reward: {
    type: 'points',
    amount: 10 | 20 | 50 | 100,
    tier: 'common' | 'rare' | 'epic' | 'legendary'
  },
  balance: number,              // 更新後の残高
  resetInSeconds: number,
  dayId: string
}
```

**エラー**:
```typescript
{
  ok: false,
  reason: 'already_claimed' | 'rate_limit' | 'server_error',
  resetInSeconds: number,
  dayId: string
}
```

**ロジック**:
```typescript
export const claimDailyGacha = functions
  .region(region)
  .https.onCall(async (data, context) => {
    const uid = context.auth?.uid;
    if (!uid) {
      throw new functions.https.HttpsError("unauthenticated", "Login required.");
    }

    // IP取得（不正検知用）
    const ipAddress = context.rawRequest.ip || 'unknown';
    const userAgent = context.rawRequest.headers['user-agent'];

    const dayId = todayIdJST();
    const gachaRef = admin.firestore()
      .collection("users").doc(uid)
      .collection("gachaClaims").doc(dayId);

    const pointsRef = admin.firestore()
      .collection("users").doc(uid)
      .collection("points").doc("total");

    const ledgerRef = admin.firestore()
      .collection("users").doc(uid)
      .collection("pointLedger").doc();

    const userRef = admin.firestore().collection("users").doc(uid);

    const result = await admin.firestore().runTransaction(async (tx) => {
      // 1. 既に実行済みかチェック
      const gachaSnap = await tx.get(gachaRef);
      if (gachaSnap.exists) {
        return { ok: false as const, reason: "already_claimed" as const };
      }

      // 2. 抽選実行
      const reward = drawGachaReward();

      // 3. 現在のポイント取得
      const pointsSnap = await tx.get(pointsRef);
      const currentTotal = pointsSnap.exists ? (pointsSnap.data()?.total || 0) : 0;
      const newTotal = currentTotal + reward.amount;

      // 4. ガチャ請求記録
      tx.set(gachaRef, {
        claimedAt: admin.firestore.FieldValue.serverTimestamp(),
        reward,
        ipAddress,
        userAgent,
        resetInSeconds: secondsUntilJSTMidnight(),
      });

      // 5. ポイント更新
      tx.set(pointsRef, {
        total: newTotal,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });

      // 6. 台帳記録（有効期限1年後）
      const now = admin.firestore.Timestamp.now();
      const expiresAt = admin.firestore.Timestamp.fromMillis(
        now.toMillis() + 365 * 24 * 60 * 60 * 1000
      );

      tx.set(ledgerRef, {
        type: "gacha",
        delta: reward.amount,
        balance: newTotal,
        note: `デイリーガチャ (${reward.tier})`,
        expiresAt,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        metadata: {
          ipAddress,
          userAgent,
          gachaResult: reward.tier,
        },
      });

      // 7. ユーザー統計更新
      tx.update(userRef, {
        totalPoints: newTotal,
        totalGachaPlays: admin.firestore.FieldValue.increment(1),
        lastLoginAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return { ok: true as const, reward, balance: newTotal };
    });

    if (!result.ok) {
      return {
        ok: false,
        reason: result.reason,
        resetInSeconds: secondsUntilJSTMidnight(),
        dayId,
      };
    }

    // GA4イベント送信
    logAnalyticsEvent('gacha_claimed', {
      user_id: uid,
      reward_amount: result.reward.amount,
      reward_tier: result.reward.tier,
      balance: result.balance,
    });

    return {
      ok: true,
      reward: result.reward,
      balance: result.balance,
      resetInSeconds: secondsUntilJSTMidnight(),
      dayId,
    };
  });

/**
 * ガチャ抽選ロジック
 */
function drawGachaReward(): { type: 'points'; amount: number; tier: string } {
  const rand = Math.random() * 100;

  if (rand < 60) {
    // 60% - Common (10pt)
    return { type: 'points', amount: 10, tier: 'common' };
  } else if (rand < 90) {
    // 30% - Rare (20pt)
    return { type: 'points', amount: 20, tier: 'rare' };
  } else if (rand < 98) {
    // 8% - Epic (50pt)
    return { type: 'points', amount: 50, tier: 'epic' };
  } else {
    // 2% - Legendary (100pt)
    return { type: 'points', amount: 100, tier: 'legendary' };
  }
}
```

#### 2. `expirePoints` (Scheduled, 日次バッチ)

**トリガー**: 毎日 JST 3:00

**ロジック**:
```typescript
export const expirePoints = functions
  .region(region)
  .pubsub.schedule("0 3 * * *")
  .timeZone("Asia/Tokyo")
  .onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();

    // 有効期限切れのポイントを検索
    const expiredSnapshot = await admin.firestore()
      .collectionGroup("pointLedger")
      .where("expiresAt", "<=", now)
      .where("delta", ">", 0) // 獲得ポイントのみ
      .get();

    // ユーザーごとにグループ化
    const userExpiredPoints = new Map<string, number>();

    expiredSnapshot.docs.forEach((doc) => {
      const userId = doc.ref.parent.parent!.id;
      const delta = doc.data().delta as number;
      userExpiredPoints.set(
        userId,
        (userExpiredPoints.get(userId) || 0) + delta
      );
    });

    // ユーザーごとに失効処理
    const batch = admin.firestore().batch();
    const userIds: string[] = [];

    for (const [userId, expiredAmount] of userExpiredPoints.entries()) {
      const userRef = admin.firestore().collection("users").doc(userId);
      const pointsRef = userRef.collection("points").doc("total");
      const ledgerRef = userRef.collection("pointLedger").doc();

      // ポイント減算
      batch.update(pointsRef, {
        total: admin.firestore.FieldValue.increment(-expiredAmount),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // 台帳に失効記録
      batch.set(ledgerRef, {
        type: "expire",
        delta: -expiredAmount,
        balance: 0, // 後で計算
        note: `ポイント失効 (${expiredAmount}pt)`,
        expiresAt: null,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // ユーザー統計更新
      batch.update(userRef, {
        totalPoints: admin.firestore.FieldValue.increment(-expiredAmount),
      });

      userIds.push(userId);
    }

    await batch.commit();

    // OneSignal通知送信（バッチ処理）
    for (const userId of userIds) {
      const expiredAmount = userExpiredPoints.get(userId)!;
      await sendExpirationNotification(userId, expiredAmount);
    }

    functions.logger.info(`Expired points for ${userIds.length} users`);

    return null;
  });
```

#### 3. `addPointsManually` (Callable, 管理者専用)

**入力**:
```typescript
{
  targetUserId: string,
  amount: number,         // ±1000 範囲
  note: string,
  reason: 'bonus' | 'compensation' | 'refund' | 'adjustment'
}
```

**権限チェック**: `context.auth.token.admin === true`

**出力**:
```typescript
{
  ok: true,
  newBalance: number
}
```

### `functions/src/analytics.ts`

#### 4. `logAnalyticsEvent` (Helper)

```typescript
import { getAnalytics } from "firebase-admin/analytics";

export function logAnalyticsEvent(
  eventName: string,
  params: Record<string, any>
): void {
  // GA4イベント送信
  // 実装は Firebase Admin SDK の analytics を使用
}
```

## 🎨 Flutter実装方針

### ディレクトリ構造

```
lib/features/points/
├── domain/
│   └── models/
│       ├── point_ledger_entry.dart       # freezed
│       ├── gacha_claim.dart              # freezed
│       └── monthly_summary.dart          # freezed
├── data/
│   └── repositories/
│       └── points_repository.dart        # 既存を強化
└── presentation/
    ├── providers/
    │   ├── points_ledger_provider.dart   # ページネーション対応
    │   ├── gacha_state_provider.dart
    │   └── monthly_summary_provider.dart
    ├── pages/
    │   ├── points_screen.dart            # 既存を強化
    │   └── points_history_page.dart      # 新規（詳細履歴）
    └── widgets/
        ├── gacha_button.dart             # アニメーション付き
        ├── gacha_result_dialog.dart      # 結果表示
        ├── points_ledger_list.dart       # 無限スクロール
        ├── ledger_entry_tile.dart
        ├── monthly_chart.dart            # グラフ表示
        └── points_filter_sheet.dart      # フィルタ
```

### Repository強化: `points_repository.dart`

```dart
class PointsRepository {
  // 既存メソッド
  Stream<int> totalPoints(String userId);
  Future<GachaResult> claimDailyGacha();

  // 新規追加
  /// ポイント履歴をページネーションで取得
  Future<List<PointLedgerEntry>> fetchLedgerPaged({
    required String userId,
    int limit = 20,
    DocumentSnapshot? lastDoc,
    String? typeFilter,
  }) async {
    Query<Map<String, dynamic>> query = firestore
        .collection('users')
        .doc(userId)
        .collection('pointLedger')
        .orderBy('createdAt', descending: true);

    if (typeFilter != null) {
      query = query.where('type', isEqualTo: typeFilter);
    }

    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    query = query.limit(limit);

    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      return PointLedgerEntry.fromFirestore(doc);
    }).toList();
  }

  /// 月次サマリー取得
  Future<MonthlySummary> fetchMonthlySummary({
    required String userId,
    required String monthId, // 'YYYYMM'
  }) async {
    final doc = await firestore
        .collection('users')
        .doc(userId)
        .collection('pointsSummary')
        .doc('monthly_$monthId')
        .get();

    if (!doc.exists) {
      return MonthlySummary.empty(monthId);
    }

    return MonthlySummary.fromFirestore(doc);
  }

  /// 当月の獲得ポイント（リアルタイム集計）
  Future<int> getCurrentMonthEarned(String userId) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    final snapshot = await firestore
        .collection('users')
        .doc(userId)
        .collection('pointLedger')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('delta', isGreaterThan: 0)
        .get();

    return snapshot.docs.fold<int>(0, (sum, doc) {
      return sum + (doc.data()['delta'] as int? ?? 0);
    });
  }
}
```

### Provider: `gacha_state_provider.dart`

```dart
@freezed
class GachaState with _$GachaState {
  const factory GachaState.initial() = _Initial;
  const factory GachaState.loading() = _Loading;
  const factory GachaState.success(GachaResult result) = _Success;
  const factory GachaState.alreadyClaimed({
    required int resetInSeconds,
    required String dayId,
  }) = _AlreadyClaimed;
  const factory GachaState.error(String message) = _Error;
}

class GachaStateNotifier extends StateNotifier<GachaState> {
  final PointsRepository repository;

  GachaStateNotifier(this.repository) : super(const GachaState.initial());

  Future<void> claimGacha() async {
    state = const GachaState.loading();

    try {
      final result = await repository.claimDailyGacha();

      if (result.ok) {
        state = GachaState.success(result);

        // 3秒後にリセット
        await Future.delayed(const Duration(seconds: 3));
        state = const GachaState.initial();
      } else {
        state = GachaState.alreadyClaimed(
          resetInSeconds: result.resetInSeconds,
          dayId: result.dayId,
        );
      }
    } catch (e) {
      state = GachaState.error(e.toString());
    }
  }
}

final gachaStateProvider = StateNotifierProvider<GachaStateNotifier, GachaState>((ref) {
  final repo = ref.watch(pointsRepositoryProvider);
  return GachaStateNotifier(repo);
});
```

### Widget: `gacha_button.dart`

```dart
class GachaButton extends ConsumerWidget {
  const GachaButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gachaState = ref.watch(gachaStateProvider);

    return gachaState.when(
      initial: () => ElevatedButton.icon(
        onPressed: () => ref.read(gachaStateProvider.notifier).claimGacha(),
        icon: const Icon(CupertinoIcons.gift_fill),
        label: const Text('デイリーガチャを回す'),
        style: ElevatedButton.styleFrom(
          backgroundColor: DesignTokens.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: 32,
            vertical: 16,
          ),
        ),
      ),
      loading: () => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 8),
            Text('抽選中...'),
          ],
        ),
      ),
      success: (result) {
        // アニメーションダイアログを表示
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => GachaResultDialog(result: result),
          );
        });
        return const SizedBox.shrink();
      },
      alreadyClaimed: (resetInSeconds, dayId) {
        final hours = (resetInSeconds / 3600).ceil();
        return Column(
          children: [
            const Icon(
              CupertinoIcons.checkmark_circle_fill,
              size: 64,
              color: DesignTokens.success,
            ),
            const SizedBox(height: 16),
            Text(
              '本日は既に受け取り済みです',
              style: TextStyle(
                fontSize: 16,
                color: DesignTokens.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'リセットまで約 $hours 時間',
              style: const TextStyle(
                fontSize: 14,
                color: DesignTokens.textSecondary,
              ),
            ),
          ],
        );
      },
      error: (message) => Column(
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_triangle,
            size: 48,
            color: DesignTokens.error,
          ),
          const SizedBox(height: 8),
          Text(
            'エラーが発生しました',
            style: const TextStyle(color: DesignTokens.error),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => ref.read(gachaStateProvider.notifier).claimGacha(),
            child: const Text('リトライ'),
          ),
        ],
      ),
    );
  }
}
```

### Widget: `gacha_result_dialog.dart`

```dart
class GachaResultDialog extends StatefulWidget {
  final GachaResult result;

  const GachaResultDialog({super.key, required this.result});

  @override
  State<GachaResultDialog> createState() => _GachaResultDialogState();
}

class _GachaResultDialogState extends State<GachaResultDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 2 * 3.14159).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusBottomSheet),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spaceHeading),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // アニメーション
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Transform.rotate(
                    angle: _rotationAnimation.value,
                    child: Icon(
                      CupertinoIcons.gift_fill,
                      size: 100,
                      color: _getTierColor(widget.result.reward.tier),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: DesignTokens.spaceSection),
            Text(
              _getTierLabel(widget.result.reward.tier),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _getTierColor(widget.result.reward.tier),
              ),
            ),
            const SizedBox(height: DesignTokens.spaceSmall),
            Text(
              '+${widget.result.reward.amount} pt',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: DesignTokens.primary,
              ),
            ),
            const SizedBox(height: DesignTokens.spaceSmall),
            Text(
              '現在の残高: ${widget.result.balance} pt',
              style: const TextStyle(
                fontSize: 16,
                color: DesignTokens.textSecondary,
              ),
            ),
            const SizedBox(height: DesignTokens.spaceSection),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('閉じる'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTierColor(String tier) {
    switch (tier) {
      case 'legendary':
        return const Color(0xFFFFD700); // Gold
      case 'epic':
        return const Color(0xFF9B59B6); // Purple
      case 'rare':
        return const Color(0xFF3498DB); // Blue
      default:
        return DesignTokens.textSecondary;
    }
  }

  String _getTierLabel(String tier) {
    switch (tier) {
      case 'legendary':
        return '🎉 レジェンダリー！';
      case 'epic':
        return '✨ エピック！';
      case 'rare':
        return '⭐ レア！';
      default:
        return 'コモン';
    }
  }
}
```

## 🧪 テスト戦略

### Unit Tests

#### `test/features/points/data/repositories/points_repository_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

void main() {
  group('PointsRepository', () {
    test('fetchLedgerPaged returns paginated results', () async {
      // Mock Firestore
      // Verify pagination works correctly
    });

    test('claimDailyGacha prevents double claim', () async {
      // Mock transaction
      // Verify second call fails
    });

    test('getCurrentMonthEarned calculates correctly', () async {
      // Mock data for current month
      // Verify sum is correct
    });
  });
}
```

### Widget Tests

#### `test/features/points/presentation/widgets/gacha_button_test.dart`

```dart
void main() {
  testWidgets('GachaButton shows initial state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: GachaButton(),
          ),
        ),
      ),
    );

    expect(find.text('デイリーガチャを回す'), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.gift_fill), findsOneWidget);
  });

  testWidgets('GachaButton shows loading state', (tester) async {
    // Mock loading state
    // Verify CircularProgressIndicator is shown
  });

  testWidgets('GachaButton shows result dialog', (tester) async {
    // Mock success state
    // Verify dialog is displayed
  });
}
```

### Integration Tests

#### `integration_test/epic2_points_gacha_test.dart`

```dart
void main() {
  testWidgets('Complete gacha flow', (tester) async {
    // 1. Launch app and navigate to Points screen
    // 2. Tap gacha button
    // 3. Verify loading state
    // 4. Verify result dialog
    // 5. Close dialog
    // 6. Verify points updated in ledger
  });

  testWidgets('Double claim prevention', (tester) async {
    // 1. Claim gacha
    // 2. Try to claim again
    // 3. Verify error message
  });
}
```

### 疑似データ（Firestore Emulator用）

```json
{
  "users": {
    "testUser123": {
      "totalPoints": 150,
      "pointLedger": {
        "entry1": {
          "type": "gacha",
          "delta": 10,
          "balance": 10,
          "note": "デイリーガチャ",
          "createdAt": "2025-01-01T00:00:00Z",
          "expiresAt": "2026-01-01T00:00:00Z"
        },
        "entry2": {
          "type": "booking",
          "delta": 50,
          "balance": 60,
          "note": "予約完了",
          "createdAt": "2025-01-02T00:00:00Z",
          "expiresAt": "2026-01-02T00:00:00Z"
        }
      }
    }
  }
}
```

## 📦 CI/CD

### `.github/workflows/epic2-ci.yml`

```yaml
name: Epic 2 CI - Points & Gacha

on:
  pull_request:
    branches: [develop]
    paths:
      - 'lib/features/points/**'
      - 'functions/src/points.ts'
      - 'functions/src/analytics.ts'

jobs:
  test-functions:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
          cache-dependency-path: functions/package-lock.json

      - name: Install dependencies
        run: cd functions && npm ci

      - name: Start Firestore Emulator
        run: |
          npm install -g firebase-tools
          firebase emulators:start --only firestore &
          sleep 5

      - name: Run tests with emulator
        run: cd functions && npm test
        env:
          FIRESTORE_EMULATOR_HOST: localhost:8080

    timeout-minutes: 10

  test-flutter:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
          cache: true

      - name: Install dependencies
        run: flutter pub get

      - name: Run code generation
        run: flutter pub run build_runner build --delete-conflicting-outputs

      - name: Analyze
        run: flutter analyze lib/features/points

      - name: Run unit tests
        run: flutter test test/features/points --coverage

      - name: Run widget tests
        run: flutter test test/features/points/presentation

      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage/lcov.info
          flags: points

    timeout-minutes: 15

  integration-test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
          cache: true

      - name: Install dependencies
        run: flutter pub get

      - name: Start iOS Simulator
        run: |
          xcrun simctl boot "iPhone 15" || true
          sleep 10

      - name: Run integration tests
        run: flutter test integration_test/epic2_points_gacha_test.dart

    timeout-minutes: 20
```

## ✅ 受け入れ基準（DoD）

### 機能要件
- [ ] デイリーガチャが1日1回（JST基準）のみ実行可能
- [ ] ガチャ実行時にポイントが正確に加算される
- [ ] 抽選確率が仕様通り（Common 60%, Rare 30%, Epic 8%, Legendary 2%）
- [ ] 二重取得が完全に防止される（トランザクション検証）
- [ ] ポイント履歴が正確に記録される（balance スナップショット含む）
- [ ] 無限スクロールで過去の履歴を遡れる
- [ ] タイプ別フィルタが機能する
- [ ] 当月獲得ポイントが正確に集計される
- [ ] 1年後にポイントが自動失効する
- [ ] 失効時にOneSignal通知が送信される

### 非機能要件
- [ ] ガチャ実行レスポンスタイム < 2秒（P95）
- [ ] 履歴取得レスポンスタイム < 1秒（P95）
- [ ] 10万ユーザー同時アクセスでエラー率 < 0.1%
- [ ] トランザクション競合時に適切にリトライ
- [ ] IP記録で不正検知の基盤が整う

### コード品質
- [ ] Dart analyze でエラー0件
- [ ] Unit test カバレッジ > 80%
- [ ] Widget test で主要UIをカバー
- [ ] Integration test でE2Eフローをカバー
- [ ] Freezed でイミュータブルモデル
- [ ] Riverpod で状態管理

### セキュリティ
- [ ] Firestoreルールで書き込みをFunctionsに制限
- [ ] IP記録で不正検知に備える
- [ ] レート制限が機能する（1日1回厳守）
- [ ] 管理者権限チェックが機能する（addPointsManually）

### ドキュメント
- [ ] README更新（ガチャ機能説明）
- [ ] API仕様書更新
- [ ] Firestoreスキーマ図更新

### デプロイ
- [ ] Cloud Functions正常デプロイ
- [ ] Firestoreルール正常デプロイ
- [ ] Firestore Indexes作成完了
- [ ] Cloud Scheduler設定完了（expirePoints）
- [ ] iOS実機で動作確認

## ⏱️ 工数見積りと段階的リリース

### フェーズ1: 基盤実装（3日間 / 24時間）
- **Day 1**: データモデル＋Firestoreルール（8h）
  - `pointLedger`, `gachaClaims`, `pointsSummary` スキーマ定義
  - セキュリティルール実装
  - インデックス作成
- **Day 2**: Cloud Functions実装（10h）
  - `claimDailyGacha` 強化（トランザクション、IP記録）
  - `expirePoints` 日次バッチ
  - `drawGachaReward` 抽選ロジック
- **Day 3**: Unit test（6h）
  - Functions unit test
  - Repository unit test

**リリース判定**: Functions単体で動作確認

### フェーズ2: Flutter UI実装（2日間 / 16時間）
- **Day 4**: Repository＋Provider（8h）
  - `PointsRepository` 強化（ページネーション）
  - `GachaStateNotifier` 実装
  - `MonthlySum​​maryProvider` 実装
- **Day 5**: Widget実装（8h）
  - `GachaButton` + アニメーション
  - `GachaResultDialog`
  - `PointsLedgerList` 無限スクロール

**リリース判定**: iOS実機で動作確認

### フェーズ3: テスト＋最適化（2日間 / 12時間）
- **Day 6**: Widget/Integration test（6h）
  - Widget test実装
  - Integration test実装
- **Day 7**: パフォーマンス最適化＋バグ修正（6h）
  - レスポンスタイム測定
  - メモリリーク確認
  - Firestore読み取り最適化

**リリース判定**: 全テスト通過、DoD達成

### 最小スライス優先順位

#### MVP（Minimum Viable Product）
1. ✅ デイリーガチャ実行（二重防止）
2. ✅ ポイント履歴表示（直近50件）
3. ✅ 当月獲得ポイント表示

#### 次点機能
4. 無限スクロール（ページネーション）
5. タイプ別フィルタ
6. 月次サマリー

#### 将来機能
7. ポイント有効期限管理（日次バッチ）
8. 失効通知（OneSignal）
9. 管理者手動ポイント付与

### 総工数
**合計: 52時間（約7日間）**

---

**次のステップ**: Epic 3（クーポン）と Epic 4（予約）の設計を進めます。
