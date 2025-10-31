import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();
const region = "asia-northeast1";

/**
 * JST（日本標準時）で今日の日付IDを取得
 * @returns YYYYMMDD形式の文字列（例: 20250131）
 */
function todayIdJST(): string {
  const nowUtc = Date.now();
  const jst = new Date(nowUtc + 9 * 60 * 60 * 1000);
  const y = jst.getUTCFullYear();
  const m = String(jst.getUTCMonth() + 1).padStart(2, "0");
  const d = String(jst.getUTCDate()).padStart(2, "0");
  return `${y}${m}${d}`;
}

/**
 * JST 00:00 までの残り秒数を計算
 * @returns 残り秒数
 */
function secondsUntilJSTMidnight(): number {
  const nowUtc = Date.now();
  const jstNow = new Date(nowUtc + 9 * 60 * 60 * 1000);
  const midnight = new Date(Date.UTC(
    jstNow.getUTCFullYear(),
    jstNow.getUTCMonth(),
    jstNow.getUTCDate() + 1,
    0, 0, 0, 0
  ));
  return Math.max(0, Math.floor((midnight.getTime() - (nowUtc + 9 * 60 * 60 * 1000)) / 1000));
}

/**
 * ポイント履歴を追加し、合計ポイントを更新
 * @param tx トランザクション
 * @param uid ユーザーID
 * @param type ポイント種別
 * @param delta ポイント増減量
 * @param note 備考
 */
async function addPointsInTransaction(
  tx: admin.firestore.Transaction,
  uid: string,
  type: "gacha" | "booking" | "manual",
  delta: number,
  note: string
): Promise<void> {
  const pointsRef = admin.firestore().collection("users").doc(uid).collection("points").doc("total");
  const ledgerRef = admin.firestore().collection("users").doc(uid).collection("pointLedger").doc();

  const pointsSnap = await tx.get(pointsRef);
  const currentTotal = pointsSnap.exists ? (pointsSnap.data()?.total || 0) : 0;
  const newTotal = currentTotal + delta;

  tx.set(pointsRef, {
    total: newTotal,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });

  tx.set(ledgerRef, {
    type,
    delta,
    note,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

/**
 * 毎日ガチャ実行（JST基準・トランザクション対応・ポイント付与）
 *
 * 仕様:
 * - 同一JST日に1回のみ実行可能
 * - トランザクションで重複防止
 * - gachaClaims コレクションに記録（YYYYMMDD形式のドキュメントID）
 * - 成功時に+10ポイント付与
 *
 * @param _data 未使用
 * @param context 認証コンテキスト
 * @returns { ok: boolean, reward?: object, reason?: string, resetInSeconds: number, dayId: string }
 */
export const claimDailyGacha = functions
  .region(region)
  .https.onCall(async (_data, context) => {
    const uid = context.auth?.uid;
    if (!uid) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Login required."
      );
    }

    const dayId = todayIdJST();
    const ref = admin
      .firestore()
      .collection("users")
      .doc(uid)
      .collection("gachaClaims")
      .doc(dayId);

    const res = await admin.firestore().runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      if (snap.exists) {
        return { ok: false as const, reason: "already_claimed" as const };
      }

      const pointAmount = 10;
      const reward = { type: "points", amount: pointAmount };

      tx.set(ref, {
        claimedAt: admin.firestore.FieldValue.serverTimestamp(),
        reward: reward.type,
      });

      // ポイント付与
      await addPointsInTransaction(tx, uid, "gacha", pointAmount, "デイリーガチャ");

      return { ok: true as const, reward };
    });

    return res.ok
      ? {
          ok: true,
          reward: res.reward,
          resetInSeconds: secondsUntilJSTMidnight(),
          dayId,
        }
      : {
          ok: false,
          reason: "already_claimed",
          resetInSeconds: secondsUntilJSTMidnight(),
          dayId,
        };
  });

