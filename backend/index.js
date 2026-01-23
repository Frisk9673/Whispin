const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * 招待ドキュメント作成時に通知を送信
 */
exports.sendInvitationNotification = functions.firestore
  .document("invitations/{invitationId}")
  .onCreate(async (snapshot) => {
    const data = snapshot.data();

    if (!data || !data.fcmToken) {
      console.log("FCM token not found");
      return;
    }

    await admin.messaging().send({
      token: data.fcmToken,
      notification: {
        title: "招待が届きました",
        body: "Whispinで新しい招待があります",
      },
    });

    console.log("Notification sent");
  });
