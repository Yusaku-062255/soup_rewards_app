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
 * 前月の YYYYMM を取得（JST基準）
 */
function lastMonthYYYYMM(): string {
  const jst = nowJST();
  // 前月の1日を取得
  const lastMonth = new Date(Date.UTC(
    jst.getUTCFullYear(),
    jst.getUTCMonth() - 1,
    1
  ));
  const y = lastMonth.getUTCFullYear();
  const m = String(lastMonth.getUTCMonth() + 1).padStart(2, "0");
  return `${y}${m}`;
}

/**
 * 指定月の開始・終了タイムスタンプを取得（JST基準）
 */
function getMonthRange(yyyymm: string): { start: admin.firestore.Timestamp; end: admin.firestore.Timestamp } {
  const year = parseInt(yyyymm.substring(0, 4));
  const month = parseInt(yyyymm.substring(4, 6));

  // JST基準で月初00:00と月末23:59:59を計算
  // JSTはUTC+9なので、UTC時刻から9時間引く
  const startJST = new Date(year, month - 1, 1, 0, 0, 0, 0);
  const endJST = new Date(year, month, 1, 0, 0, 0, 0); // 翌月1日00:00（含まない）

  // JSTからUTCに変換（9時間引く）
  const startUTC = new Date(startJST.getTime() - 9 * 60 * 60 * 1000);
  const endUTC = new Date(endJST.getTime() - 9 * 60 * 60 * 1000);

  return {
    start: admin.firestore.Timestamp.fromDate(startUTC),
    end: admin.firestore.Timestamp.fromDate(endUTC),
  };
}

/**
 * 特定ユーザーの月次統計を計算
 *
 * @param uid ユーザーID
 * @param yyyymm 対象月（YYYYMM形式）
 */
async function calculateStatsForUser(
  uid: string,
  yyyymm: string
): Promise<{
  month: string;
  granted: number;
  spent: number;
  expired: number;
  net: number;
  closingBalance: number;
}> {
  const db = admin.firestore();
  const { start, end } = getMonthRange(yyyymm);

  // 対象月の pointLedger を取得
  const ledgerQuery = db
    .collection("users")
    .doc(uid)
    .collection("pointLedger")
    .where("createdAt", ">=", start)
    .where("createdAt", "<", end)
    .orderBy("createdAt", "asc");

  const snapshot = await ledgerQuery.get();

  let granted = 0; // 付与（delta > 0）
  let spent = 0; // 消費（delta < 0, type != "expire"）
  let expired = 0; // 失効（type == "expire"）

  for (const doc of snapshot.docs) {
    const data = doc.data();
    const delta = data.delta || 0;
    const type = data.type || "";

    if (type === "expire") {
      expired += Math.abs(delta);
    } else if (delta > 0) {
      granted += delta;
    } else if (delta < 0) {
      spent += Math.abs(delta);
    }
  }

  const net = granted - spent - expired;

  // 月末の残高を取得
  const userRef = db.collection("users").doc(uid);
  const userSnap = await userRef.get();
  const closingBalance = userSnap.exists ? (userSnap.data()?.totalPoints || 0) : 0;

  return {
    month: yyyymm,
    granted,
    spent,
    expired,
    net,
    closingBalance,
  };
}

/**
 * スケジュール実行: 月次統計計算
 *
 * Cloud Scheduler設定:
 * - スケジュール: 0 18 1 * * (UTC 18:00 on 1st = JST 03:00 on 1st)
 * - タイムゾーン: UTC
 * - 説明: Monthly stats calculation at JST 03:00 on 1st
 *
 * 実装:
 * - 前月のポイント履歴を集計
 * - users/{uid}/stats/{YYYYMM} に保存
 * - 全ユーザー対象（バッチサイズ: 100ユーザー/実行）
 */
export const calculateMonthlyStatsScheduled = functions
  .region(region)
  .runWith({
    timeoutSeconds: 540,
    memory: "1GB",
  })
  .pubsub.schedule("0 18 1 * *") // UTC 18:00 on 1st = JST 03:00 on 1st
  .timeZone("UTC")
  .onRun(async (_context) => {
    const db = admin.firestore();
    const targetMonth = lastMonthYYYYMM();

    console.log(`Starting monthly stats calculation for ${targetMonth} at ${nowJST().toISOString()}`);

    // 全ユーザーを取得（バッチサイズ制限）
    const usersSnapshot = await db.collection("users").limit(100).get();

    if (usersSnapshot.empty) {
      console.log("No users found");
      return { processed: 0 };
    }

    let processedUsers = 0;
    let errors = 0;

    for (const userDoc of usersSnapshot.docs) {
      const uid = userDoc.id;

      try {
        // 既に統計が存在する場合はスキップ
        const statsRef = db.collection("users").doc(uid).collection("stats").doc(targetMonth);
        const statsSnap = await statsRef.get();

        if (statsSnap.exists) {
          console.log(`Stats already exist for user ${uid}, month ${targetMonth}`);
          continue;
        }

        // 統計を計算
        const stats = await calculateStatsForUser(uid, targetMonth);

        // 統計を保存
        await statsRef.set({
          ...stats,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        processedUsers++;
        console.log(`Calculated stats for user ${uid}: granted=${stats.granted}, spent=${stats.spent}, expired=${stats.expired}, net=${stats.net}`);
      } catch (error) {
        console.error(`Failed to calculate stats for user ${uid}:`, error);
        errors++;
      }
    }

    console.log(`Processed ${processedUsers} users with ${errors} errors`);
    return { processedUsers, errors, targetMonth };
  });

/**
 * 開発用: 特定ユーザーの月次統計を手動計算
 *
 * 使用例:
 * ```typescript
 * const result = await calculateMonthlyStatsDev({ uid: 'user123', month: '202501' });
 * ```
 */
export const calculateMonthlyStatsDev = functions
  .region(region)
  .https.onCall(async (data, context) => {
    const uid = data.uid || context.auth?.uid;
    if (!uid) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "uid is required"
      );
    }

    const month = data.month || lastMonthYYYYMM();

    try {
      const stats = await calculateStatsForUser(uid, month);

      // 統計を保存
      const db = admin.firestore();
      const statsRef = db.collection("users").doc(uid).collection("stats").doc(month);
      await statsRef.set({
        ...stats,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return {
        ok: true,
        uid,
        month,
        stats,
      };
    } catch (error) {
      console.error("calculateMonthlyStatsDev failed:", error);
      throw new functions.https.HttpsError(
        "internal",
        error instanceof Error ? error.message : "Failed to calculate stats"
      );
    }
  });
