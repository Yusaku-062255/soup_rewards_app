# Epic 4: 予約システム（トランザクション強化）

## 🎯 ドメイン要件

### ユースケース

#### UC4-1: 予約可能スロットの確認
- **アクター**: ユーザー
- **前提条件**: ログイン済み
- **メインフロー**:
  1. ユーザーが予約画面を開く
  2. カレンダーで日付を選択
  3. システムは選択日のスロット一覧を表示（空き状況付き）
  4. ユーザーは時間帯を選択
  5. サービス種別を選択（洗車/コーティング/修理）
  6. 車両を選択
- **成功条件**: 正確な空き状況が表示される

#### UC4-2: 予約の作成
- **アクター**: ユーザー
- **前提条件**: 空きスロットが存在
- **メインフロー**:
  1. ユーザーが予約内容を確認
  2. 「予約を確定」をタップ
  3. システムはトランザクションでスロットを予約
  4. 成功時に+50ポイント付与
  5. 確認メールとOneSignal通知を送信
  6. 予約一覧に反映
- **代替フロー**:
  - 3a. スロットが満席 → エラーメッセージ、リトライ促進
  - 3b. トランザクション競合 → 自動リトライ（最大3回）
- **成功条件**: 予約が確定し、ポイントが付与される

#### UC4-3: 予約のキャンセル
- **アクター**: ユーザー
- **前提条件**: 確定済み予約を所持
- **メインフロー**:
  1. ユーザーが予約詳細を開く
  2. 「キャンセル」をタップ
  3. システムはキャンセル可否を判定
     - 24時間以上前: 無料キャンセル、ポイント全額返却
     - 24時間未満: キャンセル料発生、ポイント返却なし
  4. 確認ダイアログ表示
  5. システムはトランザクションで予約をキャンセル
  6. スロットの空き枠を1つ増やす
  7. 通知送信
- **成功条件**: 予約がキャンセルされ、スロットが解放される

#### UC4-4: リマインダー通知
- **アクター**: システム（日次バッチ）
- **前提条件**: 24時間後に予約がある
- **メインフロー**:
  1. 毎時00分にバッチ実行
  2. 24時間後の予約を検索
  3. OneSignal通知送信
  4. `reminderSent: true` に更新
- **成功条件**: 予約24時間前に通知が届く

#### UC4-5: No-Show処理
- **アクター**: システム（日次バッチ）
- **前提条件**: 予約時刻が30分経過
- **メインフロー**:
  1. 毎時30分にバッチ実行
  2. 予約時刻+30分経過かつ`status: 'confirmed'`の予約を検索
  3. `status: 'no_show'`に更新
  4. ポイントペナルティ（任意）
  5. 通知送信
- **成功条件**: No-Showが自動記録される

### 非機能要件

| 項目 | 要件 |
|------|------|
| **パフォーマンス** | 予約作成 < 2秒、スロット取得 < 1秒 |
| **可用性** | 99.9%（予約は重要オペレーション） |
| **整合性** | 楽観的ロックで競合を検知、リトライで解決 |
| **監視** | 予約成功率、競合率、No-Show率をGA4で追跡 |
| **セキュリティ** | 本人のみ予約/キャンセル可能、不正防止 |
| **スケーラビリティ** | ピーク時（週末午前）に1000予約/時間に耐える |

## 🗄️ データモデル

### `serviceCenters/{centerId}/days/{YYYYMMDD}/slots/{HHmm}`

```typescript
interface ServiceSlot {
  // 必須フィールド
  id: string;                       // 'HHmm' (例: '1030', '1400')
  centerId: string;                 // 'default', 'tokushima-main'
  date: string;                     // 'YYYY-MM-DD'

  // 時間帯
  startAt: Timestamp;               // 開始時刻
  endAt: Timestamp;                 // 終了時刻

  // キャパシティ管理
  capacity: number;                 // 最大予約数（例: 3）
  reservedCount: number;            // 現在の予約数
  version: number;                  // 楽観的ロック用バージョン

  // サービス情報
  availableServices: string[];      // ['wash', 'coating', 'repair']

  // 状態
  isActive: boolean;                // 有効/無効（臨時休業等）
  blockedReason?: string;           // 無効理由

  // メタデータ
  createdAt: Timestamp;
  updatedAt: Timestamp;
}
```

