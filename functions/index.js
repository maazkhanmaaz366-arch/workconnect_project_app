const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.dispatchJobNotification = functions.firestore
  .document("jobs/{jobId}")
  .onCreate(async (snap, context) => {
    const jobData = snap.data();
    const tradeCategory = jobData.category || "General Labor";
    const jobTitle = jobData.title || "New Job Posted";

    console.log(`New job created: ${jobTitle} (${tradeCategory})`);

    try {
      // Query workers who are available and match the trade category
      const workersSnapshot = await admin.firestore().collection("users")
        .where("role", "==", "worker")
        .where("isAvailable", "==", true)
        .where("trade", "==", tradeCategory)
        .get();

      if (workersSnapshot.empty) {
        console.log("No available workers found for this trade.");
        return null;
      }

      // Collect FCM tokens (assuming fcmToken is stored on user doc)
      const tokens = [];
      workersSnapshot.forEach(doc => {
        const data = doc.data();
        if (data.fcmToken) {
          tokens.push(data.fcmToken);
        }
      });

      if (tokens.length === 0) {
        console.log("Found workers, but no FCM tokens available.");
        return null;
      }

      // Construct notification payload
      const payload = {
        notification: {
          title: "New Job Alert!",
          body: `A new ${tradeCategory} job is available: ${jobTitle}`,
        },
        data: {
          click_action: "FLUTTER_NOTIFICATION_CLICK",
          jobId: context.params.jobId,
        }
      };

      // Dispatch to all matching workers
      const response = await admin.messaging().sendToDevice(tokens, payload);
      console.log("Successfully sent notifications:", response);

    } catch (error) {
      console.error("Error dispatching notifications:", error);
    }
    
    return null;
  });
