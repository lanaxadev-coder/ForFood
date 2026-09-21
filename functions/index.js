// ============================================================
// ForFood Cloud Functions — push notifications
// ============================================================

const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

/**
 * Sends a push notification whenever a new document is
 * created in /notifications/{id}. Routes to the recipient's
 * FCM token stored in /users/{recipientId}.fcmToken.
 */
exports.sendPushOnNotificationCreate = functions.firestore
  .document('notifications/{notificationId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    if (!data) return null;

    const recipientId = data.recipientId;
    if (!recipientId) {
      console.log('No recipientId on notification', context.params.notificationId);
      return null;
    }

    // Look up the recipient's FCM token
    let token = null;
    try {
      const userDoc = await admin
        .firestore()
        .collection('users')
        .doc(recipientId)
        .get();

      if (userDoc.exists) {
        token = userDoc.data().fcmToken;
      }
    } catch (err) {
      console.error('Failed to load user doc:', err);
    }

    if (!token) {
      console.log('No FCM token for user', recipientId);
      return null;
    }

    // Build the FCM message
    const message = {
      token: token,
      notification: {
        title: data.title || 'ForFood',
        body: data.message || '',
      },
      data: {
        // Everything in `data` must be strings
        type: String(data.type || ''),
        orderId: String(data.orderId || ''),
        notificationId: context.params.notificationId,
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'forfood_default',
          color: '#E95322',
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
      const response = await admin.messaging().send(message);
      console.log('Push sent:', response);
      return response;
    } catch (err) {
      console.error('Failed to send push:', err);

      // If the token is stale, clear it from Firestore
      if (
        err.code === 'messaging/registration-token-not-registered' ||
        err.code === 'messaging/invalid-registration-token'
      ) {
        await admin
          .firestore()
          .collection('users')
          .doc(recipientId)
          .update({ fcmToken: admin.firestore.FieldValue.delete() });
      }

      return null;
    }
  });