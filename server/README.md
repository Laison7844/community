# CSI Church Community — Node.js Notification Server

Trusted server-side notification backend and daily cron scheduler for the CSI Church Community app.

## Responsibilities
1. **Push Notifications**: Sends Firebase Cloud Messaging (FCM) notifications for member birthday and anniversary reminders and wishes.
2. **Daily Scheduler**: Automatically runs every day at 07:00 AM to process birthdays and anniversaries from published weekly bulletins, resolving members who enabled reminders and dispatching FCM notifications with duplicate protection.
3. **Static Wish Delivery**: Validates sender authentication, applies non-editable church blessing templates, and delivers push notifications to celebrants.
4. **FCM Token Management**: Registers multi-device member tokens and cleans up stale/unregistered tokens.

---

## Directory Structure
```
server/
├── src/
│   ├── firebase.js              # Firebase Admin SDK initialization
│   ├── routes/
│   │   └── api.js               # Express API endpoints
│   ├── services/
│   │   ├── reminderScheduler.js # Daily reminder pipeline and deduplication
│   │   ├── tokenService.js      # Multi-device token management
│   │   └── wishService.js       # Static templates and wish delivery
│   └── index.js                 # Express server & node-cron setup
├── test/
│   └── server.test.js           # Unit tests
├── .env.example                 # Environment variables template
├── package.json
└── README.md
```

---

## Installation & Setup

1. **Install dependencies**:
   ```bash
   cd server
   npm install
   ```

2. **Configure Environment Variables**:
   Copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```

   Key variables:
   - `PORT`: HTTP port (default `5001`).
   - `FIREBASE_PROJECT_ID`: `church-5d638`.
   - `GOOGLE_APPLICATION_CREDENTIALS`: Absolute path to your service account key file (or run in Google Cloud environment where Application Default Credentials are automatically discovered).
   - `CRON_SECRET`: Secret token for calling `/api/reminders/run-daily` via Cloud Scheduler.
   - `RUN_CRON`: `true` to enable background node-cron scheduler (runs at 07:00 AM daily).

3. **Run Tests**:
   ```bash
   npm test
   ```

4. **Start Server**:
   ```bash
   npm start
   ```

---

## API Endpoints

### 1. Health Check
`GET /api/health`
Returns server status and timestamp.

### 2. Register FCM Device Token
`POST /api/tokens/register`
**Headers**: `Authorization: Bearer <Firebase_ID_Token>`
**Body**:
```json
{
  "token": "dKjs983...fcm_device_token"
}
```

### 3. Send Birthday or Anniversary Wish
`POST /api/wishes/send`
**Headers**: `Authorization: Bearer <Firebase_ID_Token>`
**Body**:
```json
{
  "recipientUid": "uid_recipient",
  "recipientName": "John Doe",
  "type": "birthday",
  "eventDate": "2026-09-25"
}
```
*Note: Sender identity and name are resolved from authenticated Firestore profile data. Wishes use non-editable church blessing templates.*

### 4. Trigger Daily Reminder (Cloud Scheduler / Cron)
`POST /api/reminders/run-daily`
**Headers**: `Authorization: Bearer <CRON_SECRET>`
*Processes today's birthdays and anniversaries from published bulletins, checks active member reminders, checks deduplication logs, and dispatches FCM notifications.*

---

## Cloud Deployment (e.g. Google Cloud Run)

```bash
gcloud run deploy csi-church-notifications \
  --source . \
  --region us-central1 \
  --set-env-vars FIREBASE_PROJECT_ID=church-5d638,RUN_CRON=true
```
