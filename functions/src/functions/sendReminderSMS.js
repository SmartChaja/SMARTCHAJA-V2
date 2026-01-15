const functions = require("firebase-functions/v2");
const admin = require("firebase-admin");
const axios = require("axios");

// Beem Africa SMS API Configuration
const BEEM_API_KEY = "247b432f75dbf2cd";
const BEEM_SECRET_KEY =
  "YTA3Zjg0NmFiZDhlMGZmZTc5YzRhMTk0ZDViZDQwMjE1ZmY4Njc0ZjU5MzVmZDcwMDc1NjdmOGMwYzE5OTQ4Ng==";
const BEEM_SENDER_ID = "SmartChaja";
const BEEM_API_ENDPOINT = "https://apisms.beem.africa/v1/send";

/**
 * Format phone number to international format (Tanzania country code).
 * @param {string} phoneNumber - The phone number to format
 * @return {string} The formatted phone number with country code
 */
function formatPhoneNumber(phoneNumber) {
  let cleaned = phoneNumber.replace(/[^\d]/g, "");

  // Remove leading zero if present
  if (cleaned.startsWith("0")) {
    cleaned = cleaned.substring(1);
  }

  // Add Tanzania country code if not present
  if (!cleaned.startsWith("255")) {
    cleaned = "255" + cleaned;
  }

  return cleaned;
}

/**
 * Generate Basic Authentication header for Beem API.
 * @return {string} Basic auth header string
 */
function getBasicAuth() {
  const credentials = `${BEEM_API_KEY}:${BEEM_SECRET_KEY}`;
  const base64Credentials = Buffer.from(credentials).toString("base64");
  return `Basic ${base64Credentials}`;
}

/**
 * Send SMS via Beem Africa API.
 * @param {string} phoneNumber - The recipient phone number
 * @param {string} message - The SMS message text
 * @return {Promise<boolean>} True if SMS sent successfully, false otherwise
 */
async function sendReminderSMS(phoneNumber, message) {
  try {
    const formattedPhone = formatPhoneNumber(phoneNumber);

    const requestBody = {
      source_addr: BEEM_SENDER_ID,
      encoding: 0, // Plain text
      message: message,
      recipients: [
        {
          recipient_id: 1,
          dest_addr: formattedPhone,
        },
      ],
    };

    const response = await axios.post(BEEM_API_ENDPOINT, requestBody, {
      headers: {
        Authorization: getBasicAuth(),
        "Content-Type": "application/json",
      },
      timeout: 10000,
    });

    if (response.status === 200 && response.data.successful) {
      console.log(
        `✅ SMS sent: ${formattedPhone}. ID: ${response.data.request_id}`,
      );
      return true;
    }
    console.error(
      `❌ SMS failed: ${response.data.message}. Code: ${response.data.code}`,
    );
    return false;
  } catch (error) {
    console.error(`❌ Error sending SMS: ${error.message}`);
    return false;
  }
}

/**
 * Cloud Function: Check rentals ending soon and send reminders.
 * Scheduled to run every 5 minutes via Cloud Scheduler.
 * @return {Promise<Object>} Object with sentCount and failureCount
 */
exports.sendReminderSMSFunction = functions.scheduler.onSchedule(
  "every 5 minutes",
  async (context) => {
    try {
      console.log("📱 Starting reminder SMS check...");

      const db = admin.firestore();
      const now = new Date();

      // Calculate time range: 5 minutes from now (to check if reminder should be sent now)
      const fiveMinutesFromNow = new Date(now.getTime() + 5 * 60 * 1000);

      // Query rentals that:
      // 1. Reminder time is approaching (within next 5 minutes)
      // 2. Reminder SMS hasn't been sent yet
      const rentalsSnapshot = await db
        .collectionGroup("rentals")
        .where("reminderTime", ">=", now)
        .where("reminderTime", "<=", fiveMinutesFromNow)
        .where("reminderSMSSent", "==", false)
        .get();

      console.log(
        `Found ${rentalsSnapshot.docs.length} rentals needing reminders`,
      );

      let sentCount = 0;
      let failureCount = 0;

      // Send reminders for each rental
      for (const doc of rentalsSnapshot.docs) {
        const rentalData = doc.data();

        try {
          const reminderMessage =
            "SmartChaja Reminder: Your rental time is almost " +
            "over. Please return the power bank to any SmartChaja " +
            "station to avoid extra charges.";

          const phoneNumber = rentalData.userPhoneNumber || "";
          const reminderMinutes = rentalData.reminderMinutes || 15;

          if (phoneNumber) {
            const smsSent = await sendReminderSMS(phoneNumber, reminderMessage);

            if (smsSent) {
              // Mark reminder as sent in Firestore
              await doc.ref.update({
                reminderSMSSent: true,
                reminderSMSSentAt: new Date(),
              });

              console.log(
                `✅ Reminder sent for rental: ${doc.id} ` +
                `(${reminderMinutes} mins before end)`,
              );
              sentCount++;
            } else {
              failureCount++;
            }
          } else {
            console.warn(`⚠️ No phone number for rental: ${doc.id}`);
            failureCount++;
          }
        } catch (error) {
          console.error(
            `❌ Error processing rental ${doc.id}: ${error.message}`,
          );
          failureCount++;
        }
      }

      console.log(
        `📊 Reminder SMS Summary: Sent=${sentCount}, ` +
        `Failed=${failureCount}`,
      );
      return { sentCount, failureCount };
    } catch (error) {
      console.error(`❌ Function error: ${error.message}`);
      throw error;
    }
  },
);

/**
 * Callable function to manually send reminder SMS (for testing).
 * @param {Object} data - Request data containing phoneNumber and deviceId
 * @param {Object} context - Firebase context with auth info
 * @return {Promise<Object>} Response with success status and message
 */
exports.sendReminderSMSManual = functions.https.onCall(
  { enforceAppCheck: true },
  async (request) => {
    const data = request.data;
    const auth = request.auth;

    // Verify user is authenticated
    if (!auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated",
      );
    }

    try {
      const { phoneNumber } = data;

      if (!phoneNumber) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "Phone number is required",
        );
      }

      const message =
        "SmartChaja Reminder: Your rental time is almost " +
        "over. Please return the power bank to any SmartChaja " +
        "station to avoid extra charges.";

      const smsSent = await sendReminderSMS(phoneNumber, message);

      return {
        success: smsSent,
        message: smsSent ?
          "Reminder SMS sent successfully" :
          "Failed to send reminder SMS",
      };
    } catch (error) {
      console.error(`❌ Manual reminder error: ${error.message}`);
      throw new functions.https.HttpsError("internal", error.message);
    }
  },
);
