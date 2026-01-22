/**
 * Cloud Function to verify OTP and generate a custom Firebase Auth token.
 * This allows using Beem Africa SMS for OTP verification while still
 * maintaining Firebase Auth session management.
 */

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const logger = require("firebase-functions/logger");

/**
 * Verifies OTP code from Firestore and returns a custom auth token.
 * The client can then use this token to sign in with Firebase Auth.
 */
exports.verifyOTPAndGetToken = onCall(async (request) => {
  const { phoneNumber, otpCode } = request.data;

  // Validate inputs
  if (!phoneNumber || !otpCode) {
    throw new HttpsError(
      "invalid-argument",
      "Phone number and OTP code are required.",
    );
  }

  // Clean phone number - ensure consistent format
  const cleanPhone = phoneNumber.replace(/\s+/g, "").trim();

  logger.info(`Verifying OTP for phone: ${cleanPhone}`);

  const db = admin.firestore();
  const otpDocRef = db.collection("otp_codes").doc(cleanPhone);

  try {
    const otpDoc = await otpDocRef.get();

    if (!otpDoc.exists) {
      throw new HttpsError(
        "not-found",
        "No OTP found for this phone number. Please request a new one.",
      );
    }

    const otpData = otpDoc.data();

    // Check if already verified
    if (otpData.verified === true) {
      throw new HttpsError(
        "failed-precondition",
        "This OTP has already been used. Please request a new one.",
      );
    }

    // Check expiration
    const expiresAt = otpData.expiresAt.toDate();
    if (new Date() > expiresAt) {
      await otpDocRef.delete();
      throw new HttpsError(
        "deadline-exceeded",
        "OTP has expired. Please request a new one.",
      );
    }

    // Check attempts
    const attempts = otpData.attempts || 0;
    if (attempts >= 5) {
      await otpDocRef.delete();
      throw new HttpsError(
        "resource-exhausted",
        "Too many failed attempts. Please request a new OTP.",
      );
    }

    // Verify OTP code
    if (otpData.code !== otpCode) {
      // Increment attempts
      await otpDocRef.update({
        attempts: admin.firestore.FieldValue.increment(1),
      });
      const remaining = 4 - attempts;
      throw new HttpsError(
        "permission-denied",
        `Invalid OTP code. ${remaining} attempts remaining.`,
      );
    }

    // OTP is valid! Mark as verified
    await otpDocRef.update({
      verified: true,
      verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    logger.info(`OTP verified successfully for ${cleanPhone}`);

    // Generate a unique UID based on phone number (new logic)
    const newUid = `phone_${cleanPhone.replace(/\+/g, "")}`;
    let userRecord;
    let usedUid = newUid;
    try {
      // Try new UID logic first
      userRecord = await admin.auth().getUser(newUid);
      logger.info(`Existing user found: ${newUid}`);
      // If phone number is different, update it
      if (userRecord.phoneNumber !== (cleanPhone.startsWith("+") ? cleanPhone : `+${cleanPhone}`)) {
        await admin.auth().updateUser(newUid, {
          phoneNumber: cleanPhone.startsWith("+") ? cleanPhone : `+${cleanPhone}`,
        });
        logger.info(`Updated phone number for user: ${newUid}`);
        userRecord = await admin.auth().getUser(newUid); // Refresh user record
      }
    } catch (error) {
      if (error.code === "auth/user-not-found") {
        // Try to find user by phone number (old user)
        try {
          userRecord = await admin.auth().getUserByPhoneNumber(
            cleanPhone.startsWith("+") ? cleanPhone : `+${cleanPhone}`,
          );
          usedUid = userRecord.uid;
          logger.info(
            `Found old user by phone number: ${userRecord.uid}`,
          );
        } catch (err2) {
          if (err2.code === "auth/user-not-found") {
            // Create new user
            userRecord = await admin.auth().createUser({
              uid: newUid,
              phoneNumber: cleanPhone.startsWith("+") ? cleanPhone : `+${cleanPhone}`,
              disabled: false,
            });
            logger.info(`New user created: ${newUid}`);
            usedUid = newUid;
          } else {
            throw err2;
          }
        }
      } else if (error.code === "auth/phone-number-already-exists") {
        // Phone number already exists for another user, find and use that user
        userRecord = await admin.auth().getUserByPhoneNumber(
          cleanPhone.startsWith("+") ? cleanPhone : `+${cleanPhone}`,
        );
        usedUid = userRecord.uid;
        logger.info(
          `Found user by phone number: ${userRecord.uid}`,
        );
      } else {
        throw error;
      }
    }

    // Generate custom token for the actual UID (old or new)
    const customToken = await admin.auth().createCustomToken(
      usedUid,
      {
        phoneNumber: cleanPhone,
      },
    );

    logger.info(
      "Custom token generated for " + cleanPhone,
    );
    logger.info(
      "UID: " + usedUid,
    );

    // Split long logger lines if needed
    // logger.info(
    //   'Custom token generated for ' +
    //   cleanPhone +
    //   ' (UID: ' +
    //   usedUid +
    //   ')',
    // );

    // Clean up OTP document after successful verification
    await otpDocRef.delete();

    return {
      success: true,
      token: customToken,
      uid: usedUid,
      isNewUser: !userRecord.customClaims,
    };
  } catch (error) {
    if (error instanceof HttpsError) {
      throw error;
    }
    logger.error("Error verifying OTP:", error);
    throw new HttpsError("internal", "An error occurred during verification.");
  }
});

/**
 * Sends OTP via Beem Africa SMS.
 * This function generates, stores, and sends the OTP.
 */
exports.sendOTP = onCall(async (request) => {
  const { phoneNumber } = request.data;

  if (!phoneNumber) {
    throw new HttpsError("invalid-argument", "Phone number is required.");
  }

  // Clean phone number
  let cleanPhone = phoneNumber.replace(/\s+/g, "").trim();

  // Ensure phone has country code
  if (cleanPhone.startsWith("0")) {
    cleanPhone = "255" + cleanPhone.substring(1);
  }
  if (!cleanPhone.startsWith("+") && !cleanPhone.startsWith("255")) {
    cleanPhone = "255" + cleanPhone;
  }

  logger.info(`Sending OTP to: ${cleanPhone}`);

  const db = admin.firestore();
  const otpDocRef = db.collection("otp_codes").doc(cleanPhone);

  // DEMO ACCOUNT BYPASS: If this is the demo account, use default OTP and skip Beem Africa
  const DEMO_PHONE = "+255123456789"; // Updated to match your demo account
  const DEMO_OTP = "123456"; // Change to your default OTP if needed
  if (cleanPhone === DEMO_PHONE || cleanPhone === DEMO_PHONE.replace("+", "")) {
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes
    await otpDocRef.set({
      code: DEMO_OTP,
      phoneNumber: cleanPhone,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      expiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
      verified: false,
      attempts: 0,
    });
    logger.info(`Demo account detected, default OTP set for ${cleanPhone}`);
    return {
      success: true,
      message: "Demo OTP set (no SMS sent)",
      phoneNumber: cleanPhone,
    };
  }

  // Generate 6-digit OTP
  const otpCode = Math.floor(100000 + Math.random() * 900000).toString();
  const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

  // Store OTP in Firestore
  await otpDocRef.set({
    code: otpCode,
    phoneNumber: cleanPhone,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    expiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
    verified: false,
    attempts: 0,
  });
  // ...existing code...
  const configDoc = await db.collection("config").doc("beem_africa").get();
  let beemConfig;


  if (configDoc.exists) {
    beemConfig = configDoc.data();
    console.log("DEBUG: Beem Africa config from Firestore:", beemConfig);
  } else {
    // Fallback to environment variables or hardcoded (not recommended for production)
    beemConfig = {
      apiKey: process.env.BEEM_API_KEY || "247b432f75dbf2cd",
      secretKey: process.env.BEEM_SECRET_KEY ||
        "YTA3Zjg0NmFiZDhlMGZmZTc5YzRhMTk0ZDViZDQwMjE1ZmY4Njc0ZjU5MzVmZDcwMDc1NjdmOGMwYzE5OTQ4Ng==",
      senderId: process.env.BEEM_SENDER_ID || "SmartChaja",
    };
    console.log("DEBUG: Beem Africa config from ENV:", beemConfig);
  }

  if (!beemConfig.apiKey || !beemConfig.secretKey) {
    logger.error("Beem Africa credentials not configured. beemConfig:", beemConfig);
    throw new HttpsError("failed-precondition", "SMS service not configured.");
  }

  // Send SMS via Beem Africa
  const message = `Your Smart Chaja verification code is: ${otpCode}. Valid for 10 minutes.`;

  try {
    const credentials = Buffer.from(
      `${beemConfig.apiKey}:${beemConfig.secretKey}`,
    ).toString("base64");

    const response = await fetch("https://apisms.beem.africa/v1/send", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Basic ${credentials}`,
      },
      body: JSON.stringify({
        source_addr: beemConfig.senderId,
        encoding: 0,
        message: message,
        recipients: [
          {
            recipient_id: 1,
            dest_addr: cleanPhone.replace("+", ""),
          },
        ],
      }),
    });

    const result = await response.json();

    if (result.successful === true) {
      logger.info(`OTP SMS sent successfully to ${cleanPhone}`);
      return {
        success: true,
        message: "OTP sent successfully",
        phoneNumber: cleanPhone,
      };
    } else {
      logger.error("Beem Africa SMS failed:", result);
      // Clean up the stored OTP since SMS failed
      await otpDocRef.delete();
      throw new HttpsError("internal", "Failed to send SMS. Please try again.");
    }
  } catch (error) {
    logger.error("Error sending SMS:", error);
    await otpDocRef.delete();
    throw new HttpsError("internal", "Failed to send SMS. Please try again.");
  }
});
