import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();
const region = "asia-northeast1";

// Export point expiration and stats functions
export * from "./points_expire";
export * from "./points_stats";

// Export coupon functions
export * from "./coupons_fuel";

// Export booking functions
export * from "./bookings_minimal";

// Export dev seed functions
export * from "./dev_seeds";

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
 * @param expiresAt 失効日時（オプション、1年後に自動設定）
 */
async function addPointsInTransaction(
  tx: admin.firestore.Transaction,
  uid: string,
  type: "gacha" | "booking" | "manual" | "expire",
  delta: number,
  note: string,
  expiresAt?: admin.firestore.Timestamp
): Promise<void> {
  const userRef = admin.firestore().collection("users").doc(uid);
  const ledgerRef = userRef.collection("pointLedger").doc();

  const userSnap = await tx.get(userRef);
  const currentTotal = userSnap.exists ? (userSnap.data()?.totalPoints || 0) : 0;
  const newTotal = currentTotal + delta;

  // users.totalPoints を更新
  tx.update(userRef, {
    totalPoints: newTotal,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // ポイント付与の場合、1年後に失効するように expiresAt を設定
  let finalExpiresAt = expiresAt;
  if (!finalExpiresAt && delta > 0) {
    const oneYearLater = new Date();
    oneYearLater.setFullYear(oneYearLater.getFullYear() + 1);
    finalExpiresAt = admin.firestore.Timestamp.fromDate(oneYearLater);
  }

  // pointLedger に記録
  const ledgerData: any = {
    type,
    delta,
    balance: newTotal,
    note,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    expiredProcessed: false, // 失効処理済みフラグ（初期値: false）
  };

  if (finalExpiresAt) {
    ledgerData.expiresAt = finalExpiresAt;
  }

  tx.set(ledgerRef, ledgerData);
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
 * ヘルスチェックエンドポイント
 * @param _req リクエスト
 * @param res レスポンス
 */
export const healthCheck = functions
  .region(region)
  .https.onRequest((_req, res) => {
    res.status(200).send({ ok: true, region });
  });
