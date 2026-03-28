const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

/**
 * Triggered every time a new document is added to the `notifications`
 * collection (by the admin panel). Sends a real FCM push notification
 * to the `all_users` topic — this reaches ALL devices in background/killed state.
 */
exports.sendPushOnNotification = onDocumentCreated(
  "notifications/{docId}",
  async (event) => {
    const data = event.data?.data();
    if (!data) return null;

    const title   = data.title   || "BGMI Tournamentor";
    const message = data.message || "";
    const type    = data.type    || "general";

    // Build the FCM message
    const fcmMessage = {
      topic: "all_users",            // every device subscribed on app startup
      notification: {
        title: title,
        body: message,
      },
      android: {
        priority: "high",
        notification: {
          channelId: "bgmi_tournament_channel",  // must match Flutter channel id
          color: "#F47B25",
          icon: "ic_launcher",
          sound: "default",
          priority: "high",
          defaultVibrateTimings: true,
        },
      },
      data: {
        type: type,
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
    };

    try {
      const response = await getMessaging().send(fcmMessage);
      console.log("FCM push sent successfully. MessageId:", response);
    } catch (error) {
      console.error("Error sending FCM push:", error);
    }

    return null;
  }
);
