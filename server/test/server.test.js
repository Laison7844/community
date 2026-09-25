const { test, describe } = require('node:test');
const assert = require('node:assert');
const WishService = require('../src/services/wishService');
const ReminderScheduler = require('../src/services/reminderScheduler');

describe('Node.js Notification Server — Unit Tests', () => {
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

  test('ReminderScheduler formatDate outputs YYYY-MM-DD in Asia/Kolkata timezone', () => {
    // 2026-09-24T20:00:00Z is 2026-09-25T01:30:00 in Asia/Kolkata (UTC+5:30)
    const utcDate = new Date('2026-09-24T20:00:00Z');
    const kolkataFormatted = ReminderScheduler.formatDate(utcDate, 'Asia/Kolkata');
    assert.strictEqual(kolkataFormatted, '2026-09-25');
  });
});
