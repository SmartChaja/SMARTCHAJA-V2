const {onSchedule} = require("firebase-functions/v2/scheduler");
const {logger} = require("firebase-functions");
const {defineSecret} = require("firebase-functions/params");
const admin = require("firebase-admin");
const axios = require("axios");

// Secrets
const chargeNowUsername = defineSecret("CHARGENOW_USERNAME");
const chargeNowPassword = defineSecret("CHARGENOW_PASSWORD");

// Config
const CHARGENOW_API_BASE_URL =
    "https://developer.chargenow.top/cdb-open-api/v1";
const PENALTY_AMOUNT = 500;
const PENALTY_INTERVAL_HOURS = 3;
const TIMEZONE = "Africa/Dar_es_Salaam";

exports.checkOverdueRentals = onSchedule(
    {
      schedule: "every 3 hours",
      timeZone: TIMEZONE,
      secrets: [chargeNowUsername, chargeNowPassword],
      timeoutSeconds: 540,
      memory: "1GiB",
    },
    async () => {
      logger.info("Starting overdue rental check...");

      const db = admin.firestore();
      const now = new Date();
      const nowTimestamp = admin.firestore.Timestamp.fromDate(now);

      const rentalsRef = db.collection("rented_power_banks");
      const snapshot = await rentalsRef
          .where("status", "in", ["rented", "overdue"])
          .get();

      if (snapshot.empty) {
        logger.info("No active rentals found.");
        return;
      }

      logger.info(`Found ${snapshot.size} active rentals to process.`);

      const username = chargeNowUsername.value();
      const password = chargeNowPassword.value();
      const authHeader = `Basic ${
        Buffer.from(`${username}:${password}`).toString("base64")}`;

      const processPromises = snapshot.docs.map(async (doc) => {
        const rental = doc.data();
        const tradeNo = rental.tradeNo;
        const userId = rental.userId;

        try {
          // === 1. Check if returned via ChargeNow API ===
          let isReturned = false;
          try {
            const res = await axios.get(
                `${CHARGENOW_API_BASE_URL}/rent/order/detail`,
                {
                  params: {tradeNo},
                  headers: {
                    Authorization: authHeader,
                    Accept: "application/json",
                  },
                  timeout: 8000,
                },
            );

            if (res.data.code === 0 && res.data.data &&
                res.data.data.returnTime) {
              await doc.ref.update({
                status: "returned",
                actualReturnTime: admin.firestore.Timestamp.fromDate(
                    new Date(res.data.data.returnTime),
                ),
                updatedAt: nowTimestamp,
              });
              logger.info(`Rental ${tradeNo} returned. Status updated.`);
              isReturned = true;
            }
          } catch (apiErr) {
            logger.warn(
                `API check failed for ${tradeNo}:`, apiErr.message,
            );
          }

          if (isReturned) return;

          // === 2. Check if overdue & time for penalty ===
          const rentEndDate = rental.rentEndDate ?
              rental.rentEndDate.toDate() : null;
          if (!rentEndDate || now <= rentEndDate) {
            return; // Not overdue
          }

          const lastPenaltyAt = rental.lastPenaltyAt ?
              rental.lastPenaltyAt.toDate() : rentEndDate;
          const hoursSince = (now - lastPenaltyAt) / (1000 * 60 * 60);
          if (hoursSince < PENALTY_INTERVAL_HOURS) {
            return; // Not time yet
          }

          // === 3. Apply penalty + auto-settle debt ===
          const userRef = db.collection("users").doc(userId);
          const logRef = db.collection("penalty_logs").doc();

          await db.runTransaction(async (t) => {
            const userSnap = await t.get(userRef);
            if (!userSnap.exists) {
              logger.warn(`User ${userId} not found. Skipping penalty.`);
              return;
            }

            const user = userSnap.data();
            let balance = user.balance !== undefined ? user.balance : 0;
            let debt = user.debt !== undefined ? user.debt : 0;

            // Auto-settle debt if balance exists
            if (debt > 0 && balance > 0) {
              const settle = Math.min(debt, balance);
              balance -= settle;
              debt -= settle;
              logger.info(`Auto-settled ${settle} TZS debt for ${userId}`);
            }

            // Apply penalty
            let amountDeducted = 0;
            let status = "debt";

            if (balance >= PENALTY_AMOUNT) {
              balance -= PENALTY_AMOUNT;
              amountDeducted = PENALTY_AMOUNT;
              status = "deducted";
            } else {
              const needed = PENALTY_AMOUNT - balance;
              balance = 0;
              debt += needed;
              amountDeducted = needed;
              status = "debt";
            }

            // Update rental
            t.update(doc.ref, {
              lastPenaltyAt: nowTimestamp,
              status: rental.status === "rented" ? "overdue" : rental.status,
              updatedAt: nowTimestamp,
            });

            // Update user
            const userUpdates = {
              balance,
              totalPenalties: admin.firestore.FieldValue.increment(1),
              updatedAt: nowTimestamp,
            };
            if (debt > 0) {
              userUpdates.debt = debt;
            } else {
              userUpdates.debt = admin.firestore.FieldValue.delete();
            }
            t.update(userRef, userUpdates);

            // Log penalty
            t.set(logRef, {
              userId,
              tradeNo,
              amount: amountDeducted,
              status,
              timestamp: nowTimestamp,
            });

            logger.info(
                `Penalty applied: ${amountDeducted} TZS (${status}) ` +
                `for ${userId} | TradeNo: ${tradeNo}`,
            );
          });
        } catch (err) {
          logger.error(`Failed processing ${tradeNo}:`, err);
        }
      });

      await Promise.all(processPromises);
      logger.info("Overdue rental check completed.");
    },
);
