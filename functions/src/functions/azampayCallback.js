
const {onRequest} = require("firebase-functions/v2/https");
const {logger} = require("firebase-functions");
const admin = require("firebase-admin");

/**
 * AzamPay payment callback handler
 */
module.exports = onRequest({maxInstances: 5}, async (req, res) => {
  logger.info("AzamPay Callback Payload:", req.body);
  try {
    const {
      message,
      transactionstatus,
      operator, reference,
      externalreference,
      utilityref,
      amount,
      transid,
      msisdn,
      mnoreference,
      submerchantAcc = null,
      additionalProperties = {},
    } = req.body;

    const userId = additionalProperties.userId;
    const transactionDocId = additionalProperties.transactionDocId;

    // Validate required fields
    if (!userId || !transactionDocId) {
      logger.error(
          "Missing userId or transactionDocId",
          {userId, transactionDocId},
      );
      return res.status(400).send("Missing userId or transactionDocId");
    }
    if (!reference || !transactionstatus) {
      logger.error(
          "Missing reference or transactionstatus",
          {reference, transactionstatus},
      );
      return res.status(400).send("Missing reference or transactionstatus");
    }

    const transactionRef = admin.firestore()
        .collection("transactions").doc(transactionDocId);
    const transactionDoc = await transactionRef.get();

    if (!transactionDoc.exists) {
      logger.error("Transaction not found:", transactionDocId);
      return res.status(404).send("Transaction not found");
    }

    if (transactionDoc.data().userId !== userId) {
      logger.error("User ID mismatch", {
        provided: userId,
        stored: transactionDoc.data().userId});
      return res.status(403).send("User ID mismatch");
    }

    // Map AzamPay transactionstatus to system status
    let status;
    switch (transactionstatus.toUpperCase()) {
      case "SUCCESS":
        status = "confirmed";
        break;
      case "FAILED":
        status = "failed";
        break;
      default: status = "pending";
    }

    // Log all extracted fields for auditing
    logger.info("AzamPay Callback Fields:", {
      message,
      transactionstatus,
      operator,
      reference,
      externalreference,
      utilityref,
      amount,
      transid,
      msisdn,
      mnoreference,
      submerchantAcc,
      additionalProperties,
    });

    // Prepare Firestore update aligned with TransactionModel
    const updateData = {
      status,
      transactionId: transid || transactionDoc.data().transactionId,
      referenceId: reference,
      externalId: externalreference || transactionDoc.data().externalId,
      amount: amount != null ? Number(amount) : transactionDoc.data().amount,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      additionalProperties: {
        message,
        operator,
        mnoreference,
        submerchantAcc,
        utilityReference: utilityref,
        msisdn, ...additionalProperties,
      },
      azamPayResponse: req.body, // full raw payload for auditing
    };

    await transactionRef.update(updateData);

    // If confirmed, update user balance atomically
    if (status === "confirmed") {
      const userRef = admin.firestore().collection("users").doc(userId);
      await admin.firestore().runTransaction(async (transaction) => {
        const userDoc = await transaction.get(userRef);
        if (!userDoc.exists) throw new Error("User not found");

        const currentBalance = userDoc.data().balance || 0;

        const topUpAmount = amount != null ?
          Number(amount) : transactionDoc.data().amount;
        const newBalance = currentBalance + topUpAmount;

        transaction.update(userRef, {
          balance: newBalance,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      });
    }


    logger.info(
        `Callback processed for transaction: ${transactionDocId} → ${status}`,
    );
    return res.status(200).send("Callback processed successfully");
  } catch (error) {
    logger.error("Callback processing error:", error);
    return res.status(500).send(`Error processing callback: ${error.message}`);
  }
});