### `bookings/{bookingId}`

```typescript
interface Booking {
  // 必須フィールド
  id: string;
  userId: string;                   // 予約者
  centerId: string;                 // サービスセンター
  date: string;                     // 'YYYY-MM-DD'
  slotId: string;                   // 'HHmm'

  // 予約内容
  serviceType: 'wash' | 'coating' | 'repair' | 'inspection';
  vehicleId: string;                // 対象車両
  notes?: string;                   // 備考

  // 状態管理
  status: 'confirmed' | 'cancelled' | 'completed' | 'no_show';

  // キャンセル情報
  cancelledAt?: Timestamp;
  cancelReason?: string;
  cancelledBy?: 'user' | 'admin' | 'system';
  refundedPoints?: number;          // 返却ポイント

  // リマインダー
  reminderSent: boolean;            // リマインダー送信済みか
  reminderSentAt?: Timestamp;

  // ポイント
  pointsAwarded: number;            // 付与ポイント（通常50）

  // タイムスタンプ
  createdAt: Timestamp;
  updatedAt: Timestamp;
}
```

### `users/{userId}/bookingHistory/{historyId}`

```typescript
interface BookingHistory {
  bookingId: string;                // 元の予約ID
  action: 'created' | 'cancelled' | 'completed' | 'no_show';
  timestamp: Timestamp;
  metadata?: {
    reason?: string;
    refundedPoints?: number;
  };
}
```

### インデックス

```json
{
  "collectionGroup": "slots",
  "queryScope": "COLLECTION_GROUP",
  "fields": [
    { "fieldPath": "centerId", "order": "ASCENDING" },
    { "fieldPath": "date", "order": "ASCENDING" },
    { "fieldPath": "startAt", "order": "ASCENDING" }
  ]
},
{
  "collectionGroup": "bookings",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "userId", "order": "ASCENDING" },
    { "fieldPath": "status", "order": "ASCENDING" },
    { "fieldPath": "date", "order": "DESCENDING" }
  ]
},
{
  "collectionGroup": "bookings",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "status", "order": "ASCENDING" },
    { "fieldPath": "date", "order": "ASCENDING" },
    { "fieldPath": "slotId", "order": "ASCENDING" }
  ]
},
{
  "collectionGroup": "bookings",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "reminderSent", "order": "ASCENDING" },
    { "fieldPath": "date", "order": "ASCENDING" }
  ]
}
```

### TTL設定
- `bookingHistory`: 2年後に自動削除

## 🔐 Firestoreセキュリティルール

```javascript
// スロット：全認証ユーザー読み取り可、書き込みはFunctionsのみ
match /serviceCenters/{centerId}/days/{yyyymmdd}/slots/{slotId} {
  allow read: if isSignedIn();
  allow write: if false; // Functionsのみ
}

// 予約：本人のみ読み取り、作成/更新はFunctionsのみ
match /bookings/{bookingId} {
  allow read: if isSignedIn() && resource.data.userId == request.auth.uid;
  allow create, update: if false; // Functionsのみ
  allow delete: if false; // キャンセルもFunctions経由
}

// 予約履歴：本人のみ読み取り
match /users/{userId}/bookingHistory/{historyId} {
  allow read: if isOwner(userId);
  allow write: if false; // Functionsのみ
}
```

## ☁️ Cloud Functions API

### `functions/src/bookings.ts`

#### 1. `createBooking` (Callable, 既存を強化)

**入力**:
```typescript
{
  date: string,                     // 'YYYY-MM-DD'
  slotId: string,                   // 'HHmm'
  serviceType: string,
  vehicleId: string,
  notes?: string
}
```

**出力**:
```typescript
{
  ok: true,
  bookingId: string,
  pointsAwarded: number
}
```

