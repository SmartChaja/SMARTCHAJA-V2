
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_chaja/features/chargenow_devices/payment/azam/model/transaction_model.dart';
import 'package:uuid/uuid.dart';

class PowerBankService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid uuid = const Uuid();

  Future<Map<String, dynamic>> usePowerBank({
    required double amount,
    required String currency,
    required String deviceId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      return {
        'success': false,
        'message': 'No authenticated user found',
      };
    }

    String transactionDocId = uuid.v4();

    try {
      // Save transaction for power bank usage
      await _firestore.collection('transactions').doc(transactionDocId).set(
            TransactionModel(
              id: transactionDocId,
              userId: user.uid,
              amount: amount,
              currency: currency,
              provider: 'PowerBank',
              status: 'confirmed', // Direct confirmation for usage
              externalId: transactionDocId,
              createdAt: DateTime.now(),
            ).toMap(),
          );

      // Update user balance
      await _firestore.runTransaction((transaction) async {
        final userRef = _firestore.collection('users').doc(user.uid);
        final userDoc = await transaction.get(userRef);
        if (!userDoc.exists) {
          throw Exception('User not found');
        }
        final currentBalance = (userDoc.data()?['balance'] as num?)?.toDouble() ?? 0.0;
        final newBalance = currentBalance - amount; // Allow negative balance (loan)
        transaction.update(userRef, {'balance': newBalance, 'updatedAt': DateTime.now()});
      });

      return {
        'success': true,
        'message': 'Power bank usage recorded successfully',
        'transactionDocId': transactionDocId,
      };
    } catch (e) {
      await _firestore.collection('transactions').doc(transactionDocId).update({
        'status': 'failed',
        'updatedAt': DateTime.now(),
      });
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
        'transactionDocId': transactionDocId,
      };
    }
  }
}
