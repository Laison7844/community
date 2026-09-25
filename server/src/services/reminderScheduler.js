const { db, messaging, admin } = require('../firebase');
const TokenService = require('./tokenService');

class ReminderScheduler {
  /**
   * Calculates Monday for any date
   */
  static getMonday(date) {
    const d = new Date(date);
    const day = d.getDay();
    const diff = d.getDate() - day + (day === 0 ? -6 : 1);
    const monday = new Date(d.setDate(diff));
    monday.setHours(0, 0, 0, 0);
    return monday;
  }

  /**
   * Formats Date in Asia/Kolkata timezone as YYYY-MM-DD
   */
  static formatDate(d, timeZone = 'Asia/Kolkata') {
    if (!d) return '';
    const dateObj = d instanceof Date ? d : new Date(d);
    return new Intl.DateTimeFormat('en-CA', {
      timeZone,
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
    }).format(dateObj);
  }

  /**
   * Generates standard weekId (YYYY-MM-DD) from Monday
   */
  static getWeekId(date) {
    const monday = this.getMonday(date);
    return this.formatDate(monday);
  }

  /**
   * Runs the daily reminder pipeline.
   * Safe against duplicate sends.
   */
  static async processDailyReminders(targetDate) {
    const today = targetDate ? (targetDate instanceof Date ? targetDate : new Date(targetDate)) : new Date();
    const todayStr = this.formatDate(today);
    const [, mStr, dStr] = todayStr.split('-');
    const todayMonth = parseInt(mStr, 10);
    const todayDay = parseInt(dStr, 10);

    const weekId = this.getWeekId(today);
    console.log(`[ReminderScheduler] Running daily reminders for date: ${todayStr} (Asia/Kolkata, weekId: ${weekId})`);

    // 1. Fetch published bulletin for this week
    const weekDoc = await db.collection('birthday_anniversary_weeks').doc(weekId).get();
    if (!weekDoc.exists) {
      console.log(`[ReminderScheduler] No bulletin found for week: ${weekId}`);
      return { date: todayStr, message: 'No bulletin for week', sentCount: 0 };
    }

    const weekData = weekDoc.data();
    if (!weekData.isPublished) {
      console.log(`[ReminderScheduler] Week ${weekId} is not published yet.`);
      return { date: todayStr, message: 'Bulletin is draft', sentCount: 0 };
    }

    const birthdays = Array.isArray(weekData.birthdays) ? weekData.birthdays : [];
    const anniversaries = Array.isArray(weekData.anniversaries) ? weekData.anniversaries : [];

    // Helper to check if entry occurs today in Asia/Kolkata
    const isToday = (entryDateVal) => {
      if (!entryDateVal) return false;
      const d = entryDateVal.toDate ? entryDateVal.toDate() : new Date(entryDateVal);
      const entryStr = this.formatDate(d);
      const [, emStr, edStr] = entryStr.split('-');
      return parseInt(emStr, 10) === todayMonth && parseInt(edStr, 10) === todayDay;
    };

    const todaysBirthdays = birthdays.filter(b => isToday(b.eventDate));
    const todaysAnniversaries = anniversaries.filter(a => isToday(a.eventDate));

    console.log(`[ReminderScheduler] Found ${todaysBirthdays.length} birthdays and ${todaysAnniversaries.length} anniversaries today.`);

    let sentCount = 0;
    const allEvents = [
      ...todaysBirthdays.map(b => ({ ...b, type: 'birthday', targetName: b.memberName })),
      ...todaysAnniversaries.map(a => ({ ...a, type: 'anniversary', targetName: a.coupleName })),
    ];

    for (const event of allEvents) {
      // Find all active reminders set for this entry
      const remindersSnap = await db.collection('member_reminders')
        .where('entryId', 'isEqualTo', event.id)
        .where('isActive', 'isEqualTo', true)
        .get();

      if (remindersSnap.empty) continue;

      for (const reminderDoc of remindersSnap.docs) {
        const reminder = reminderDoc.data();
        const userUid = reminder.userUid;
        if (!userUid) continue;

        // Deduplication check: verify notification hasn't already been sent today
        const dedupId = `remind_${userUid}_${event.id}_${todayStr}`;
        const logRef = db.collection('notification_logs').doc(dedupId);
        const existingLog = await logRef.get();

        if (existingLog.exists) {
          // Already sent today; skip
          continue;
        }

        // Resolve user FCM device tokens
        const tokens = await TokenService.getTokensForUser(userUid);
        if (tokens.length === 0) continue;

        const title = event.type === 'birthday' ? '🎂 Birthday Reminder' : '💍 Anniversary Reminder';
        const body = event.type === 'birthday'
            ? `Today is ${event.targetName}'s birthday 🎂`
            : `Today is ${event.targetName}'s wedding anniversary 💍`;

        const payload = {
          tokens,
          notification: {
            title,
            body,
          },
          data: {
            type: 'reminder',
            eventType: event.type,
            entryId: event.id,
            targetName: event.targetName,
            route: '/birthdays-anniversaries',
          },
          android: {
            priority: 'high',
            notification: {
              channelId: 'church_reminders_channel',
              sound: 'default',
            },
          },
          apns: {
            payload: {
              aps: {
                sound: 'default',
              },
            },
          },
        };

        try {
          const resp = await messaging.sendEachForMulticast(payload);
          if (resp.successCount > 0) {
            sentCount += resp.successCount;

            // Record log to prevent duplicate sends
            await logRef.set({
              id: dedupId,
              userUid,
              entryId: event.id,
              targetName: event.targetName,
              type: event.type,
              dateStr: todayStr,
              timestamp: admin.firestore.FieldValue.serverTimestamp(),
            });
          }

          // Cleanup invalid tokens
          resp.responses.forEach((r, idx) => {
            if (!r.success) {
              const errCode = r.error?.code;
              if (
                errCode === 'messaging/invalid-registration-token' ||
                errCode === 'messaging/registration-token-not-registered'
              ) {
                TokenService.removeToken(userUid, tokens[idx]);
              }
            }
          });
        } catch (err) {
          console.warn(`[ReminderScheduler] Failed sending reminder to ${userUid}:`, err.message);
        }
      }
    }

    console.log(`[ReminderScheduler] Daily reminders finished. Sent ${sentCount} notifications.`);
    return {
      date: todayStr,
      birthdaysCount: todaysBirthdays.length,
      anniversariesCount: todaysAnniversaries.length,
      notificationsSent: sentCount,
    };
  }
}

module.exports = ReminderScheduler;