**ロジック**（楽観的ロック + リトライ）:
```typescript
export const createBooking = functions
  .region(region)
  .https.onCall(async (data, context) => {
    const uid = context.auth?.uid;
    if (!uid) {
      throw new functions.https.HttpsError("unauthenticated", "Login required");
    }

    const { date, slotId, serviceType, vehicleId, notes } = data;

    const centerId = "default";
    const yyyymmdd = date.replace(/-/g, "");
    const slotRef = admin.firestore()
      .collection("serviceCenters").doc(centerId)
      .collection("days").doc(yyyymmdd)
      .collection("slots").doc(slotId);

    const bookingRef = admin.firestore().collection("bookings").doc();
    const userRef = admin.firestore().collection("users").doc(uid);

    // 楽観的ロック + リトライ（最大3回）
    let attempts = 0;
    const maxAttempts = 3;

    while (attempts < maxAttempts) {
      try {
        const result = await admin.firestore().runTransaction(async (tx) => {
          // 1. スロット読み取り
          const slotSnap = await tx.get(slotRef);
          if (!slotSnap.exists) {
            return { ok: false, error: "slot_not_found" };
          }

          const slot = slotSnap.data();
          const { capacity, reservedCount, version, isActive } = slot;

          // 2. 検証
          if (!isActive) {
            return { ok: false, error: "slot_inactive" };
          }

          if (reservedCount >= capacity) {
            return { ok: false, error: "slot_full" };
          }

          // 3. 予約作成
          tx.set(bookingRef, {
            userId: uid,
            centerId,
            date,
            slotId,
            serviceType,
            vehicleId,
            notes: notes || null,
            status: "confirmed",
            reminderSent: false,
            pointsAwarded: 50,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          // 4. スロット更新（楽観的ロック）
          tx.update(slotRef, {
            reservedCount: admin.firestore.FieldValue.increment(1),
            version: version + 1,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          // 5. ポイント付与
          await addPointsInTransaction(tx, uid, "booking", 50, "予約完了");

          // 6. ユーザー統計更新
          tx.update(userRef, {
            totalBookings: admin.firestore.FieldValue.increment(1),
          });

          // 7. 履歴記録
          const historyRef = userRef.collection("bookingHistory").doc();
          tx.set(historyRef, {
            bookingId: bookingRef.id,
            action: "created",
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
          });

          return { ok: true, bookingId: bookingRef.id };
        });

        if (!result.ok) {
          throw new functions.https.HttpsError("failed-precondition", result.error);
        }

        // GA4イベント
        logAnalyticsEvent("booking_created", {
          user_id: uid,
          service_type: serviceType,
          date,
          slot_id: slotId,
        });

        // OneSignal通知（バックグラウンド）
        sendBookingConfirmation(uid, date, slotId).catch(console.error);

        return { ok: true, bookingId: result.bookingId, pointsAwarded: 50 };

      } catch (error: any) {
        // トランザクション競合時にリトライ
        if (error.code === "aborted" || error.message.includes("contention")) {
          attempts++;
          functions.logger.warn(`Transaction conflict, retrying... (${attempts}/${maxAttempts})`);
          await new Promise((resolve) => setTimeout(resolve, 100 * attempts)); // Exponential backoff
          continue;
        }

        throw error;
      }
    }

    throw new functions.https.HttpsError("resource-exhausted", "Max retry attempts exceeded");
  });
```

#### 2. `cancelBooking` (Callable)

**入力**:
```typescript
{
  bookingId: string,
  reason?: string
}
```

**出力**:
```typescript
{
  ok: true,
  refundedPoints: number
}
```

