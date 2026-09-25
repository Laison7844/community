const { db, messaging, admin } = require('../firebase');
const TokenService = require('./tokenService');

class WishService {
  /**
   * Fixed Church Wish Templates: strictly non-editable by senders
   */
  static getBirthdayMessage(name) {
    return `Happy Birthday, ${name}! May God bless you with good health, joy and happiness. Have a blessed and wonderful year ahead!`;
  }

  static getAnniversaryMessage(coupleName) {
    return `Happy Wedding Anniversary, ${coupleName}! May God continue to bless your marriage with love, joy and togetherness. Have a blessed anniversary!`;
  }

  /**
   * Dispatches a verified wish with push notification
   */
  static async sendWish({
    senderUid,
    recipientUid,
    recipientName,
    type,
    eventDate,
  }) {
    if (!senderUid || !recipientUid) {
      throw new Error('Both sender and recipient UIDs are required.');
    }
    if (!['birthday', 'anniversary'].includes(type)) {
      throw new Error('Invalid wish type: must be birthday or anniversary.');
    }

    // 1. Resolve authentic sender details from Firestore
    const senderDoc = await db.collection('member_profiles').doc(senderUid).get();
    if (!senderDoc.exists) {
      throw new Error('Sender profile not found.');
    }
    const senderData = senderDoc.data();
    if (senderData.status !== 'approved') {
      throw new Error('Only approved church members can send greetings.');
    }
    const senderName = senderData.fullName || 'Church Member';

    // 2. Resolve authentic recipient details from Firestore (security verification)
    const recipientDoc = await db.collection('member_profiles').doc(recipientUid).get();
    if (!recipientDoc.exists) {
      throw new Error('Recipient profile not found.');
    }
    const recipientData = recipientDoc.data();
    if (recipientData.status !== 'approved') {
      throw new Error('Greetings can only be sent to approved church members.');
    }

    // Resolve authentic recipient name (prevents client-spoofed names)
    const resolvedRecipientName = type === 'anniversary'
      ? (recipientData.spouseName ? `${recipientData.fullName} & ${recipientData.spouseName}` : (recipientName || recipientData.fullName))
      : (recipientData.fullName || recipientName);

    // 3. Verify wish is sent on the actual event date in Asia/Kolkata
    const todayKolkataStr = new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Kolkata' }).format(new Date());
    const [, currentMonthStr, currentDayStr] = todayKolkataStr.split('-');
    const currentMonth = parseInt(currentMonthStr, 10);
    const currentDay = parseInt(currentDayStr, 10);

    const targetDateVal = type === 'birthday' ? recipientData.dateOfBirth : recipientData.weddingAnniversary;
    if (targetDateVal) {
      const d = targetDateVal.toDate ? targetDateVal.toDate() : new Date(targetDateVal);
      const targetStr = new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Kolkata' }).format(d);
      const [, tmStr, tdStr] = targetStr.split('-');
      const targetMonth = parseInt(tmStr, 10);
      const targetDay = parseInt(tdStr, 10);

      if (targetMonth !== currentMonth || targetDay !== currentDay) {
        throw new Error(`Wishes are only allowed on the actual ${type} date.`);
      }
    } else if (eventDate) {
      if (eventDate !== todayKolkataStr) {
        throw new Error(`Wishes are only allowed on the actual ${type} date (${todayKolkataStr}).`);
      }
    }

    // 4. Select appropriate static template using resolved authentic name
    const messageContent = type === 'birthday'
        ? this.getBirthdayMessage(resolvedRecipientName)
        : this.getAnniversaryMessage(resolvedRecipientName);

    // 5. Resolve recipient FCM device tokens
    const tokens = await TokenService.getTokensForUser(recipientUid);

    let notificationSent = false;
    if (tokens.length > 0) {
      const title = type === 'birthday' ? 'Birthday Greeting 🎂' : 'Wedding Anniversary Greeting 💍';
      const body = type === 'birthday'
          ? `${senderName} sent you a birthday wish 🎉`
          : `${senderName} sent you a wedding anniversary wish 🎉`;

      const payload = {
        tokens,
        notification: {
          title,
          body,
        },
        data: {
          type,
          senderUid,
          senderName,
          recipientUid,
          recipientName,
          message: messageContent,
          route: '/birthdays-anniversaries',
        },
        android: {
          priority: 'high',
          notification: {
            channelId: 'church_announcements_channel',
            sound: 'default',
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
            },
          },
        },
      };

      try {
        const response = await messaging.sendEachForMulticast(payload);
        notificationSent = response.successCount > 0;

        // Cleanup invalid tokens
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            const errCode = resp.error?.code;
            if (
              errCode === 'messaging/invalid-registration-token' ||
              errCode === 'messaging/registration-token-not-registered'
            ) {
              TokenService.removeToken(recipientUid, tokens[idx]);
            }
          }
        });
      } catch (fcmErr) {
        console.warn('[WishService] FCM send error:', fcmErr.message);
      }
    }

    // 4. Record wish log in Firestore
    const logRef = db.collection('wish_logs').doc();
    await logRef.set({
      id: logRef.id,
      senderUid,
      senderName,
      recipientUid,
      recipientName,
      type,
      message: messageContent,
      eventDate: eventDate || new Date().toISOString().split('T')[0],
      notificationSent,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      success: true,
      logId: logRef.id,
      notificationSent,
      senderName,
      message: messageContent,
    };
  }
}

module.exports = WishService;
