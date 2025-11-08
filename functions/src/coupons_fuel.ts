import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as crypto from "crypto";

const region = "asia-northeast1";

/**
 * 8桁の英数字ランダムコードを生成
 */
function generateCouponCode(): string {
  const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"; // 紛らわしい文字を除外
  let code = "";
  for (let i = 0; i < 8; i++) {
    code += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return code;
}

/**
 * PINとsaltからハッシュを生成
 */
function hashPin(pin: string, salt: string): string {
  return crypto.createHash("sha256").update(pin + salt).digest("hex");
}

/**
 * 給油券テンプレートの初期化（idempotent）
 *
 * テンプレートが存在しない場合のみ作成します。
 * 運用での値変更はFirestore Consoleまたは管理用Functionsで実施。
 */
export const ensureFuelVoucherTemplate = functions
  .region(region)
  .https.onCall(async (_data, context) => {
    // 管理者チェック（本番環境では必須）
    // 開発中はコメントアウトしても可
    // if (!context.auth?.token?.admin) {
    //   throw new functions.https.HttpsError('permission-denied', 'Admin only');
    // }

    const db = admin.firestore();
    const templateId = "fuel_voucher_500yen";
    const templateRef = db.collection("couponTemplates").doc(templateId);

    const templateSnap = await templateRef.get();
    if (templateSnap.exists) {
      console.log(`Template ${templateId} already exists`);
      return { ok: true, message: "Template already exists", templateId };
    }

    await templateRef.set({
      title: "Fuel Voucher (ENEOS)",
      type: "flat_yen",
      discountValueYen: 500,
      pointsCost: 500,
      validityDays: 30,
      active: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`Template ${templateId} created`);
    return { ok: true, message: "Template created", templateId };
  });

/**
 * ポイント消費して給油券を発行
 *
 * トランザクション:
 * - ポイント残高チェック
 * - ポイント減算 & pointLedger 記録
 * - クーポン発行（code生成、有効期限設定）
 */
export const redeemPointsForFuelVoucher = functions
  .region(region)
  .https.onCall(async (data, context) => {
    const uid = context.auth?.uid;
    if (!uid) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Login required"
      );
    }

    const { templateId } = data;
    if (!templateId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "templateId is required"
      );
    }

    const db = admin.firestore();

    // テンプレート取得
    const templateRef = db.collection("couponTemplates").doc(templateId);
    const templateSnap = await templateRef.get();

    if (!templateSnap.exists) {
      throw new functions.https.HttpsError(
        "not-found",
        "Template not found"
      );
    }

    const template = templateSnap.data()!;
    if (!template.active) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Template is inactive"
      );
    }

    const pointsCost = template.pointsCost as number;
    const discountValueYen = template.discountValueYen as number;
    const validityDays = template.validityDays as number;

    // トランザクション実行
    const result = await db.runTransaction(async (tx) => {
      const userRef = db.collection("users").doc(uid);
      const userSnap = await tx.get(userRef);

      if (!userSnap.exists) {
        throw new functions.https.HttpsError(
          "not-found",
          "User not found"
        );
      }

      const currentPoints = userSnap.data()?.totalPoints || 0;

      // ポイント不足チェック
      if (currentPoints < pointsCost) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "insufficient_points"
        );
      }

      const newBalance = currentPoints - pointsCost;

      // ポイント減算
      tx.update(userRef, {
        totalPoints: newBalance,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // pointLedger 記録
      const ledgerRef = userRef.collection("pointLedger").doc();
      tx.set(ledgerRef, {
        type: "coupon",
        delta: -pointsCost,
        balance: newBalance,
        note: `Fuel Voucher (${discountValueYen}円)`,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        expiredProcessed: false,
      });

      // クーポン発行
      const couponRef = userRef.collection("coupons").doc();
      const code = generateCouponCode();
      const issuedAt = admin.firestore.Timestamp.now();
      const expiresAt = new admin.firestore.Timestamp(
        issuedAt.seconds + validityDays * 24 * 60 * 60,
        issuedAt.nanoseconds
      );

      tx.set(couponRef, {
        templateId,
        code,
        status: "active",
        issuedAt,
        expiresAt,
        meta: {
          discountValueYen,
          type: template.type,
          title: template.title,
        },
      });

      return {
        ok: true,
        couponId: couponRef.id,
        code,
        expiresAt: expiresAt.toDate(),
        discountValueYen,
      };
    });

    console.log(
      `Fuel voucher issued: uid=${uid}, couponId=${result.couponId}`
    );
    return result;
  });

/**
 * 店頭でスタッフPINを使ってクーポンを消込み
 *
 * 手順:
 * 1. スタッフPIN検証（ハッシュ比較）
 * 2. クーポン状態確認（owner, active, 有効期限）
 * 3. トランザクションで status を redeemed に更新
 */
export const redeemFuelVoucherAtStore = functions
  .region(region)
  .https.onCall(async (data, context) => {
    const uid = context.auth?.uid;
    if (!uid) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Login required"
      );
    }

    const { couponId, centerId, staffPin } = data;
    if (!couponId || !centerId || !staffPin) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "couponId, centerId, and staffPin are required"
      );
    }

    const db = admin.firestore();

    // スタッフPIN検証
    const settingsRef = db
      .collection("serviceCenters")
      .doc(centerId)
      .collection("settings")
      .doc("redeem");

    const settingsSnap = await settingsRef.get();
    if (!settingsSnap.exists) {
      throw new functions.https.HttpsError(
        "not-found",
        "Store settings not found"
      );
    }

    const settings = settingsSnap.data()!;
    const expectedHash = settings.redeemPinHash as string;
    const salt = settings.salt as string;

    const actualHash = hashPin(staffPin, salt);
    if (actualHash !== expectedHash) {
      console.warn(
        `Invalid staff PIN attempt: uid=${uid}, centerId=${centerId}`
      );
      throw new functions.https.HttpsError(
        "permission-denied",
        "invalid_staff_pin"
      );
    }

    // クーポン取得
    const couponRef = db
      .collection("users")
      .doc(uid)
      .collection("coupons")
      .doc(couponId);

    const result = await db.runTransaction(async (tx) => {
      const couponSnap = await tx.get(couponRef);

      if (!couponSnap.exists) {
        throw new functions.https.HttpsError(
          "not-found",
          "Coupon not found"
        );
      }

      const coupon = couponSnap.data()!;

      // ステータス確認
      if (coupon.status !== "active") {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "already_redeemed"
        );
      }

      // 有効期限確認
      const now = admin.firestore.Timestamp.now();
      const expiresAt = coupon.expiresAt as admin.firestore.Timestamp;
      if (now.seconds > expiresAt.seconds) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "expired"
        );
      }

      // クーポン消込み
      const redeemedAt = admin.firestore.FieldValue.serverTimestamp();
      tx.update(couponRef, {
        status: "redeemed",
        redeemedAt,
        redeemedBy: {
          centerId,
          staffId: "PIN", // PIN方式なのでスタッフIDは不明
        },
      });

      return {
        ok: true,
        redeemedAt: now.toDate(),
        discountValueYen: coupon.meta.discountValueYen,
      };
    });

    console.log(
      `Fuel voucher redeemed: uid=${uid}, couponId=${couponId}, centerId=${centerId}`
    );
    return result;
  });
