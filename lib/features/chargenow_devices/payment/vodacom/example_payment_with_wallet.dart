/// Example: Vodacom Payment with Wallet Integration
///
/// This shows how to use the Vodacom payment system with transaction saving
/// and wallet balance updates when payment is successful.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VodacomPaymentWithWalletExample extends ConsumerWidget {
  const VodacomPaymentWithWalletExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vodacom Payment - Wallet Integration')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _handlePaymentWithWallet(context, ref),
              child: const Text('Pay & Update Wallet'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _checkTransactionStatus(context, ref),
              child: const Text('Check Transaction Status'),
            ),
          ],
        ),
      ),
    );
  }

  /// Example 1: Complete payment flow with wallet integration
  /// This performs payment and saves transaction record
  Future<void> _handlePaymentWithWallet(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      // Step 1: Initiate payment
      print('[Example] Starting Vodacom payment...');

      final paymentNotifier =
          ref.read(vodacomPaymentViewModelProvider.notifier);

      // Perform C2B payment
      await paymentNotifier.performC2BPayment(
        amount: '1000.00', // Amount in customer's currency (TZS)
        customerMsisdn: '255707161122', // Full MSISDN format
        serviceProviderCode: 'ORG001',
        transactionReference: 'TOP_UP_001',
        purchasedItemsDesc: 'Wallet Top-up',
      );

      // Step 2: Listen for payment result
      ref.listen<AsyncValue<VodacomPaymentOperationResult?>>(
        vodacomPaymentViewModelProvider,
        (previous, next) async {
          next.whenData((result) async {
            if (result != null && result.isSuccess) {
              print('[Example] ✓ Payment successful!');
              print('[Example] Transaction ID: ${result.transactionId}');
              print('[Example] Conversation ID: ${result.conversationId}');

              // Step 3: Save transaction record to Firestore
              // This marks the transaction as 'pending' and waits for confirmation
              final transactionService =
                  ref.read(vodacomTransactionServiceProvider);

              final transactionDocId =
                  await paymentNotifier.saveTransactionRecord(
                amount: double.parse(result.amount ?? '0'),
                currency: result.currency ?? 'TZS',
                transactionId: result.transactionId ?? '',
                conversationId: result.conversationId ?? '',
                thirdPartyConversationId: result.thirdPartyConversationId ?? '',
                responseCode: result.responseCode ?? 'INS-0',
                responseDesc: result.responseDesc ?? 'Success',
                transactionService: transactionService,
              );

              if (transactionDocId != null) {
                print('[Example] ✓ Transaction saved: $transactionDocId');

                // Step 4: For synchronous payments, confirm immediately
                // For async payments, wait for Cloud Function callback
                // Here we confirm immediately if response code is INS-0
                if (result.responseCode == 'INS-0') {
                  final confirmed =
                      await paymentNotifier.confirmTransactionBalance(
                    transactionDocId: transactionDocId,
                    amount: double.parse(result.amount ?? '0'),
                    transactionService: transactionService,
                  );

                  if (confirmed) {
                    print('[Example] ✓ Wallet balance updated!');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Payment successful! ${result.amount} ${result.currency} credited to wallet.',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                }
              }
            } else if (result != null) {
              print('[Example] ✗ Payment failed: ${result.message}');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Payment failed: ${result.message}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          }).whenError((error, stack) {
            print('[Example] ✗ Error: $error');
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: $error'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          });
        },
      );
    } catch (e) {
      print('[Example] ✗ Exception: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Example 2: Check transaction status
  Future<void> _checkTransactionStatus(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      final paymentNotifier =
          ref.read(vodacomPaymentViewModelProvider.notifier);

      // You would typically get this from a previous transaction
      const conversationId = 'fd1e9143d22544459f7c66e1860ef276';

      await paymentNotifier.queryTransactionStatus(
        conversationId: conversationId,
      );

      ref.listen<AsyncValue<VodacomPaymentOperationResult?>>(
        vodacomPaymentViewModelProvider,
        (previous, next) {
          next.whenData((result) {
            if (result != null && result.isSuccess) {
              print('[Example] Transaction still pending/active');
            } else if (result != null) {
              print('[Example] Transaction error: ${result.message}');
            }
          });
        },
      );
    } catch (e) {
      print('[Example] Error checking status: $e');
    }
  }
}

// Import statements needed:
/*
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'path/to/vodacom_payment_view_model.dart';
import 'path/to/vodacom_payment_providers.dart';
import 'path/to/vodacom_payment_result.dart';
import 'path/to/vodacom_transaction_service.dart';
*/

/// ============================================================================
/// PAYMENT FLOW EXPLANATION
/// ============================================================================

/// 1. USER INITIATES PAYMENT
/// └─> Calls performC2BPayment() with amount, phone number, etc.

/// 2. GENERATE SESSION KEY
/// └─> Service calls Vodacom getSession endpoint
/// └─> Waits 30 seconds for session to become active
/// └─> Returns sessionId

/// 3. PERFORM C2B PAYMENT
/// └─> Service calls Vodacom c2bPayment endpoint with sessionId
/// └─> Vodacom returns immediate response:
///     ├─ Status 201 + INS-0 = Success (payment initiated)
///     ├─ Status 201 + Other code = Pending/Waiting for customer
///     └─ Status 400+ = Failed

/// 4. SAVE TRANSACTION RECORD
/// └─> SaveTransactionRecord() creates Firestore doc for tracking
/// └─> Status: 'pending' (waiting for final confirmation)
/// └─> Includes all Vodacom response details

/// 5. CONFIRM BALANCE (Depends on sync vs async)
///
/// FOR SYNCHRONOUS RESPONSE (response code INS-0):
/// └─> Immediately call confirmTransactionBalance()
/// └─> Updates transaction status to 'confirmed'
/// └─> ADDS payment amount to user's balance
/// └─> User sees balance update immediately

/// FOR ASYNCHRONOUS RESPONSE (waiting for callback):
/// └─> Wait for Vodacom to send callback via Cloud Function
/// └─> Cloud Function verifies response code
/// └─> If INS-0: Update transaction + balance
/// └─> If other: Update transaction + mark as failed
/// └─> User balance updates when callback received

/// ============================================================================
/// TRANSACTION STATES
/// ============================================================================

/// Initial: Payment requested
/// ↓
/// Pending: Transaction saved, awaiting confirmation
/// ├─ For sync payments: Brief state, immediately → confirmed
/// ├─ For async payments: Waits for callback
/// └─ Timeout: Could fail if callback never received
/// ↓
/// Confirmed: Balance added to user account ✓
/// ↓
/// Failed: Payment declined or error occurred ✗

/// ============================================================================
/// DATABASE STRUCTURE
/// ============================================================================

/// Firestore:
/// users/{userId}
/// ├── balance: 5000.00 (double)  ← UPDATED HERE
/// ├── currency: "TZS"
/// └── updatedAt: Timestamp
///
/// transactions/{transactionDocId}
/// ├── id: "doc_id"
/// ├── userId: "user123"
/// ├── amount: 1000.00 (double)
/// ├── currency: "TZS"
/// ├── provider: "Vodacom"
/// ├── status: "pending|confirmed|failed"  ← UPDATED BY CALLBACK
/// ├── transactionId: "hv9ahxcg4ccv"
/// ├── conversationId: "fd1e9143d22544459f7c66e1860ef276"
/// ├── thirdPartyConversationId: "user_provided_id"
/// ├── responseCode: "INS-0"  ← Success code
/// ├── responseDesc: "Request processed successfully"
/// ├── createdAt: Timestamp
/// └── updatedAt: Timestamp

/// ============================================================================
/// CLOUD FUNCTION FLOW (Async Payments)
/// ============================================================================

/// Vodacom Gateway calls Cloud Function:
/// POST /vodacomPaymentCallback
/// ├── Receives callback with response codes
/// ├── Finds transaction in Firestore
/// ├── Checks response code:
/// │  ├─ INS-0: Mark as 'confirmed'
/// │  └─ Other: Mark as 'failed'
/// └─ If confirmed:
///    └─ Atomically update:
///       ├─ transaction.status = 'confirmed'
///       └─ users.balance += amount ✓

/// ============================================================================
