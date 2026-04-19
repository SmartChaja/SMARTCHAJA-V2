# Vodacom Payment - Wallet Integration Guide

## Overview

When a Vodacom C2B payment is successful, you need to:

1. **Record the transaction** in Firestore (`transactions` collection)
2. **Update user balance** after payment confirmation
3. **Handle callbacks** for asynchronous payments

## Pattern Used in App

The app follows this flow (same as Azam payment):

### Synchronous Flow (Wallet Top-Up)

```
User initiates payment
    ↓
Payment request sent to Vodacom API
    ↓
API returns immediate response (status 201 or 400)
    ↓
If success:
  - Save transaction with status: 'pending' (immediate)
  - Display success to user (immediate)
  - CloudFunction callback later confirms and updates balance
    ↓
If failed:
  - Show error, don't save transaction
```

### Asynchronous Flow (External Payment Confirmation)

```
User initiates payment
    ↓
Vodacom API returns "Request accepted" (status 201)
    ↓
Save transaction with status: 'pending'
    ↓
Vodacom Gateway processes payment
    ↓
Vodacom sends callback (webhook) to your backend
    ↓
CloudFunction processes callback
    ↓
On confirmation: Update balance + transaction status
```

---

## Firestore Schema

### `users` collection

```dart
users/{userId}
├── balance: 5000.00 (double)
├── currency: "TZS"
├── updatedAt: Timestamp
└── ...
```

### `transactions` collection

```dart
transactions/{transactionDocId}
├── id: "unique_id" (string)
├── userId: "user123" (string)
├── amount: 100.00 (double)
├── currency: "TZS" (string)
├── provider: "Vodacom" (string)
├── status: "pending|confirmed|failed" (string)
├── transactionId: "hv9ahxcg4ccv" (string - from Vodacom)
├── conversationId: "fd1e9143d22544459f7c66e1860ef276" (string - from Vodacom)
├── thirdPartyConversationId: "..." (string - from Vodacom)
├── transactionDocId: "..." (string - for reference)
├── createdAt: Timestamp
├── updatedAt: Timestamp (optional)
└── additionalProperties: {...}
```

---

## Implementation Steps

### Step 1: Create Transaction Service

Create `lib/features/chargenow_devices/payment/vodacom/service/vodacom_transaction_service.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../model/vodacom_payment_model.dart';

class VodacomTransactionService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  VodacomTransactionService({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  /// Saves a pending transaction after successful Vodacom API response
  /// This creates the transaction record before balance update confirmation
  Future<String> savePendingTransaction({
    required double amount,
    required String currency,
    required String transactionId,
    required String conversationId,
    required String thirdPartyConversationId,
    required String responseCode,
    required String responseDesc,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user found');
    }

    final transactionDocId = const Uuid().v4();

    final transactionData = {
      'id': transactionDocId,
      'userId': user.uid,
      'amount': amount,
      'currency': currency,
      'provider': 'Vodacom',
      'status': 'pending', // Will be confirmed by callback
      'transactionId': transactionId,
      'conversationId': conversationId,
      'thirdPartyConversationId': thirdPartyConversationId,
      'responseCode': responseCode,
      'responseDesc': responseDesc,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      await _firestore
          .collection('transactions')
          .doc(transactionDocId)
          .set(transactionData);
      print('[VodacomTransaction] ✓ Saved transaction: $transactionDocId');
      return transactionDocId;
    } catch (e) {
      print('[VodacomTransaction] ✗ Error saving transaction: $e');
      rethrow;
    }
  }

  /// Updates transaction status and balance when payment is confirmed
  /// This is called by the callback function or directly for sync payments
  Future<void> confirmTransaction({
    required String transactionDocId,
    required String userId,
    required double amount,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final userRef = _firestore.collection('users').doc(userId);
        final transactionRef =
            _firestore.collection('transactions').doc(transactionDocId);

        // Get current user data
        final userDoc = await transaction.get(userRef);
        if (!userDoc.exists) {
          throw Exception('User not found');
        }

        final currentBalance =
            (userDoc.data()?['balance'] as num?)?.toDouble() ?? 0.0;
        final newBalance = currentBalance + amount;

        // Update transaction status
        transaction.update(transactionRef, {
          'status': 'confirmed',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Update user balance
        transaction.update(userRef, {
          'balance': newBalance,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        print(
            '[VodacomTransaction] ✓ Confirmed: Balance $currentBalance → $newBalance');
      });
    } catch (e) {
      print('[VodacomTransaction] ✗ Error confirming transaction: $e');
      rethrow;
    }
  }

  /// Marks transaction as failed if payment fails
  Future<void> failTransaction({
    required String transactionDocId,
    required String reason,
  }) async {
    try {
      await _firestore.collection('transactions').doc(transactionDocId).update({
        'status': 'failed',
        'failureReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('[VodacomTransaction] ✓ Failed transaction: $transactionDocId');
    } catch (e) {
      print('[VodacomTransaction] ✗ Error failing transaction: $e');
      rethrow;
    }
  }
}
```

