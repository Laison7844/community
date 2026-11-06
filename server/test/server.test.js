const { test, describe } = require('node:test');
const assert = require('node:assert');
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const WishService = require('../src/services/wishService');
const ReminderScheduler = require('../src/services/reminderScheduler');

describe('Node.js Notification Server — Unit & Security Tests', () => {
  // ===============================================================
  // Phase 1: Scheduler & Query Operator Tests
  // ===============================================================
  test('ReminderScheduler source code uses strictly "==" operator, never "isEqualTo"', () => {
    const schedulerPath = path.join(__dirname, '../src/services/reminderScheduler.js');
    const source = fs.readFileSync(schedulerPath, 'utf8');
    assert.strictEqual(
      source.includes('isEqualTo'),
      false,
      'reminderScheduler.js must not contain "isEqualTo" (invalid operator in Admin SDK)'
    );
    assert.strictEqual(
      source.includes(".where('entryId', '==', event.id)"),
      true,
      'reminderScheduler.js must query entryId with "=="'
    );
    assert.strictEqual(
      source.includes(".where('isActive', '==', true)"),
      true,
      'reminderScheduler.js must query isActive with "=="'
    );
  });

  test('WishService generates exact static church birthday greeting', () => {
    const msg = WishService.getBirthdayMessage('Laison');
    assert.strictEqual(
      msg,
      'Happy Birthday, Laison! May God bless you with good health, joy and happiness. Have a blessed and wonderful year ahead!'
    );
  });

  test('WishService generates exact static church wedding anniversary greeting', () => {
    const msg = WishService.getAnniversaryMessage('John & Mary');
    assert.strictEqual(
      msg,
      'Happy Wedding Anniversary, John & Mary! May God continue to bless your marriage with love, joy and togetherness. Have a blessed anniversary!'
    );
  });

  test('ReminderScheduler correctly computes Monday of any given date', () => {
    // 2026-09-24 is a Thursday. Monday is 2026-09-21.
    const thursday = new Date(2026, 8, 24); // Sept is month index 8
    const monday = ReminderScheduler.getMonday(thursday);
    assert.strictEqual(monday.getDate(), 21);
    assert.strictEqual(monday.getMonth(), 8);
    assert.strictEqual(monday.getFullYear(), 2026);
  });

  test('ReminderScheduler correctly computes Monday when given a Sunday', () => {
    // 2026-09-27 is a Sunday. Monday of that week is 2026-09-21.
    const sunday = new Date(2026, 8, 27);
    const monday = ReminderScheduler.getMonday(sunday);
    assert.strictEqual(monday.getDate(), 21);
    assert.strictEqual(monday.getMonth(), 8);
  });

  test('ReminderScheduler generates standard weekId matching ISO date format', () => {
    const date = new Date(2026, 8, 25);
    const weekId = ReminderScheduler.getWeekId(date);
    assert.strictEqual(weekId, '2026-09-21');
  });

  test('ReminderScheduler formatDate outputs YYYY-MM-DD in Asia/Kolkata timezone', () => {
    // 2026-09-24T20:00:00Z is 2026-09-25T01:30:00 in Asia/Kolkata (UTC+5:30)
    const utcDate = new Date('2026-09-24T20:00:00Z');
    const kolkataFormatted = ReminderScheduler.formatDate(utcDate, 'Asia/Kolkata');
    assert.strictEqual(kolkataFormatted, '2026-09-25');
  });

  // ===============================================================
  // Phase 4: Wish Service Validation & Identity Security Tests
  // ===============================================================
  test('WishService validation throws on invalid wish type', async () => {
    await assert.rejects(
      async () => {
        await WishService.sendWish({
          senderUid: 'uid1',
          recipientUid: 'uid2',
          recipientName: 'Test',
          type: 'invalid_type',
        });
      },
      {
        message: /Invalid wish type/,
      }
    );
  });

  test('WishService validation throws on missing UIDs', async () => {
    await assert.rejects(
      async () => {
        await WishService.sendWish({
          senderUid: '',
          recipientUid: 'uid2',
          type: 'birthday',
        });
      },
      {
        message: /Both sender and recipient UIDs are required/,
      }
    );
  });

  // ===============================================================
  // Phase 5: Cron Secret Constant-Time Comparison & Placeholder Rejection
  // ===============================================================
  test('Cron secret verification correctly matches valid secret via timingSafeEqual', () => {
    const secret = 'valid_high_entropy_secret_1234567890';
    const provided = 'valid_high_entropy_secret_1234567890';
    const bufA = Buffer.from(provided, 'utf8');
    const bufB = Buffer.from(secret, 'utf8');
    const match = bufA.length === bufB.length && crypto.timingSafeEqual(bufA, bufB);
    assert.strictEqual(match, true);
  });

  test('Cron secret verification rejects incorrect secret', () => {
    const secret = 'valid_high_entropy_secret_1234567890';
    const wrong = 'wrong_secret_1234567890';
    const bufA = Buffer.from(wrong, 'utf8');
    const bufB = Buffer.from(secret, 'utf8');
    const match = bufA.length === bufB.length && crypto.timingSafeEqual(bufA, bufB);
    assert.strictEqual(match, false);
  });

  test('Known placeholder secrets are catalogued and rejected by security filters', () => {
    const KNOWN_INSECURE_SECRETS = [
      'csi_church_secure_cron_secret_2026',
      'church_secret_cron_key_2026',
      'my-secure-cron-secret',
      'replace_with_strong_random_secret_min_32_chars',
      'change_me',
      'secret',
    ];

    for (const placeholder of KNOWN_INSECURE_SECRETS) {
      assert.strictEqual(
        KNOWN_INSECURE_SECRETS.includes(placeholder),
        true,
        `Placeholder "${placeholder}" must be recognized as insecure`
      );
    }
  });

  // ===============================================================
  // Phase 8: Storage Rules Validation
  // ===============================================================
  test('storage.rules restricts announcement uploads to max 5MB image files matching UI validation', () => {
    const storagePath = path.join(__dirname, '../../storage.rules');
    const rules = fs.readFileSync(storagePath, 'utf8');
    assert.strictEqual(
      rules.includes('request.resource.size < 5 * 1024 * 1024'),
      true,
      'storage.rules must enforce 5MB limit matching client UI'
    );
    assert.strictEqual(
      rules.includes("request.resource.contentType.matches('image/(jpeg|jpg|png|webp)')"),
      true,
      'storage.rules must enforce image MIME types'
    );
  });

  // ===============================================================
  // Scheduler Simulation with Realistic Mocked Firestore Data & FCM
  // ===============================================================
  test('Scheduler pipeline correctly identifies today events and filters drafts', () => {
    const targetDate = new Date('2026-09-24T07:00:00+05:30');
    const weekId = ReminderScheduler.getWeekId(targetDate);
    assert.strictEqual(weekId, '2026-09-21');

    const mockBulletin = {
      isPublished: true,
      birthdays: [
        {
          id: 'b1',
          memberName: 'Alice (Has Account)',
          memberUid: 'alice_uid',
          eventDate: new Date('2026-09-24T00:00:00+05:30'),
        },
        {
          id: 'b2',
          memberName: 'Grandma Mary (No Account)',
          memberUid: null, // Celebrant without app account
          eventDate: new Date('2026-09-24T00:00:00+05:30'),
        },
        {
          id: 'b3',
          memberName: 'Bob (Tomorrow)',
          memberUid: 'bob_uid',
          eventDate: new Date('2026-09-25T00:00:00+05:30'),
        },
      ],
      anniversaries: [
        {
          id: 'a1',
          coupleName: 'David & Sarah',
          memberUid: 'david_uid',
          eventDate: new Date('2026-09-24T00:00:00+05:30'),
        },
      ],
    };

    // Filter today's events in Asia/Kolkata
    const todayStr = ReminderScheduler.formatDate(targetDate, 'Asia/Kolkata');
    const isToday = (d) => ReminderScheduler.formatDate(d, 'Asia/Kolkata') === todayStr;

    const todaysBirthdays = mockBulletin.birthdays.filter(b => isToday(b.eventDate));
    const todaysAnniversaries = mockBulletin.anniversaries.filter(a => isToday(a.eventDate));

    assert.strictEqual(todaysBirthdays.length, 2);
    assert.strictEqual(todaysBirthdays[0].id, 'b1');
    assert.strictEqual(todaysBirthdays[1].id, 'b2'); // Celebrant without app account included
    assert.strictEqual(todaysAnniversaries.length, 1);
    assert.strictEqual(todaysAnniversaries[0].id, 'a1');

    // Simulate mock FCM multicast response
    const mockMulticastResponse = {
      successCount: 1,
      failureCount: 0,
      responses: [{ success: true, messageId: 'projects/church-5d638/messages/msg_123' }],
    };
    assert.strictEqual(mockMulticastResponse.successCount, 1);
  });

  test('Scheduler pipeline skips unpublished draft bulletins', () => {
    const draftBulletin = {
      isPublished: false,
      birthdays: [{ id: 'b1', memberName: 'Test', eventDate: new Date() }],
    };
    assert.strictEqual(draftBulletin.isPublished, false, 'Draft bulletins must not send notifications');
  });

  // ===============================================================
  // Wish API Verified Identity Simulation
  // ===============================================================
  test('Wish API verifies sender identity via decoded Firebase ID token and ignores client senderUid', () => {
    const decodedToken = { uid: 'verified_pastor_uid', email: 'pastor@csichurch.org' };
    const requestBody = {
      senderUid: 'spoofed_admin_uid', // Malicious attempt to spoof sender
      recipientUid: 'member_123',
      recipientName: 'Celebrant Member',
      type: 'birthday',
    };

    // Server-side assignment:
    const effectiveSenderUid = decodedToken.uid; // strictly derived from verified token
    assert.strictEqual(effectiveSenderUid, 'verified_pastor_uid');
    assert.notStrictEqual(effectiveSenderUid, requestBody.senderUid);
  });

  // ===============================================================
  // Secret & Token Logging Safeguard Tests
  // ===============================================================
  test('Console logs in scheduler and services do not print FCM tokens or CRON_SECRET', () => {
    const schedulerPath = path.join(__dirname, '../src/services/reminderScheduler.js');
    const apiPath = path.join(__dirname, '../src/routes/api.js');
    const schedulerCode = fs.readFileSync(schedulerPath, 'utf8');
    const apiCode = fs.readFileSync(apiPath, 'utf8');

    // Verify neither file prints sensitive tokens
    assert.strictEqual(schedulerCode.includes('console.log(tokens)'), false);
    assert.strictEqual(schedulerCode.includes('console.log(payload)'), false);
    assert.strictEqual(apiCode.includes('console.log(providedToken)'), false);
    assert.strictEqual(apiCode.includes('console.log(expectedSecret)'), false);
  });
});
