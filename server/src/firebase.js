const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

let initialized = false;

function initFirebase() {
  if (initialized) return admin;

  const projectId = process.env.FIREBASE_PROJECT_ID || 'church-5d638';
  const serviceAccountPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;

  if (serviceAccountPath && fs.existsSync(serviceAccountPath)) {
    const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf8'));
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId: serviceAccount.project_id || projectId,
    });
  } else {
    // Uses Google Cloud Application Default Credentials or Project ID
    admin.initializeApp({
      projectId,
    });
  }

  initialized = true;
  return admin;
}

module.exports = {
  admin,
  initFirebase,
  get db() {
    initFirebase();
    return admin.firestore();
  },
  get messaging() {
    initFirebase();
    return admin.messaging();
  },
  get auth() {
    initFirebase();
    return admin.auth();
  }
};
