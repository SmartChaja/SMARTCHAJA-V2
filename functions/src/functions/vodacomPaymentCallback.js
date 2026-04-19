const functions = require("firebase-functions");
const admin = require("firebase-admin");
const logger = functions.logger;

if (!admin.apps.length) {
  admin.initializeApp();
}

// eslint-disable-next-line no-unused-vars
exports.vodacomPaymentCallback = functions.https.onRequest(
  async (req, res) => {
    // Validate request method
    if (req.method !== "POST") {
      logger.warn(`Invalid HTTP method: ${req.method}`);
      return res.status(405).send("Method Not Allowed");
    }

    try {
      const body = req.body;
      const responseCode = body.output_ResponseCode;
      const responseDesc = body.output_ResponseDesc;
      const transactionId = body.output_TransactionID;
      const conversationId = body.output_ConversationID;
      const thirdPartyConversationId = body.output_ThirdPartyConversationID;

      logger.info("Vodacom callback received", {
        responseCode,
        transactionId,
        conversationId,
        thirdPartyConversationId,
      });

      // Validate required payload fields
      if (!thirdPartyConversationId) {
        logger.error("Missing thirdPartyConversationId in callback");
        return res.status(400).json({
          output_ResponseCode: "400",
          output_ResponseDesc: "Missing thirdPartyConversationID",
        });
      }

      const transactionDocId = thirdPartyConversationId;

      // Get transaction from Firestore
      const transactionRef = admin
        .firestore()
        .collection("transactions")
        .doc(transactionDocId);
      const transactionDoc = await transactionRef.get();

      if (!transactionDoc.exists) {
        logger.error(`Transaction not found: ${transactionDocId}`, {
          provider: "Vodacom",
        });
        return res.status(404).json({
          output_ResponseCode: "404",
          output_ResponseDesc: "Transaction not found",
          output_ThirdPartyConversationID: thirdPartyConversationId,
        });
      }

      const transactionData = transactionDoc.data();
      const userId = transactionData.userId;
      const amount = transactionData.amount;

      // Verify provider is Vodacom
      if (transactionData.provider !== "Vodacom") {
        logger.error(
          `Transaction provider mismatch: ${transactionData.provider}`,
          { transactionId: transactionDocId },
        );
        return res.status(400).json({
          output_ResponseCode: "400",
          output_ResponseDesc: "Provider mismatch",
        });
      }

      // Determine status based on Vodacom response code
      // INS-0 = Success, all others are failures/errors
      let status = "failed";
      if (responseCode === "INS-0") {
        status = "confirmed";
      }

      logger.info(`Processing Vodacom transaction ${transactionDocId}`, {
        status,
        responseCode,
        amount,
        userId,
      });

      // Execute atomic transaction
      await admin.firestore().runTransaction(async (transaction) => {
        // Update transaction record
        transaction.update(transactionRef, {
          status,
          transactionId: transactionId || transactionData.transactionId,
          conversationId: conversationId || transactionData.conversationId,
          responseCode,
          responseDesc,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          vodacomCallbackResponse: body,
        });

        // If confirmed, update user balance
        if (status === "confirmed") {
          const userRef = admin.firestore().collection("users").doc(userId);
          const userDoc = await transaction.get(userRef);

          if (!userDoc.exists) {
            throw new Error(`User not found: ${userId}`);
          }

          const currentBalance = userDoc.data().balance || 0;
          const newBalance = currentBalance + amount;

          transaction.update(userRef, {
            balance: newBalance,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          logger.info(`Balance updated for user ${userId}`, {
            oldBalance: currentBalance,
            newBalance,
            transactionAmount: amount,
          });
        }
      });

      logger.info("Vodacom callback processed successfully", {
        transactionId: transactionDocId,
        status,
        amount,
      });

      // Send confirmation response to Vodacom as required by API
      return res.status(200).json({
        output_OriginalConversationID: conversationId,
        output_ResponseCode: "0",
        output_ResponseDesc: "Successfully Accepted Result",
        output_ThirdPartyConversationID: thirdPartyConversationId,
      });
    } catch (error) {
      logger.error("Vodacom callback processing error", {
        error: error.message,
        stack: error.stack,
      });

      return res.status(500).json({
        output_ResponseCode: "500",
        output_ResponseDesc: `Error processing callback: ${error.message}`,
      });
    }
  },
);
