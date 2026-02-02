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
async function sendSMS(phoneNumber, message) {
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
 * Cloud Function: Firestore trigger for rental status changes.
 * When a rental status changes to "returned", send SMS automatically.
 * This handles returns from remote charging stations.
 */
exports.sendReturnSMSOnStatusChange = functions.firestore.onDocumentUpdated(
  "rented_power_banks/{docId}",
  async (event) => {
    try {
      const beforeData = event.data.before.data();
      const afterData = event.data.after.data();

      // Check if status changed to "returned"
      const statusChanged =
        beforeData.status !== afterData.status &&
        afterData.status === "returned";

      if (!statusChanged) {
        console.log(
          `ℹ️ Status did not change to 'returned'. Current: ${afterData.status}`,
        );
        return { processed: false, reason: "Status not changed to returned" };
      }

      console.log(
        `📋 Rental ${event.params.docId} status changed to 'returned'`,
      );

      // Get phone number from rental record
      const phoneNumber = afterData.userPhoneNumber || "";
      const userName = afterData.userName || "User";
      const deviceId = afterData.deviceId || "Device";
      const tradeNo = afterData.tradeNo || "";

      if (!phoneNumber || phoneNumber.trim().isEmpty) {
        console.warn(
          `⚠️ No phone number for rental: ${event.params.docId}. SMS not sent.`,
        );
        return {
          processed: false,
          reason: "No phone number available",
        };
      }

      const message =
        "Power bank returned successfully. Thank you for choosing SmartChaja. We appreciate you and look forward to serving you again.";

      console.log(`📱 Sending return SMS to: ${phoneNumber}`);
      const smsSent = await sendSMS(phoneNumber, message);

      if (smsSent) {
        // Mark SMS as sent in Firestore
        await event.data.after.ref.update({
          returnSMSSent: true,
          returnSMSSentAt: new Date(),
        });

        console.log(
          `✅ Return SMS sent successfully for rental: ${event.params.docId}`,
        );
        return {
          processed: true,
          smsSent: true,
          phoneNumber: phoneNumber,
          tradeNo: tradeNo,
        };
      } else {
        console.error(`❌ Failed to send return SMS for rental: ${event.params.docId}`);
        return {
          processed: true,
          smsSent: false,
          reason: "Beem API failed",
        };
      }
    } catch (error) {
      console.error(`❌ Function error: ${error.message}`);
      throw error;
    }
  },
);
