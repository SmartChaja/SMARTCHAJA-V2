const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

// Get email credentials
const getTransporter = () => {
  // Gmail app password WITH spaces (as displayed in Gmail settings)
  const emailUser = "smartchaja@gmail.com";
  const emailPass = "jfeq rkbu tpky idiy";

  console.log("📧 Using email:", emailUser);

  return nodemailer.createTransport({
    service: "gmail",
    auth: {
      user: emailUser,
      pass: emailPass,
    },
  });
};

/**
 * Cloud Function to send deletion feedback email
 * Called when a user deletes their account with feedback
 */
exports.sendDeletionFeedback = functions.https.onRequest(async (req, res) => {
  // Only allow POST requests
  if (req.method !== "POST") {
    return res.status(405).send("Method Not Allowed");
  }

  try {
    const {
      userId,
      userEmail,
      phoneNumber,
      feedback,
      timestamp,
      recipientEmail,
    } = req.body;

    // Validate required fields
    if (!userId || !feedback || !recipientEmail) {
      return res.status(400).send("Missing required fields");
    }

    // Get user's full name from Firestore
    let userFullName = "Unknown";
    try {
      const userDoc = await admin
        .firestore()
        .collection("users")
        .doc(userId)
        .get();
      if (userDoc.exists) {
        const userData = userDoc.data();
        userFullName = userData.fullName || userData.name || "Unknown";
      }
    } catch (e) {
      console.log("Could not fetch user full name:", e.message);
    }

    // Create email content
    const emailContent = `
        <h2>Account Deletion Feedback</h2>
        <p><strong>User Full Name:</strong> ${userFullName}</p>
        <p><strong>User Email:</strong> ${userEmail}</p>
        <p><strong>Phone Number:</strong> ${phoneNumber}</p>
        <p><strong>Deletion Time:</strong> ${timestamp}</p>
        <hr>
        <h3>User Feedback:</h3>
        <p>${feedback}</p>
      `;

    // Send email
    const transporter = getTransporter();
    await transporter.sendMail({
      from: "SmartChaja <smartchaja@gmail.com>",
      to: recipientEmail,
      subject: `Account Deletion Feedback - User ${userId}`,
      html: emailContent,
    });

    // Also save to database for audit trail
    await admin
      .firestore()
      .collection("email_logs")
      .add({
        type: "account_deletion_feedback",
        userId,
        userEmail,
        phoneNumber,
        feedback,
        timestamp: new Date(timestamp),
        emailSent: true,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

    res.status(200).json({
      success: true,
      message: "Feedback email sent successfully",
    });
  } catch (error) {
    console.error("Error sending feedback email:", error);

    // Log the error but still return success to the client
    // This way, account deletion succeeds even if email fails
    await admin.firestore().collection("email_logs").add({
      type: "account_deletion_feedback",
      error: error.message,
      timestamp: new Date(),
      emailSent: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    res.status(200).json({
      success: true,
      message: "Account deletion processed (email delivery status unknown)",
    });
  }
});
