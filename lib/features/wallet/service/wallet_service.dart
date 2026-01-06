// lib/features/wallet/service/wallet_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_chaja/features/chargenow_devices/payment/azam/model/transaction_model.dart'; // Adjust this path if your TransactionModel is in a different location

class WalletService {
  final FirebaseFirestore _firestore;

  WalletService(this._firestore);

  /// Deducts amount from user's balance and records an internal transaction.
  /// Returns true on success, false on failure or throws an exception for specific errors.
  Future<bool> deductBalance({
    required String userId,
    required double amount,
    required String currency,
    required String description, // e.g., "Power bank rent"
    String? deviceId, // To link transaction to rent order/device
  }) async {
    final userRef = _firestore.collection('users').doc(userId);
    final transactionsRef = _firestore.collection('transactions');

    try {
      await _firestore.runTransaction((transaction) async {
        final userSnapshot = await transaction.get(userRef);

        if (!userSnapshot.exists) {
          throw Exception("User profile not found.");
        }

        final currentUserData = userSnapshot.data();
        final currentBalance = (currentUserData?['balance'] as num?)?.toDouble() ?? 0.0;

        if (currentBalance < amount) {
          throw Exception("Insufficient balance.");
        }

        final newBalance = currentBalance - amount;

        // Update user's balance
        transaction.update(userRef, {'balance': newBalance});

        // Record the transaction
        final newTransactionId = transactionsRef.doc().id; // Generate new doc ID
        final newTransaction = TransactionModel(
          id: newTransactionId,
          userId: userId,
          amount: amount,
          currency: currency,
          provider: 'Smart Chaja Wallet', // Indicate internal deduction
          status: 'completed', // Status for successful deduction
          createdAt: DateTime.now(),
          externalId: deviceId, // Use externalId to link to the device being rented
          // transactionId and referenceId are typically for external payments, can be null here.
        );
        transaction.set(transactionsRef.doc(newTransaction.id), newTransaction.toMap());
      });
      return true;
    } on FirebaseException catch (e) {
      print("Firebase Error during wallet deduction: ${e.message}");
      throw Exception("Transaction failed: ${e.message}");
    } catch (e) {
      print("General Error during wallet deduction: ${e.toString()}");
      rethrow; // Re-throw to be caught by the UI layer for specific messages
    }
  }
}