/**
 * 予約作成（トランザクション対応・ポイント付与）
 *
 * 仕様:
 * - serviceCenters/{centerId}/days/{YYYYMMDD}/slots/{slotId} のキャパシティを確認
 * - 空きがあれば予約を作成し、reservedCountをインクリメント
 * - 成功時に+50ポイント付与
 *
 * @param data { date: 'YYYY-MM-DD', slotId: 'HHmm', serviceType: string, vehicleId: string }
 * @param context 認証コンテキスト
 * @returns { ok: boolean, bookingId?: string, error?: string }
 */
export const createBooking = functions
  .region(region)
  .https.onCall(async (data, context) => {
    const uid = context.auth?.uid;
    if (!uid) {
      throw new functions.https.HttpsError("unauthenticated", "Login required.");
    }

    const { date, slotId, serviceType, vehicleId } = data;
    if (!date || !slotId || !serviceType || !vehicleId) {
      throw new functions.https.HttpsError("invalid-argument", "Missing required fields.");
    }

    const centerId = "default";
    const yyyymmdd = date.replace(/-/g, "");
    const slotRef = admin
      .firestore()
      .collection("serviceCenters")
      .doc(centerId)
      .collection("days")
      .doc(yyyymmdd)
      .collection("slots")
      .doc(slotId);

    const bookingRef = admin.firestore().collection("bookings").doc();

    const result = await admin.firestore().runTransaction(async (tx) => {
      const slotSnap = await tx.get(slotRef);
      if (!slotSnap.exists) {
        return { ok: false, error: "slot_not_found" };
      }

      const slotData = slotSnap.data();
      const capacity = slotData?.capacity || 0;
      const reservedCount = slotData?.reservedCount || 0;

      if (reservedCount >= capacity) {
        return { ok: false, error: "slot_full" };
      }

      // 予約作成
      tx.set(bookingRef, {
        userId: uid,
        vehicleId,
        serviceType,
        date,
        slotId,
        centerId,
        status: "confirmed",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // スロットのreservedCountをインクリメント
      tx.update(slotRef, {
        reservedCount: admin.firestore.FieldValue.increment(1),
      });

      // ポイント付与
      await addPointsInTransaction(tx, uid, "booking", 50, "予約完了");

      return { ok: true, bookingId: bookingRef.id };
    });

    if (!result.ok) {
      throw new functions.https.HttpsError("failed-precondition", result.error || "Booking failed.");
    }

    return result;
  });

/**
 * クーポン使用（トランザクション対応）
 *
 * 仕様:
 * - users/{uid}/coupons/{couponId} を検証（所有者、期限内、未使用）
 * - トランザクションでstatus: 'redeemed' と redeemedAt を設定
 *
 * @param data { couponId: string }
 * @param context 認証コンテキスト
 * @returns { ok: boolean, error?: string }
 */
export const redeemCoupon = functions
  .region(region)
  .https.onCall(async (data, context) => {
    const uid = context.auth?.uid;
    if (!uid) {
      throw new functions.https.HttpsError("unauthenticated", "Login required.");
    }

    const { couponId } = data;
    if (!couponId) {
      throw new functions.https.HttpsError("invalid-argument", "couponId is required.");
    }

    const couponRef = admin.firestore().collection("users").doc(uid).collection("coupons").doc(couponId);

    const result = await admin.firestore().runTransaction(async (tx) => {
      const couponSnap = await tx.get(couponRef);
      if (!couponSnap.exists) {
        return { ok: false, error: "coupon_not_found" };
      }

      const couponData = couponSnap.data();
      if (couponData?.status !== "active") {
        return { ok: false, error: "coupon_not_active" };
      }

      const now = admin.firestore.Timestamp.now();
      const expiresAt = couponData?.expiresAt;
      if (expiresAt && expiresAt.toMillis() < now.toMillis()) {
        return { ok: false, error: "coupon_expired" };
      }

      // クーポンを使用済みに更新
      tx.update(couponRef, {
        status: "redeemed",
        redeemedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return { ok: true };
    });

    if (!result.ok) {
      throw new functions.https.HttpsError("failed-precondition", result.error || "Redeem failed.");
    }

    return result;
  });

/**
 * ヘルスチェックエンドポイント
 * @param _req リクエスト
 * @param res レスポンス
 */
export const healthCheck = functions
  .region(region)
  .https.onRequest((_req, res) => {
    res.status(200).send({ ok: true, region });
  });
