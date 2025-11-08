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
 * DateオブジェクトをYYYYMMDD形式の文字列に変換（JST基準）
 */
function formatDateYYYYMMDD(date: Date): string {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, "0");
  const day = String(date.getDate()).padStart(2, "0");
  return `${year}${month}${day}`;
}

/**
 * 開発用: スロットのシードデータを作成
 *
 * @param data { centerId?: string, daysAhead?: number }
 * @returns { ok: true, created: number, skipped: number, dates: string[] }
 */
export const seedSlotsDev = functions
  .region(region)
  .https.onCall(async (data, context) => {
    // 認証チェック（開発用だが一応）
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "auth_required"
      );
    }

    const centerId = data.centerId || "default";
    const daysAhead = data.daysAhead || 3;

    const db = admin.firestore();
    const jstNow = nowJST();

    const slots = [
      { time: "09:00", serviceType: "wash" },
      { time: "10:00", serviceType: "wash" },
      { time: "11:00", serviceType: "wash" },
    ];

    let created = 0;
    let skipped = 0;
    const dates: string[] = [];

    // 今日から daysAhead 日分のスロットを作成
    for (let i = 0; i < daysAhead; i++) {
      const targetDate = new Date(jstNow);
      targetDate.setDate(jstNow.getDate() + i);
      const dateStr = formatDateYYYYMMDD(targetDate);
      dates.push(dateStr);

      const dayRef = db
        .collection("serviceCenters")
        .doc(centerId)
        .collection("days")
        .doc(dateStr);

      // 各時間帯のスロットを作成
      for (const slot of slots) {
        const slotId = `${slot.time.replace(":", "")}-${slot.serviceType}`;
        const slotRef = dayRef.collection("slots").doc(slotId);

        const slotSnap = await slotRef.get();

        if (slotSnap.exists) {
          // 既に存在する場合はスキップ
          skipped++;
          console.log(
            `Skipped existing slot: ${dateStr}/${slotId}`
          );
        } else {
          // 新規作成
          await slotRef.set({
            time: slot.time,
            serviceType: slot.serviceType,
            capacity: 3,
            reservedCount: 0,
            version: 1,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          created++;
          console.log(
            `Created slot: ${dateStr}/${slotId}`
          );
        }
      }
    }

    console.log(
      `Seed complete: created=${created}, skipped=${skipped}, dates=${dates.join(", ")}`
    );

    return {
      ok: true,
      created,
      skipped,
      dates,
    };
  });

/**
 * 開発用: 予約リマインダーを送信
 *
 * @param data { centerId?: string, withinHours?: number }
 * @returns { ok: true, sent: number, skipped: number }
 */
export const sendBookingRemindersDev = functions
  .region(region)
  .https.onCall(async (data, _context) => {
    // 本関数は開発用なので認証不要（管理者のみ実行を想定）

    const centerId = data.centerId || "default";
    const withinHours = data.withinHours || 26;

    const db = admin.firestore();
    const jstNow = nowJST();

    // withinHours 時間後までの時刻を計算
    const futureTime = new Date(jstNow.getTime() + withinHours * 60 * 60 * 1000);
    const futureDate = formatDateYYYYMMDD(futureTime);
    const nowDate = formatDateYYYYMMDD(jstNow);

    console.log(
      `Checking bookings from ${nowDate} to ${futureDate} (within ${withinHours}h)`
    );

    // 予約を検索（centerId, status=confirmed, date が現在から futureDate まで）
    const bookingsSnapshot = await db
      .collection("bookings")
      .where("centerId", "==", centerId)
      .where("status", "==", "confirmed")
      .where("date", ">=", nowDate)
      .where("date", "<=", futureDate)
      .get();

    let sent = 0;
    let skipped = 0;

    for (const doc of bookingsSnapshot.docs) {
      const booking = doc.data();
      const bookingId = doc.id;

      // 既にリマインダー送信済みかチェック
      if (booking.reminderSent === true) {
        skipped++;
        console.log(`Skipped (already sent): ${bookingId}`);
        continue;
      }

      // リマインダー送信フラグを立てる
      await doc.ref.update({
        reminderSent: true,
        reminderSentAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      sent++;
      console.log(
        `Reminder sent for booking: ${bookingId} (user=${booking.userId}, date=${booking.date}, time=${booking.time})`
      );

      // 実際のプッシュ通知送信は省略（開発用なのでフラグ立てるだけ）
      // 本番では FCM を使って通知を送信
      /*
      const userSnapshot = await db.collection("users").doc(booking.userId).get();
      const fcmToken = userSnapshot.data()?.fcmToken;
      if (fcmToken) {
        await admin.messaging().send({
          token: fcmToken,
          notification: {
            title: "予約リマインダー",
            body: `明日の予約があります: ${booking.date} ${booking.time}`,
          },
        });
      }
      */
    }

    console.log(
      `Reminders complete: sent=${sent}, skipped=${skipped}`
    );

    return {
      ok: true,
      sent,
      skipped,
    };
  });
