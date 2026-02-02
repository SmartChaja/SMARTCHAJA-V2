/**
 * Main functions entry point.
 * This file acts as a "barrel" or "table of contents", importing functions
 * from their own dedicated files in the `src/functions` directory and exporting
 * them for Firebase to discover and deploy.
 */

const admin = require("firebase-admin");

// Initialize the Firebase Admin SDK once here.
// All imported functions will share this single instance.
admin.initializeApp();

// Export the AzamPay callback function from its file.
exports.azampayCallbackUrl = require("./src/functions/azampayCallback");

// Export the scheduled function for checking overdue rentals from its file.
exports.checkOverdueRentals = require("./src/functions/checkOverdueRentals");
// Export the deletion feedback email function
exports.sendDeletionFeedback =
  require("./src/functions/sendDeletionFeedback").sendDeletionFeedback;
// Export the reminder SMS function
const reminderSMSFunctions = require("./src/functions/sendReminderSMS");
exports.sendReminderSMSFunction = reminderSMSFunctions.sendReminderSMSFunction;
exports.sendReminderSMSManual = reminderSMSFunctions.sendReminderSMSManual;

// Export the return SMS trigger function (fires when rental status changes to "returned")
exports.sendReturnSMSOnStatusChange = require("./src/functions/sendReturnSMS")
  .sendReturnSMSOnStatusChange;

// Export OTP verification and custom token functions (Beem Africa SMS)
const otpFunctions = require("./src/functions/verifyOTPAndGetToken");
exports.verifyOTPAndGetToken = otpFunctions.verifyOTPAndGetToken;
exports.sendOTP = otpFunctions.sendOTP;
