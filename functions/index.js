// /**
//  * Import function triggers from their respective submodules:
//  *
//  * const {onCall} = require("firebase-functions/v2/https");
//  * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
//  *
//  * See a full list of supported triggers at https://firebase.google.com/docs/functions
//  */

// const {onRequest} = require("firebase-functions/v2/https");
// const logger = require("firebase-functions/logger");

// // Create and deploy your first functions
// // https://firebase.google.com/docs/functions/get-started

// // exports.helloWorld = onRequest((request, response) => {
// //   logger.info("Hello logs!", {structuredData: true});
// //   response.send("Hello from Firebase!");
// // });


const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendOrderStatusNotification = functions.https.onCall(async (data, context) => {
  const { orderId, newStatus, farmerId } = data;

  try {
    // Get the farmer's FCM token
    const farmerDoc = await admin.firestore().collection("users").doc(farmerId).get();
    const farmerData = farmerDoc.data();

    if (!farmerData || !farmerData.fcmToken) {
      console.log("No FCM token found for farmer");
      return;
    }

    // Get order details
    const orderDoc = await admin.firestore().collection("orders").doc(orderId).get();
    const orderData = orderDoc.data();

    // Create notification message
    const message = {
      notification: {
        title: "Order Status Updated",
        body: `Your order #${orderId.substring(0, 6)} status is now: ${newStatus}`,
      },
      data: {
        orderId: orderId,
        status: newStatus,
        type: "order_status",
      },
      token: farmerData.fcmToken,
    };

    // Send the message
    const response = await admin.messaging().send(message);
    console.log("Successfully sent message:", response);

    // Also save to notifications collection
    await admin.firestore().collection("notifications").add({
      userId: farmerId,
      title: "Order Status Updated",
      message: `Your order #${orderId.substring(0, 6)} status is now: ${newStatus}`,
      orderId: orderId,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      seen: false,
      type: "order_status",
    });

    return { success: true };
  } catch (error) {
    console.error("Error sending notification:", error);
    return { success: false, error: error.message };
  }
});