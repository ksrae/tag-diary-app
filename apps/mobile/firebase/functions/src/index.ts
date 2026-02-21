import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();
const db = admin.firestore();
const storage = admin.storage();

/**
 * Runs every day at midnight to delete diaries older than 7 days for 'free' users.
 * Crontab: "0 0 * * *"
 */
export const deleteOldFreeDiaries = functions.pubsub.schedule('0 0 * * *').timeZone('Asia/Seoul').onRun(async (context) => {
  const usersRef = db.collection('users');
  const freeUsersSnapshot = await usersRef.where('plan', '==', 'free').get();

  if (freeUsersSnapshot.empty) {
    console.log('No free users found.');
    return null;
  }

  // 7 days ago timestamp
  const sevenDaysAgo = new Date();
  sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

  const batch = db.batch();
  let deletedCount = 0;

  for (const userDoc of freeUsersSnapshot.docs) {
    const uid = userDoc.id;
    const diariesRef = userDoc.ref.collection('diaries');

    // Find diaries where date < sevenDaysAgo
    const oldDiariesSnapshot = await diariesRef.where('date', '<', sevenDaysAgo).get();

    for (const diaryDoc of oldDiariesSnapshot.docs) {
      const diaryId = diaryDoc.id;
      // 1. Delete Firestore Document
      batch.delete(diaryDoc.ref);

      // 2. Delete associated storage folder
      const bucket = storage.bucket();
      await bucket.deleteFiles({
        prefix: `users/${uid}/diaries/${diaryId}/`
      }).catch(err => {
        console.error(`Failed to delete storage for ${uid}/${diaryId}:`, err);
      });

      deletedCount++;
    }
  }

  if (deletedCount > 0) {
    await batch.commit();
    console.log(`Successfully deleted ${deletedCount} old diaries for free users.`);
  }

  return null;
});
