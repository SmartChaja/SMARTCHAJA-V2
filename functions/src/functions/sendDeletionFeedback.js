const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

// Create a Nodemailer transporter using Gmail
// You'll need to set environment variables for email credentials
const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: process.env.EMAIL_USER || "your-email@gmail.com",
    pass: process.env.EMAIL_PASSWORD || "your-app-password",
  },
});

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

    // Create email content
    const emailContent = `
        <h2>Account Deletion Feedback</h2>
        <p><strong>User ID:</strong> ${userId}</p>
        <p><strong>User Email:</strong> ${userEmail}</p>
        <p><strong>Phone Number:</strong> ${phoneNumber}</p>
        <p><strong>Deletion Time:</strong> ${timestamp}</p>
        <hr>
        <h3>User Feedback:</h3>
        <p>${feedback}</p>
      `;

    // Send email
    await transporter.sendMail({
      from: process.env.EMAIL_USER || "your-email@gmail.com",
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