---

### Step 2: Add Transaction Service to Providers

Update `lib/features/chargenow_devices/payment/vodacom/provider/vodacom_payment_providers.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../response/vodacom_payment_result.dart';
import '../service/vodacom_payment_service.dart';
import '../service/vodacom_transaction_service.dart';
import '../view_model/vodacom_payment_view_model.dart';

// ... existing code ...

/// Provides the Vodacom Transaction Service
final vodacomTransactionServiceProvider =
    Provider<VodacomTransactionService>((ref) {
  return VodacomTransactionService(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});

/// Provides the Vodacom Payment ViewModel with transaction handling
final vodacomPaymentViewModelProvider = StateNotifierProvider<
    VodacomPaymentViewModel, AsyncValue<VodacomPaymentOperationResult?>>((ref) {
  final paymentService = ref.watch(vodacomPaymentServiceProvider);
  final transactionService = ref.watch(vodacomTransactionServiceProvider);
  return VodacomPaymentViewModel(paymentService, transactionService);
});
```

---

### Step 3: Update Payment ViewModel

Update `lib/features/chargenow_devices/payment/vodacom/view_model/vodacom_payment_view_model.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../response/vodacom_payment_result.dart';
import '../service/vodacom_payment_service.dart';
import '../service/vodacom_transaction_service.dart';

class VodacomPaymentViewModel
    extends StateNotifier<AsyncValue<VodacomPaymentOperationResult?>> {
  final VodacomPaymentService _paymentService;
  final VodacomTransactionService _transactionService;

  VodacomPaymentViewModel(
    this._paymentService,
    this._transactionService,
  ) : super(const AsyncValue.data(null));

  /// Handles the complete payment flow with wallet update
  Future<void> processPayment({
    required String amount,
    required String customerMsisdn,
    required String transactionReference,
    required String purchasedItemsDesc,
  }) async {
    state = const AsyncValue.loading();

    try {
      // Step 1: Generate session key
      final sessionResponse = await _paymentService.generateSessionKey();
      if (!sessionResponse.isSuccess) {
        state = AsyncValue.data(
          VodacomPaymentOperationResult(
            isSuccess: false,
            message: sessionResponse.errorMessage,
            provider: 'Vodacom',
          ),
        );
        return;
      }

      // Step 2: Perform payment
      final paymentResult = await _paymentService.performC2BPayment(
        sessionKey: sessionResponse.sessionId,
        amount: amount,
        customerMsisdn: customerMsisdn,
        transactionReference: transactionReference,
        purchasedItemsDesc: purchasedItemsDesc,
      );

      if (!paymentResult.isSuccess) {
        state = AsyncValue.data(paymentResult);
        return;
      }

      // Step 3: Save transaction record (status: pending until confirmed)
      try {
        final transactionDocId = await _transactionService.savePendingTransaction(
          amount: double.parse(amount),
          currency: paymentResult.currency ?? 'TZS',
          transactionId: paymentResult.transactionId ?? '',
          conversationId: paymentResult.conversationId ?? '',
          thirdPartyConversationId:
              paymentResult.thirdPartyConversationId ?? '',
          responseCode: paymentResult.responseCode ?? 'INS-0',
          responseDesc: paymentResult.responseDesc ?? 'Success',
        );

        // Step 4: For synchronous payments, confirm immediately
        // For asynchronous payments, wait for callback
        if (paymentResult.isSuccess) {
          // Check response code - INS-0 means successful
          if (paymentResult.responseCode == 'INS-0' ||
              paymentResult.responseCode?.startsWith('INS-0') == true) {
            await _transactionService.confirmTransaction(
              transactionDocId: transactionDocId,
              userId: 'current_user_id', // Get from Firebase Auth
              amount: double.parse(amount),
            );
          }
        }

        state = AsyncValue.data(
          paymentResult.copyWith(transactionDocId: transactionDocId),
        );
      } catch (e) {
        print('[VodacomPayment] Error in transaction handling: $e');
        state = AsyncValue.data(
          paymentResult.copyWith(
            message:
                '${paymentResult.message} (Note: Transaction saved but not confirmed)',
          ),
        );
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}
```

