require('dotenv').config();
const express = require('express');
const cors = require('cors');
const cron = require('node-cron');
const apiRoutes = require('./routes/api');
const ReminderScheduler = require('./services/reminderScheduler');

const app = express();
const PORT = process.env.PORT || 5001;

// Enable CORS for Flutter Web / Local development
app.use(cors());
app.use(express.json());

// Mount API routes
app.use('/api', apiRoutes);

// Root informational endpoint
app.get('/', (req, res) => {
  res.json({
    name: 'CSI Church Community Notification Server',
    version: '1.0.0',
    endpoints: {
      health: 'GET /api/health',
      registerToken: 'POST /api/tokens/register',
      sendWish: 'POST /api/wishes/send',
      runDailyReminders: 'POST /api/reminders/run-daily',
    },
  });
});

// Start daily cron scheduler if enabled (default 07:00 AM every day)
const shouldRunCron = process.env.RUN_CRON !== 'false';
if (shouldRunCron) {
  // Runs at 07:00 AM Indian Standard Time (IST) every day: minute 0, hour 7
  cron.schedule(
    '0 7 * * *',
    async () => {
      console.log('[Cron] Triggering daily scheduled birthday and anniversary reminders at 07:00 AM IST...');
      try {
        await ReminderScheduler.processDailyReminders();
      } catch (err) {
        console.error('[Cron] Error processing daily reminders:', err);
      }
    },
    {
      scheduled: true,
      timezone: process.env.TIMEZONE || 'Asia/Kolkata',
    }
  );
  console.log('[Scheduler] Daily birthday & anniversary cron registered for 07:00 AM (Asia/Kolkata).');
}

const server = app.listen(PORT, () => {
  console.log(`[Server] CSI Church Notification Server running on port ${PORT}`);
});

module.exports = { app, server };
