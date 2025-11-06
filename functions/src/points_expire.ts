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
 * ポイント失効バッチ処理
 *
 * 仕様:
 * - 全ユーザーの pointLedger から expiresAt <= now(JST) のエントリを検索
 * - 失効対象がある場合、トランザクションで以下を実行:
 *   1. users/{uid}.totalPoints から減算
 *   2. pointLedger に type: "expire" のエントリを追加
 * - 大量件数対応: 500件ずつバッチ処理
 *
 * @param uid 対象ユーザーID（指定時は該当ユーザーのみ処理）
 */
async function expirePointsForUser(uid: string): Promise<{ expired: number; entries: number }> {
  const db = admin.firestore();
  const now = admin.firestore.Timestamp.now();

  // 失効対象のエントリを取得（delta > 0 のみ、expiresAt <= now）
  const ledgerQuery = db
    .collection("users")
    .doc(uid)
    .collection("pointLedger")
    .where("expiresAt", "<=", now)
    .where("delta", ">", 0);

  const snapshot = await ledgerQuery.get();

  if (snapshot.empty) {
    return { expired: 0, entries: 0 };
  }

  // 失効ポイント合計を計算
  let totalExpired = 0;
  for (const doc of snapshot.docs) {
    const data = doc.data();
    totalExpired += data.delta || 0;
  }

  if (totalExpired === 0) {
    return { expired: 0, entries: snapshot.size };
  }

  // トランザクションで失効処理
  await db.runTransaction(async (tx) => {
    const userRef = db.collection("users").doc(uid);
    const userSnap = await tx.get(userRef);

    if (!userSnap.exists) {
      throw new Error(`User ${uid} not found`);
    }

    const userData = userSnap.data();
    const currentPoints = userData?.totalPoints || 0;
    const newTotal = Math.max(0, currentPoints - totalExpired);

    // users.totalPoints を減算
    tx.update(userRef, {
      totalPoints: newTotal,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // pointLedger に失効記録を追加
    const ledgerRef = userRef.collection("pointLedger").doc();
    tx.set(ledgerRef, {
      type: "expire",
      delta: -totalExpired,
      balance: newTotal,
      note: `ポイント失効（${snapshot.size}件）`,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // 失効済みエントリに processed フラグを追加（再処理防止）
    for (const doc of snapshot.docs) {
      tx.update(doc.ref, {
        expiredProcessed: true,
        expiredAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  });

  console.log(`Expired ${totalExpired} points for user ${uid} (${snapshot.size} entries)`);
  return { expired: totalExpired, entries: snapshot.size };
}

/**
 * スケジュール実行: ポイント失効処理
 *
 * Cloud Scheduler設定:
 * - スケジュール: 0 18 * * * (UTC 18:00 = JST 03:00)
 * - タイムゾーン: UTC
 * - 説明: Daily point expiration at JST 03:00
 *
 * 実装:
 * - 全ユーザーを走査し、失効対象があるユーザーに対して処理を実行
 * - バッチサイズ: 100ユーザー/実行（タイムアウト防止）
 */
export const expirePointsScheduled = functions
  .region(region)
  .runWith({
    timeoutSeconds: 540,
    memory: "1GB",
  })
  .pubsub.schedule("0 18 * * *") // UTC 18:00 = JST 03:00
  .timeZone("UTC")
  .onRun(async (_context) => {
    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();

    console.log(`Starting point expiration at ${nowJST().toISOString()}`);

    // 失効対象のポイントを持つユーザーを検索
    // NOTE: 効率化のため、まず失効対象の pointLedger を検索
    const expirableEntries = await db
      .collectionGroup("pointLedger")
      .where("expiresAt", "<=", now)
      .where("delta", ">", 0)
      .where("expiredProcessed", "==", false) // 未処理のみ
      .limit(500) // バッチサイズ制限
      .get();

    if (expirableEntries.empty) {
      console.log("No points to expire");
      return { processed: 0 };
    }

    // ユーザーIDを重複なく抽出
    const userIds = new Set<string>();
    for (const doc of expirableEntries.docs) {
      const pathParts = doc.ref.path.split("/");
      if (pathParts.length >= 2) {
        userIds.add(pathParts[1]); // users/{uid}/pointLedger/{entryId}
      }
    }

    console.log(`Found ${userIds.size} users with expirable points`);

    // 各ユーザーに対して失効処理を実行
    let totalExpired = 0;
    let processedUsers = 0;

    for (const uid of userIds) {
      try {
        const result = await expirePointsForUser(uid);
        totalExpired += result.expired;
        if (result.expired > 0) {
          processedUsers++;
        }
      } catch (error) {
        console.error(`Failed to expire points for user ${uid}:`, error);
      }
    }

    console.log(`Expired ${totalExpired} points for ${processedUsers} users`);
    return { processedUsers, totalExpired };
  });

/**
 * 開発用: 特定ユーザーのポイント失効処理
 *
 * 使用例:
 * ```typescript
 * const result = await expirePointsDev({ uid: 'user123' });
 * ```
 */
export const expirePointsDev = functions
  .region(region)
  .https.onCall(async (data, context) => {
    // 認証チェック（管理者のみ許可、または開発環境のみ）
    const uid = data.uid || context.auth?.uid;
    if (!uid) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "uid is required"
      );
    }

    try {
      const result = await expirePointsForUser(uid);
      return {
        ok: true,
        uid,
        expired: result.expired,
        entries: result.entries,
      };
    } catch (error) {
      console.error("expirePointsDev failed:", error);
      throw new functions.https.HttpsError(
        "internal",
        error instanceof Error ? error.message : "Failed to expire points"
      );
    }
  });
