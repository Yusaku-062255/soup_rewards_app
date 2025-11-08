import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

const region = "asia-northeast1";

/**
 * JST（日本標準時）の現在時刻を取得
 */
function nowJST(): Date {
  const nowUtc = Date.now();
  return new Date(nowUtc + 9 * 60 * 60 * 1000);
}

/**
 * YYYYMMDD形式の日付文字列をJST基準のDateオブジェクトに変換
 */
function parseDateYYYYMMDD(yyyymmdd: string): Date {
  const year = parseInt(yyyymmdd.substring(0, 4));
  const month = parseInt(yyyymmdd.substring(4, 6)) - 1;
  const day = parseInt(yyyymmdd.substring(6, 8));
  return new Date(year, month, day, 0, 0, 0, 0);
}

/**
 * DateオブジェクトをYYYYMMDD形式の文字列に変換（JST基準）
 */
function formatDateYYYYMMDD(date: Date): string {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, "0");
  const day = String(date.getDate()).padStart(2, "0");
  return `${year}${month}${day}`;
}

/**
 * ポイント追加（トランザクション内で使用）
 * 既存の addPointsInTransaction と同じシグネチャ
 */
async function addPointsInTransaction(
  tx: admin.firestore.Transaction,
  uid: string,
  type: "gacha" | "booking" | "manual" | "expire",
  delta: number,
  note: string,
  expiresAt?: admin.firestore.Timestamp
): Promise<void> {
  const db = admin.firestore();
  const userRef = db.collection("users").doc(uid);

  // 現在のポイントを取得
  const userSnap = await tx.get(userRef);
  if (!userSnap.exists) {
    throw new functions.https.HttpsError(
      "not-found",
      "user_not_found"
    );
  }

  const currentPoints = userSnap.data()?.totalPoints || 0;
  const newBalance = currentPoints + delta;

  if (newBalance < 0) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "insufficient_points"
    );
  }

  // ポイント更新
  tx.update(userRef, {
    totalPoints: newBalance,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // 付与の場合、1年後の有効期限を自動設定
  let finalExpiresAt = expiresAt;
  if (!finalExpiresAt && delta > 0) {
    const oneYearLater = new Date();
    oneYearLater.setFullYear(oneYearLater.getFullYear() + 1);
    finalExpiresAt = admin.firestore.Timestamp.fromDate(oneYearLater);
  }

  // pointLedger エントリを追加
  const ledgerRef = userRef.collection("pointLedger").doc();
  const ledgerData: Record<string, unknown> = {
    type,
    delta,
    balance: newBalance,
    note,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    expiredProcessed: false,
  };

  if (finalExpiresAt) {
    ledgerData.expiresAt = finalExpiresAt;
  }

  tx.set(ledgerRef, ledgerData);
}

/**
 * 空き状況を確認
 *
 * @param data { centerId: string, date: string (YYYYMMDD), serviceType: "wash" | "coating" }
 * @returns { ok: true, slots: [...] }
 */
export const listAvailableSlots = functions
  .region(region)
  .https.onCall(async (data, context) => {
    // 認証チェック
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "auth_required"
      );
    }

    const { centerId, date, serviceType } = data;

    // バリデーション
    if (!centerId || typeof centerId !== "string") {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "centerId_required"
      );
    }

    if (!date || !/^\d{8}$/.test(date)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "invalid_date_format"
      );
    }

    if (!serviceType || !["wash", "coating"].includes(serviceType)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "invalid_service_type"
      );
    }

    // 日付が過去でないかチェック（JST基準）
    const jstNow = nowJST();
    const jstNowDate = formatDateYYYYMMDD(jstNow);
    if (date < jstNowDate) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "past_date_not_allowed"
      );
    }

    // 日付が14日以内かチェック
    const targetDate = parseDateYYYYMMDD(date);
    const fourteenDaysLater = new Date(jstNow);
    fourteenDaysLater.setDate(jstNow.getDate() + 14);
    if (targetDate > fourteenDaysLater) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "date_too_far"
      );
    }

    const db = admin.firestore();

    // スロットを取得
    const slotsRef = db
      .collection("serviceCenters")
      .doc(centerId)
      .collection("days")
      .doc(date)
      .collection("slots");

    const slotsSnapshot = await slotsRef
      .where("serviceType", "==", serviceType)
      .orderBy("time", "asc")
      .get();

    const slots = slotsSnapshot.docs.map((doc) => {
      const data = doc.data();
      const capacity = data.capacity || 0;
      const reservedCount = data.reservedCount || 0;
      const available = capacity - reservedCount;

      return {
        id: doc.id,
        time: data.time,
        serviceType: data.serviceType,
        capacity,
        reservedCount,
        available,
        version: data.version || 1,
      };
    });

    return {
      ok: true,
      slots,
    };
  });