**ロジック**:
```typescript
export const cancelBooking = functions
  .region(region)
  .https.onCall(async (data, context) => {
    const uid = context.auth?.uid;
    if (!uid) {
      throw new functions.https.HttpsError("unauthenticated", "Login required");
    }

    const { bookingId, reason } = data;

    const bookingRef = admin.firestore().collection("bookings").doc(bookingId);

    const result = await admin.firestore().runTransaction(async (tx) => {
      const bookingSnap = await tx.get(bookingRef);
      if (!bookingSnap.exists) {
        return { ok: false, error: "booking_not_found" };
      }

      const booking = bookingSnap.data();

      // 権限チェック
      if (booking.userId !== uid) {
        return { ok: false, error: "permission_denied" };
      }

      // 状態チェック
      if (booking.status !== "confirmed") {
        return { ok: false, error: "booking_not_confirmed" };
      }

      // キャンセル期限チェック（24時間前）
      const bookingDateTime = new Date(`${booking.date}T${booking.slotId.slice(0, 2)}:${booking.slotId.slice(2)}`);
      const now = new Date();
      const hoursUntilBooking = (bookingDateTime.getTime() - now.getTime()) / (1000 * 60 * 60);

      let refundedPoints = 0;
      if (hoursUntilBooking >= 24) {
        // 24時間以上前：全額返却
        refundedPoints = booking.pointsAwarded;
      } else {
        // 24時間未満：返却なし（キャンセル料）
        refundedPoints = 0;
      }

      // 予約キャンセル
      tx.update(bookingRef, {
        status: "cancelled",
        cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
        cancelReason: reason || "ユーザーによるキャンセル",
        cancelledBy: "user",
        refundedPoints,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // スロット空き枠を増やす
      const { centerId, date, slotId } = booking;
      const yyyymmdd = date.replace(/-/g, "");
      const slotRef = admin.firestore()
        .collection("serviceCenters").doc(centerId)
        .collection("days").doc(yyyymmdd)
        .collection("slots").doc(slotId);

      tx.update(slotRef, {
        reservedCount: admin.firestore.FieldValue.increment(-1),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // ポイント返却（あれば）
      if (refundedPoints > 0) {
        await addPointsInTransaction(
          tx,
          uid,
          "booking",
          refundedPoints,
          `予約キャンセル返却 (${date} ${slotId})`
        );
      }

      // 履歴記録
      const historyRef = admin.firestore()
        .collection("users").doc(uid)
        .collection("bookingHistory").doc();

      tx.set(historyRef, {
        bookingId,
        action: "cancelled",
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        metadata: {
          reason: reason || "ユーザーによるキャンセル",
          refundedPoints,
        },
      });

      return { ok: true, refundedPoints };
    });

    if (!result.ok) {
      throw new functions.https.HttpsError("failed-precondition", result.error);
    }

    // 通知
    sendCancellationNotification(uid, refundedPoints).catch(console.error);

    return result;
  });
```

#### 3. `sendBookingReminders` (Scheduled)

```typescript
export const sendBookingReminders = functions
  .region(region)
  .pubsub.schedule("0 * * * *") // 毎時00分
  .timeZone("Asia/Tokyo")
  .onRun(async (context) => {
    const now = new Date();
    const in24Hours = new Date(now.getTime() + 24 * 60 * 60 * 1000);

    const targetDate = in24Hours.toISOString().split("T")[0]; // 'YYYY-MM-DD'

    // 24時間後の予約を検索
    const bookingsSnapshot = await admin.firestore()
      .collection("bookings")
      .where("status", "==", "confirmed")
      .where("date", "==", targetDate)
      .where("reminderSent", "==", false)
      .get();

    const batch = admin.firestore().batch();

    for (const doc of bookingsSnapshot.docs) {
      const booking = doc.data();

      // リマインダー送信
      await sendReminderNotification(booking.userId, booking.date, booking.slotId);

      // reminderSent更新
      batch.update(doc.ref, {
        reminderSent: true,
        reminderSentAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();

    functions.logger.info(`Sent ${bookingsSnapshot.size} reminders`);

    return null;
  });
```

#### 4. `markNoShow` (Scheduled)

```typescript
export const markNoShow = functions
  .region(region)
  .pubsub.schedule("30 * * * *") // 毎時30分
  .timeZone("Asia/Tokyo")
  .onRun(async (context) => {
    const now = new Date();
    const thirtyMinutesAgo = new Date(now.getTime() - 30 * 60 * 1000);

    const today = now.toISOString().split("T")[0];

    // 30分以上経過した予約を検索
    const bookingsSnapshot = await admin.firestore()
      .collection("bookings")
      .where("status", "==", "confirmed")
      .where("date", "==", today)
      .get();

    const batch = admin.firestore().batch();
    let noShowCount = 0;

    for (const doc of bookingsSnapshot.docs) {
      const booking = doc.data();

      // 予約時刻を計算
      const bookingTime = new Date(
        `${booking.date}T${booking.slotId.slice(0, 2)}:${booking.slotId.slice(2)}:00`
      );

      if (bookingTime < thirtyMinutesAgo) {
        batch.update(doc.ref, {
          status: "no_show",
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // 履歴記録
        const historyRef = admin.firestore()
          .collection("users").doc(booking.userId)
          .collection("bookingHistory").doc();

        batch.set(historyRef, {
          bookingId: doc.id,
          action: "no_show",
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });

        noShowCount++;

        // 通知（バックグラウンド）
        sendNoShowNotification(booking.userId).catch(console.error);
      }
    }

    await batch.commit();

    functions.logger.info(`Marked ${noShowCount} bookings as no-show`);

    return null;
  });
```

