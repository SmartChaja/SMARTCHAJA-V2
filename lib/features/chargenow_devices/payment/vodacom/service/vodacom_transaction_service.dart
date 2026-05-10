import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

/// Service for managing Vodacom payment transactions and wallet balance updates
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
  ///
  /// Returns: Transaction document ID for future reference
  /// Throws: Exception if user not found or save fails
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
      print(
          '[VodacomTransaction] ✓ Saved pending transaction: $transactionDocId');
      return transactionDocId;
    } catch (e) {
      print('[VodacomTransaction] ✗ Error saving transaction: $e');
      rethrow;
    }
  }

  /// Saves a failed transaction so rejected or abandoned payment attempts
  /// still appear in Firestore and can be reviewed later.
  Future<String> saveFailedTransaction({
    required double amount,
    required String currency,
    required String transactionId,
    required String conversationId,
    required String thirdPartyConversationId,
    required String responseCode,
    required String responseDesc,
    String? failureReason,
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
      'status': 'failed',
      'transactionId': transactionId,
      'conversationId': conversationId,
      'thirdPartyConversationId': thirdPartyConversationId,
      'responseCode': responseCode,
      'responseDesc': responseDesc,
      'failureReason': failureReason ?? responseDesc,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      await _firestore
          .collection('transactions')
          .doc(transactionDocId)
          .set(transactionData);
      print(
          '[VodacomTransaction] ✓ Saved failed transaction: $transactionDocId');
      return transactionDocId;
    } catch (e) {
      print('[VodacomTransaction] ✗ Error saving failed transaction: $e');
      rethrow;
    }
  }

  /// Updates transaction status to confirmed and adds amount to user's balance
  /// Uses Firestore transaction for atomicity
  ///
  /// This is called by:
  /// 1. Cloud Function callback handler (azynchronous payment)
  /// 2. Direct call for synchronous payments
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

        // Update transaction status to confirmed
        transaction.update(transactionRef, {
          'status': 'confirmed',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Update user balance (add payment amount for top-up)
        transaction.update(userRef, {
          'balance': newBalance,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        print(
            '[VodacomTransaction] ✓ Confirmed transaction: Balance $currentBalance → $newBalance TZS');
      });
    } catch (e) {
      print('[VodacomTransaction] ✗ Error confirming transaction: $e');
      rethrow;
    }
  }

  /// Marks transaction as failed if payment fails
  /// Called when Vodacom returns error response codes
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

  /// Gets transaction details by ID
  Future<Map<String, dynamic>?> getTransaction(String transactionDocId) async {
    try {
      final doc = await _firestore
          .collection('transactions')
          .doc(transactionDocId)
          .get();
      return doc.data();
    } catch (e) {
      print('[VodacomTransaction] ✗ Error fetching transaction: $e');
      return null;
    }
  }

  /// Gets all transactions for current user
  Future<List<Map<String, dynamic>>> getUserTransactions({
    required String userId,
    String? provider,
    String? status,
  }) async {
    try {
      Query query = _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true);

      if (provider != null) {
        query = query.where('provider', isEqualTo: provider);
      }

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('[VodacomTransaction] ✗ Error fetching user transactions: $e');
      return [];
    }
  }

  /// Gets current user's balance
  Future<double> getUserBalance(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        print('[VodacomTransaction] ✗ User not found: $userId');
        return 0.0;
      }
      return (userDoc.data()?['balance'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      print('[VodacomTransaction] ✗ Error fetching user balance: $e');
      return 0.0;
    }
  }
}