/**
 * 予約作成（楽観的ロック + トランザクション）
 *
 * @param data { centerId: string, slotId: string, date: string (YYYYMMDD), serviceType: string }
 * @returns { ok: true, bookingId: string }
 */
export const createBooking = functions
  .region(region)
  .https.onCall(async (data, context) => {
    // 認証チェック
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "auth_required"
      );
    }

    const uid = context.auth.uid;
    const { centerId, slotId, date, serviceType } = data;

    // バリデーション
    if (!centerId || typeof centerId !== "string") {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "centerId_required"
      );
    }

    if (!slotId || typeof slotId !== "string") {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "slotId_required"
      );
    }

    if (!date || !/^\d{8}$/.test(date)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "invalid_date_format"
      );
    }

    if (!serviceType || !["wash", "coating"].includes(serviceType)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "invalid_service_type"
      );
    }

    // 日付が過去でないかチェック（JST基準）
    const jstNow = nowJST();
    const jstNowDate = formatDateYYYYMMDD(jstNow);
    if (date < jstNowDate) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "past_date_not_allowed"
      );
    }

    const db = admin.firestore();

    // トランザクションで予約作成
    const result = await db.runTransaction(async (tx) => {
      const slotRef = db
        .collection("serviceCenters")
        .doc(centerId)
        .collection("days")
        .doc(date)
        .collection("slots")
        .doc(slotId);

      const slotSnap = await tx.get(slotRef);

      if (!slotSnap.exists) {
        throw new functions.https.HttpsError(
          "not-found",
          "slot_not_found"
        );
      }

      const slotData = slotSnap.data()!;
      const capacity = slotData.capacity || 0;
      const reservedCount = slotData.reservedCount || 0;
      const currentVersion = slotData.version || 1;

      // 空きがあるかチェック
      if (reservedCount >= capacity) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "slot_full"
        );
      }

      // serviceTypeが一致するかチェック
      if (slotData.serviceType !== serviceType) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "service_type_mismatch"
        );
      }

      // スロットを更新（楽観的ロック: versionをインクリメント）
      tx.update(slotRef, {
        reservedCount: reservedCount + 1,
        version: currentVersion + 1,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // 予約を作成
      const bookingRef = db.collection("bookings").doc();
      tx.set(bookingRef, {
        userId: uid,
        centerId,
        slotId,
        date,
        time: slotData.time,
        serviceType,
        status: "confirmed",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // ポイント付与（予約完了で50pt）
      await addPointsInTransaction(
        tx,
        uid,
        "booking",
        50,
        `予約完了: ${date} ${slotData.time}`
      );

      // totalBookings をインクリメント
      const userRef = db.collection("users").doc(uid);
      tx.update(userRef, {
        totalBookings: admin.firestore.FieldValue.increment(1),
      });

      return {
        ok: true,
        bookingId: bookingRef.id,
      };
    });

    console.log(`Booking created: ${result.bookingId} for user ${uid}`);
    return result;
  });

/**
 * 予約キャンセル
 *
 * @param data { bookingId: string }
 * @returns { ok: true }
 */
export const cancelBooking = functions
  .region(region)
  .https.onCall(async (data, context) => {
    // 認証チェック
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "auth_required"
      );
    }

    const uid = context.auth.uid;
    const { bookingId } = data;

    // バリデーション
    if (!bookingId || typeof bookingId !== "string") {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "bookingId_required"
      );
    }

    const db = admin.firestore();

    // トランザクションでキャンセル処理
    const result = await db.runTransaction(async (tx) => {
      const bookingRef = db.collection("bookings").doc(bookingId);
      const bookingSnap = await tx.get(bookingRef);

      if (!bookingSnap.exists) {
        throw new functions.https.HttpsError(
          "not-found",
          "booking_not_found"
        );
      }

      const bookingData = bookingSnap.data()!;

      // 本人確認
      if (bookingData.userId !== uid) {
        throw new functions.https.HttpsError(
          "permission-denied",
          "not_your_booking"
        );
      }

      // ステータス確認
      if (bookingData.status !== "confirmed") {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "already_cancelled"
        );
      }

      // 予約をキャンセル
      tx.update(bookingRef, {
        status: "cancelled",
        cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // スロットの予約数を減らす
      const slotRef = db
        .collection("serviceCenters")
        .doc(bookingData.centerId)
        .collection("days")
        .doc(bookingData.date)
        .collection("slots")
        .doc(bookingData.slotId);

      const slotSnap = await tx.get(slotRef);

      if (slotSnap.exists) {
        const slotData = slotSnap.data()!;
        const reservedCount = slotData.reservedCount || 0;
        const currentVersion = slotData.version || 1;

        tx.update(slotRef, {
          reservedCount: Math.max(0, reservedCount - 1),
          version: currentVersion + 1,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      return { ok: true };
    });

    console.log(`Booking cancelled: ${bookingId} by user ${uid}`);
    return result;
  });
