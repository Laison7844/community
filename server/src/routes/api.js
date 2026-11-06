const express = require('express');
const router = express.Router();
const crypto = require('crypto');
const { auth } = require('../firebase');
const TokenService = require('../services/tokenService');
const WishService = require('../services/wishService');
const ReminderScheduler = require('../services/reminderScheduler');

/**
 * In-memory sliding rate limiter for greeting dispatches (prevents spam abuse)
 * Allows up to 10 wishes per minute per authenticated user
 */
const wishRateLimits = new Map();
const WISH_RATE_LIMIT_WINDOW_MS = 60 * 1000;
const MAX_WISHES_PER_WINDOW = 10;

function checkWishRateLimit(uid) {
  const now = Date.now();
  const userTimestamps = wishRateLimits.get(uid) || [];
  // Prune timestamps older than window
  const activeTimestamps = userTimestamps.filter(t => now - t < WISH_RATE_LIMIT_WINDOW_MS);
  if (activeTimestamps.length >= MAX_WISHES_PER_WINDOW) {
    return false;
  }
  activeTimestamps.push(now);
  wishRateLimits.set(uid, activeTimestamps);
  return true;
}

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
  if (!token || typeof token !== 'string' || token.trim().length === 0) {
    return res.status(400).json({ error: 'Missing or invalid "token" in request body' });
  }

  try {
    await TokenService.registerToken(req.user.uid, token.trim());
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

  // Rate limiting check per authenticated sender UID
  if (!checkWishRateLimit(req.user.uid)) {
    return res.status(429).json({
      error: 'Too many greetings sent. Please wait a moment before sending more wishes.',
    });
  }

  try {
    const result = await WishService.sendWish({
      senderUid: req.user.uid, // Strictly derived from verified Firebase ID token (spoofing impossible)
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
  const expectedSecret = process.env.CRON_SECRET;
  if (!expectedSecret || expectedSecret.trim() === '') {
    console.error('[Security] CRON_SECRET is not configured on server.');
    return res.status(500).json({ error: 'Server misconfiguration: CRON_SECRET is not configured' });
  }

  const KNOWN_INSECURE_SECRETS = [
    'csi_church_secure_cron_secret_2026',
    'church_secret_cron_key_2026',
    'my-secure-cron-secret',
    'replace_with_strong_random_secret_min_32_chars',
    'change_me',
    'secret',
  ];

  if (KNOWN_INSECURE_SECRETS.includes(expectedSecret.trim())) {
    console.error('[Security] Insecure placeholder CRON_SECRET detected. Refusing execution.');
    return res.status(403).json({ error: 'Unauthorized: Insecure CRON_SECRET placeholder in use' });
  }

  const authHeader = req.headers.authorization;
  const providedToken = authHeader && authHeader.startsWith('Bearer ') ? authHeader.split('Bearer ')[1] : null;

  if (!providedToken) {
    return res.status(401).json({ error: 'Missing or malformed Authorization header' });
  }

  const bufA = Buffer.from(providedToken, 'utf8');
  const bufB = Buffer.from(expectedSecret, 'utf8');
  const isMatch = bufA.length === bufB.length && crypto.timingSafeEqual(bufA, bufB);

  if (!isMatch) {
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
