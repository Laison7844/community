const express = require('express');
const router = express.Router();
const { auth } = require('../firebase');
const TokenService = require('../services/tokenService');
const WishService = require('../services/wishService');
const ReminderScheduler = require('../services/reminderScheduler');

/**
 * Authentication middleware verifying Firebase Auth ID token
 */
async function requireAuth(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Missing or malformed Authorization header' });
  }

  const token = authHeader.split('Bearer ')[1];
  try {
    const decodedToken = await auth.verifyIdToken(token);
    req.user = decodedToken;
    next();
  } catch (err) {
    return res.status(401).json({ error: 'Invalid or expired Firebase ID token', details: err.message });
  }
}

/**
 * Health check endpoint
 */
router.get('/health', (req, res) => {
  res.json({
    status: 'online',
    timestamp: new Date().toISOString(),
    service: 'CSI Church Notification Server',
  });
});

/**
 * Register or refresh member FCM token
 * POST /api/tokens/register
 * Body: { token: string }
 */
router.post('/tokens/register', requireAuth, async (req, res) => {
  const { token } = req.body;
  if (!token) {
    return res.status(400).json({ error: 'Missing "token" in request body' });
  }

  try {
    await TokenService.registerToken(req.user.uid, token);
    res.json({ success: true, message: 'FCM token registered successfully' });
  } catch (err) {
    res.status(500).json({ error: 'Failed to register token', details: err.message });
  }
});

/**
 * Send Birthday or Anniversary Wish
 * POST /api/wishes/send
 * Body: { recipientUid, recipientName, type: 'birthday' | 'anniversary', eventDate }
 */
router.post('/wishes/send', requireAuth, async (req, res) => {
  const { recipientUid, recipientName, type, eventDate } = req.body;

  if (!recipientUid || !recipientName || !type) {
    return res.status(400).json({
      error: 'Missing required fields: recipientUid, recipientName, and type are required.',
    });
  }

  try {
    const result = await WishService.sendWish({
      senderUid: req.user.uid, // Authenticated UID, spoofing impossible
      recipientUid,
      recipientName,
      type,
      eventDate,
    });

    res.json(result);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

/**
 * Trigger daily reminder processing pipeline
 * POST /api/reminders/run-daily
 * Headers: { Authorization: 'Bearer <CRON_SECRET>' }
 */
router.post('/reminders/run-daily', async (req, res) => {
  const expectedSecret = process.env.CRON_SECRET || 'csi_church_secure_cron_secret_2026';
  const authHeader = req.headers.authorization;
  const providedToken = authHeader && authHeader.startsWith('Bearer ') ? authHeader.split('Bearer ')[1] : null;

  if (providedToken !== expectedSecret) {
    return res.status(403).json({ error: 'Unauthorized: Invalid cron secret' });
  }

  try {
    const summary = await ReminderScheduler.processDailyReminders();
    res.json({ success: true, summary });
  } catch (err) {
    res.status(500).json({ error: 'Failed running daily reminders', details: err.message });
  }
});

module.exports = router;
