const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * 招待ドキュメント作成時に通知を送信（Cloud Functions v2）
 */
exports.sendInvitationNotification = onDocumentCreated(
  "invitations/{invitationId}",
  async (event) => {
    const snapshot = event.data;

    if (!snapshot) {
      console.log("No snapshot data");
      return;
    }

    const data = snapshot.data();

    if (!data?.fcmToken) {
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
  }
);