---

### Step 4: Create Firebase Cloud Function (Node.js)

Create `functions/src/functions/vodacomCallback.js`:

```javascript
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const logger = functions.logger;

if (!admin.apps.length) {
  admin.initializeApp();
}

/**
 * Handles asynchronous callbacks from Vodacom M-Pesa OpenAPI
 *
 * Expected payload:
 * {
 *   "output_ResponseCode": "INS-0",
 *   "output_ResponseDesc": "Request processed successfully",
 *   "output_TransactionID": "hv9ahxcg4ccv",
 *   "output_ConversationID": "fd1e9143d22544459f7c66e1860ef276",
 *   "output_ThirdPartyConversationID": "user_transaction_id"
 * }
 */
exports.vodacomPaymentCallback = functions.https.onRequest(async (req, res) => {
  // Validate request method
  if (req.method !== "POST") {
    return res.status(405).send("Method Not Allowed");
  }

  try {
    const {
      output_ResponseCode,
      output_ResponseDesc,
      output_TransactionID,
      output_ConversationID,
      output_ThirdPartyConversationID,
    } = req.body;

    logger.info("Vodacom callback received:", {
      responseCode: output_ResponseCode,
      transactionId: output_TransactionID,
      conversationId: output_ConversationID,
      thirdPartyConversationId: output_ThirdPartyConversationID,
    });

    // Validate payload
    if (!output_ThirdPartyConversationID) {
      logger.error("Missing thirdPartyConversationID in callback");
      return res.status(400).send("Missing thirdPartyConversationID");
    }

    const transactionDocId = output_ThirdPartyConversationID;

    // Get transaction from Firestore
    const transactionRef = admin
      .firestore()
      .collection("transactions")
      .doc(transactionDocId);
    const transactionDoc = await transactionRef.get();

    if (!transactionDoc.exists) {
      logger.error("Transaction not found: " + transactionDocId);
      return res.status(404).send("Transaction not found");
    }

    const transactionData = transactionDoc.data();
    const userId = transactionData.userId;
    const amount = transactionData.amount;

    // Determine status based on response code
    let status = "failed";
    if (output_ResponseCode === "INS-0") {
      status = "confirmed";
    }

    logger.info(
      `Processing transaction ${transactionDocId} with status: ${status}`,
    );

    // Update transaction record
    await transactionRef.update({
      status: status,
      transactionId: output_TransactionID || transactionData.transactionId,
      conversationId: output_ConversationID || transactionData.conversationId,
      responseCode: output_ResponseCode,
      responseDesc: output_ResponseDesc,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      vodacomCallbackResponse: req.body, // Store full response for auditing
    });

    // If confirmed, update user balance
    if (status === "confirmed") {
      const userRef = admin.firestore().collection("users").doc(userId);

      await admin.firestore().runTransaction(async (transaction) => {
        const userDoc = await transaction.get(userRef);
        if (!userDoc.exists) {
          throw new Error("User not found");
        }

        const currentBalance = userDoc.data().balance || 0;
        const newBalance = currentBalance + amount;

        transaction.update(userRef, {
          balance: newBalance,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        logger.info(
          `Balance updated for user ${userId}: ${currentBalance} → ${newBalance}`,
        );
      });
    }

    logger.info(`Vodacom callback processed: ${transactionDocId} → ${status}`);

    // Send confirmation response to Vodacom
    return res.status(200).json({
      output_OriginalConversationID: output_ConversationID,
      output_ResponseCode: "0",
      output_ResponseDesc: "Successfully Accepted Result",
      output_ThirdPartyConversationID: output_ThirdPartyConversationID,
    });
  } catch (error) {
    logger.error("Vodacom callback error:", error);
    return res.status(500).send(`Error processing callback: ${error.message}`);
  }
});
```

