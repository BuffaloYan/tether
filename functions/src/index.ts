import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { sendAlerts } from './alerts';

admin.initializeApp();

/**
 * Scheduled function that runs every hour to check for missed check-ins
 * and trigger alerts to emergency contacts
 */
export const checkMissedCheckIns = functions.pubsub
  .schedule('every 1 hours')
  .onRun(async (context) => {
    const db = admin.firestore();
    const now = Date.now();

    try {
      const usersSnapshot = await db.collection('users').get();

      const alertPromises: Promise<void>[] = [];

      usersSnapshot.forEach((userDoc) => {
        const data = userDoc.data();
        const deviceId = userDoc.id;

        // Skip if user doesn't have lastCheckIn or is already alerted
        if (!data.lastCheckIn || data.alerted) {
          return;
        }

        const lastCheckIn = data.lastCheckIn.toDate();
        const gracePeriodHours = data.gracePeriodHours || 24;
        const hoursSinceCheckIn = (now - lastCheckIn.getTime()) / (1000 * 60 * 60);

        // Check if grace period has passed
        if (hoursSinceCheckIn > gracePeriodHours) {
          functions.logger.info(`User ${deviceId} missed check-in. Hours since last check-in: ${hoursSinceCheckIn}`);

          // Trigger alert
          const alertPromise = sendAlerts(
            deviceId,
            data.contacts || [],
            data.userName || 'Unknown User',
            hoursSinceCheckIn,
            gracePeriodHours,
            lastCheckIn,
            data.lastLocation,
            data.preferredLanguage || 'en'
          ).then(async () => {
            // Mark user as alerted
            await userDoc.ref.update({ alerted: true });
          }).catch((error) => {
            functions.logger.error(`Error sending alerts for user ${deviceId}:`, error);
          });

          alertPromises.push(alertPromise);
        }
      });

      // Wait for all alerts to be sent
      await Promise.all(alertPromises);

      functions.logger.info(`Check-in monitoring completed. Processed ${usersSnapshot.size} users, sent ${alertPromises.length} alerts.`);
    } catch (error) {
      functions.logger.error('Error in checkMissedCheckIns:', error);
      throw error;
    }
  });

/**
 * Callable function to manually trigger an immediate alert
 * Used for "tether alert" voice command or panic button
 */
export const triggerImmediateAlert = functions.https.onCall(async (data, context) => {
  // Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { deviceId, location } = data;

  if (!deviceId) {
    throw new functions.https.HttpsError('invalid-argument', 'deviceId is required');
  }

  try {
    const db = admin.firestore();
    const userDoc = await db.collection('users').doc(deviceId).get();

    if (!userDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'User not found');
    }

    const userData = userDoc.data();

    if (!userData) {
      throw new functions.https.HttpsError('not-found', 'User data not found');
    }

    // Send immediate alert
    await sendAlerts(
      deviceId,
      userData.contacts || [],
      userData.userName || 'Unknown User',
      0, // Hours since check-in (immediate)
      userData.gracePeriodHours || 24,
      new Date(), // Current time
      location || userData.lastLocation,
      userData.preferredLanguage || 'en',
      true // isImmediate flag
    );

    functions.logger.info(`Immediate alert triggered for user ${deviceId}`);

    return { success: true, message: 'Alert sent successfully' };
  } catch (error) {
    functions.logger.error('Error in triggerImmediateAlert:', error);
    throw new functions.https.HttpsError('internal', 'Failed to send alert');
  }
});

/**
 * HTTP function to reset alert status when user checks in successfully
 */
export const resetAlertStatus = functions.https.onCall(async (data, context) => {
  // Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { deviceId } = data;

  if (!deviceId) {
    throw new functions.https.HttpsError('invalid-argument', 'deviceId is required');
  }

  try {
    const db = admin.firestore();
    await db.collection('users').doc(deviceId).update({
      alerted: false,
      lastCheckIn: admin.firestore.FieldValue.serverTimestamp(),
    });

    functions.logger.info(`Alert status reset for user ${deviceId}`);

    return { success: true, message: 'Alert status reset successfully' };
  } catch (error) {
    functions.logger.error('Error in resetAlertStatus:', error);
    throw new functions.https.HttpsError('internal', 'Failed to reset alert status');
  }
});