## 🎨 Flutter実装方針

### Repository強化

```dart
class BookingRepository {
  // 既存
  Future<List<TimeSlot>> fetchSlots(DateTime date);
  Future<String> createBooking({...});

  // 新規
  Future<void> cancelBooking({
    required String bookingId,
    String? reason,
  }) async {
    final callable = functions.httpsCallable('cancelBooking');
    final result = await callable.call({
      'bookingId': bookingId,
      'reason': reason,
    });

    if (result.data['ok'] != true) {
      throw Exception(result.data['error']);
    }
  }

  Stream<List<Booking>> getMyBookings(String userId) {
    return firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .where('status', whereIn: ['confirmed', 'completed'])
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Booking.fromFirestore(doc.id, doc.data());
      }).toList();
    });
  }
}
```

### Widget: `booking_detail_page.dart`

```dart
class BookingDetailPage extends ConsumerWidget {
  final Booking booking;

  const BookingDetailPage({super.key, required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('予約詳細')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 予約情報
            _buildInfoCard(),
            const SizedBox(height: 16),

            // キャンセルボタン（24時間前まで無料）
            if (booking.status == 'confirmed')
              _buildCancelButton(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildCancelButton(BuildContext context, WidgetRef ref) {
    final bookingTime = DateTime.parse('${booking.date}T${booking.slotId}');
    final hoursUntil = bookingTime.difference(DateTime.now()).inHours;
    final isFreeCancel = hoursUntil >= 24;

    return ElevatedButton.icon(
      onPressed: () => _showCancelDialog(context, ref, isFreeCancel),
      icon: const Icon(CupertinoIcons.xmark_circle),
      label: Text(isFreeCancel ? 'キャンセル（無料）' : 'キャンセル（返金なし）'),
      style: ElevatedButton.styleFrom(
        backgroundColor: DesignTokens.error,
      ),
    );
  }

  Future<void> _showCancelDialog(
    BuildContext context,
    WidgetRef ref,
    bool isFreeCancel,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('予約をキャンセルしますか？'),
        content: Text(
          isFreeCancel
              ? '24時間以上前のため、ポイントは全額返却されます。'
              : '24時間未満のため、ポイントは返却されません。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('戻る'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: DesignTokens.error),
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final repo = ref.read(bookingRepositoryProvider);
        await repo.cancelBooking(bookingId: booking.id);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('予約をキャンセルしました')),
        );

        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('キャンセルに失敗しました: $e')),
        );
      }
    }
  }
}
```

## 🧪 テスト戦略

### Unit Tests
- 楽観的ロックの競合検知テスト
- キャンセルポリシーロジックテスト
- リトライメカニズムテスト

### Integration Tests
- 同時予約の競合解決テスト
- キャンセル→再予約のフローテスト
- リマインダー送信テスト

## 📦 CI/CD

`.github/workflows/epic4-ci.yml` (Epic 2/3と同様)

## ✅ 受け入れ基準（DoD）

### 機能要件
- [ ] スロット空き状況が正確に表示される
- [ ] 楽観的ロックで競合が検知される
- [ ] トランザクション競合時に自動リトライ（最大3回）
- [ ] 予約成功時に+50ポイント付与
- [ ] キャンセルポリシーが正しく適用される（24時間前後）
- [ ] リマインダーが24時間前に送信される
- [ ] No-Showが30分後に自動記録される

### 非機能要件
- [ ] 予約作成 < 2秒（P95）
- [ ] 競合発生率 < 5%（ピーク時）
- [ ] リトライ成功率 > 95%

### セキュリティ
- [ ] 本人のみ予約/キャンセル可能
- [ ] スロット書き込みはFunctionsのみ

## ⏱️ 工数見積り

**合計: 56時間（7日間）**

### フェーズ1: 基盤（2日 / 16h）
- データモデル＋ルール（6h）
- Cloud Functions（楽観的ロック）（10h）

### フェーズ2: UI（2日 / 16h）
- Repository＋Provider（8h）
- 予約詳細＋キャンセルUI（8h）

### フェーズ3: バッチ＋テスト（3日 / 24h）
- リマインダー＋No-Showバッチ（8h）
- Unit/Integration test（16h）