---

### Step 5: Register Cloud Function

In `functions/src/functions/index.js`:

```javascript
// Add to imports
exports.vodacomPaymentCallback =
  require("./vodacomCallback").vodacomPaymentCallback;
```

---

## Usage in UI

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VodacomPaymentScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        // Initiate payment
        await ref.read(vodacomPaymentViewModelProvider.notifier).processPayment(
          amount: '1000.00',
          customerMsisdn: '255707161122',
          transactionReference: 'TXN_001',
          purchasedItemsDesc: 'Wallet Top-up',
        );

        // Listen for result
        ref.listen(vodacomPaymentViewModelProvider, (previous, next) {
          next.whenData((result) {
            if (result != null && result.isSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Payment successful! ₨${result.amount} credited.',
                  ),
                ),
              );
            }
          });
        });
      },
      child: const Text('Top-up Wallet'),
    );
  }
}
```

---

## Key Differences: Vodacom vs Azam

| Aspect                   | Azam                        | Vodacom                                   |
| ------------------------ | --------------------------- | ----------------------------------------- |
| **Transaction Status**   | pending → confirmed         | pending → confirmed                       |
| **Balance Update**       | Via callback function       | Via callback function                     |
| **Response Code Format** | Various                     | INS-0 (success), INS-6 (failed), etc.     |
| **Callback Endpoint**    | `/azampayCallback`          | `/vodacomCallback` (needs to be deployed) |
| **Provider Name**        | Azam, Vodacom, Airtel, etc. | Always "Vodacom"                          |

---

## Testing

### Sandbox Testing

- Transactions will be saved as pending
- Manually update status in Firestore to "confirmed" to test balance update
- Verify balance increases in users collection

### Production Testing

- Follow same flow
- Callback from Vodacom will auto-update balance
- Monitor Firebase logs for callback receipt

---

## Security Considerations

1. **Validate callback origin** - Add IP whitelist for Vodacom servers
2. **Verify response codes** - Only accept INS-0 as success
3. **Idempotent updates** - Prevent duplicate balance updates if callback is received twice
4. **User authentication** - Ensure transaction belongs to authenticated user

---

## Troubleshooting

### Balance not updating

- Check if transaction status is "confirmed" in Firestore
- Verify Cloud Function is deployed and logs show callback received
- Check user document exists in Firestore

### Transaction not saved

- Verify user is authenticated
- Check Firestore security rules allow write to transactions collection
- Check console logs for permission errors

### Callback not received

- Verify Cloud Function URL is correct in Vodacom dashboard
- Ensure function is publicly accessible (not require auth)
- Check Firebase function logs for incoming requests
