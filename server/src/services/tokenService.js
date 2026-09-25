const { db, admin } = require('../firebase');

/**
 * Service for registering, resolving, and cleaning up FCM device tokens.
 */
class TokenService {
  /**
   * Registers or refreshes an FCM token for a member.
   * Supports multiple devices per user without duplicates.
   */
  static async registerToken(uid, token) {
    if (!uid || !token) throw new Error('Missing uid or token');

    const memberRef = db.collection('member_profiles').doc(uid);
    await memberRef.set(
      {
        fcmTokens: admin.firestore.FieldValue.arrayUnion(token),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
  }

  /**
   * Cleans up an invalid or expired FCM token from a member's profile.
   */
  static async removeToken(uid, token) {
    if (!uid || !token) return;

    try {
      const memberRef = db.collection('member_profiles').doc(uid);
      await memberRef.update({
        fcmTokens: admin.firestore.FieldValue.arrayRemove(token),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (err) {
      console.warn(`[TokenService] Could not remove token for ${uid}:`, err.message);
    }
  }

  /**
   * Retrieves active tokens for a specific user.
   */
  static async getTokensForUser(uid) {
    const doc = await db.collection('member_profiles').doc(uid).get();
    if (!doc.exists) return [];
    const data = doc.data();
    return Array.isArray(data.fcmTokens) ? data.fcmTokens : [];
  }
}

module.exports = TokenService;
