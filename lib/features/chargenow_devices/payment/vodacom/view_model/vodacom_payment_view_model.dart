import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../response/vodacom_payment_result.dart';
import '../model/vodacom_payment_model.dart';
import '../service/vodacom_payment_service.dart';
import '../service/vodacom_transaction_service.dart';

/// ViewModel for managing Vodacom payment operations
class VodacomPaymentViewModel
    extends StateNotifier<AsyncValue<VodacomPaymentOperationResult?>> {
  final VodacomPaymentService _paymentService;
  final VodacomTransactionService _transactionService;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Store session key to avoid regenerating for multiple payments
  String? _cachedSessionKey;
  DateTime? _sessionKeyExpiry;

  VodacomPaymentViewModel(
    this._paymentService,
    this._transactionService,
  ) : super(const AsyncValue.data(null));

  /// Gets or generates a valid session key
  /// Per M-Pesa API docs: Session ID takes up to 30 seconds to become 'live' in the system
  /// CRITICAL: Must wait 30 seconds after generation before using it for C2B payments
  Future<String?> _getValidSessionKey() async {
    // Check if cached session key is still valid
    // Note: We use 25-second TTL cache but MUST wait 30 seconds after generation
    if (_cachedSessionKey != null &&
        _sessionKeyExpiry != null &&
        DateTime.now().isBefore(_sessionKeyExpiry!)) {
      print('[VodacomPaymentViewModel] Using cached session key (still valid)');
      return _cachedSessionKey;
    }

    // Generate new session key
    try {
      print('[VodacomPaymentViewModel] Generating new session key...');
      final sessionResponse = await _paymentService.generateSessionKey();

      if (sessionResponse.isSuccess && sessionResponse.sessionId != null) {
        _cachedSessionKey = sessionResponse.sessionId;

        // CRITICAL: Per M-Pesa API docs, session ID takes 30 seconds to become live
        // We wait 30 seconds before returning to ensure it's ready for use
        print(
            '[VodacomPaymentViewModel] ⏳ Waiting 30 seconds for session ID to become active in M-Pesa system...');
        print(
            '[VodacomPaymentViewModel] Generated SessionID: ${_cachedSessionKey}');

        // Wait 30 seconds as per M-Pesa API documentation
        await Future.delayed(const Duration(seconds: 30));

        print(
            '[VodacomPaymentViewModel] ✓ Session ID is now active and ready for payment');

        _sessionKeyExpiry = DateTime.now()
            .add(const Duration(seconds: 25)); // 25 second TTL after wait
        return _cachedSessionKey;
      } else {
        print('[VodacomPaymentViewModel] ✗ Failed to generate session key');
        state = AsyncValue.data(VodacomPaymentOperationResult.error(
          sessionResponse.responseDesc ?? 'Failed to generate session key',
        ));
        return null;
      }
    } catch (e) {
      print('[VodacomPaymentViewModel] ✗ Session key error: $e');
      state = AsyncValue.data(
        VodacomPaymentOperationResult.error('Session key error: $e'),
      );
      return null;
    }
  }

  /// Performs a C2B single stage payment
  Future<void> performC2BPayment({
    required String amount,
    required String customerMsisdn,
    required String serviceProviderCode,
    required String transactionReference,
    required String purchasedItemsDesc,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      state = AsyncValue.data(
        VodacomPaymentOperationResult.error('No authenticated user found'),
      );
      return;
    }

    state = const AsyncValue.loading();
    try {
      // Get valid session key
      final sessionKey = await _getValidSessionKey();
      if (sessionKey == null) {
        return; // Error state already set by _getValidSessionKey
      }

      // Dispatch the C2B payment request and show the success page immediately.
      // The real API response still arrives in the background and is used for
      // the transaction record and wallet balance confirmation.
      final paymentFuture = _paymentService.performC2BPayment(
        sessionKey: sessionKey,
        amount: amount,
        customerMsisdn: customerMsisdn,
        serviceProviderCode: serviceProviderCode,
        transactionReference: transactionReference,
        purchasedItemsDesc: purchasedItemsDesc,
      );

      state = AsyncValue.data(
        VodacomPaymentOperationResult(
          isSuccess: true,
          isProvisional: true,
          message: 'Payment request sent',
          transactionId: transactionReference,
          amount: amount,
          currency: 'TZS',
          provider: 'Vodacom',
          responseCode: 'INS-0',
          responseDesc: 'Request processed',
        ),
      );

      final paymentResult = await paymentFuture;

      // Build operation result
      final operationResult = VodacomPaymentOperationResult(
        isSuccess: paymentResult.isSuccess,
        isProvisional: false,
        message: paymentResult.message,
        transactionId: paymentResult.transactionId,
        conversationId: paymentResult.conversationId,
        thirdPartyConversationId: paymentResult.thirdPartyConversationId,
        amount: amount,
        currency: paymentResult.currency,
        provider: 'Vodacom',
        responseCode: paymentResult.responseCode,
        responseDesc: paymentResult.responseDesc,
      );

      state = AsyncValue.data(operationResult);

      if (operationResult.isSuccess) {
        unawaited(_finalizeSuccessfulPayment(
          paymentResult: paymentResult,
          amount: amount,
        ));
      } else {
        unawaited(_recordFailedPayment(
          paymentResult: paymentResult,
          amount: amount,
        ));
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> _finalizeSuccessfulPayment({
    required VodacomPaymentResult paymentResult,
    required String amount,
  }) async {
    try {
      final transactionDocId = await saveTransactionRecord(
        amount: double.parse(amount),
        currency: paymentResult.currency ?? 'TZS',
        transactionId: paymentResult.transactionId ?? '',
        conversationId: paymentResult.conversationId ?? '',
        thirdPartyConversationId: paymentResult.thirdPartyConversationId ?? '',
        responseCode: paymentResult.responseCode ?? 'INS-0',
        responseDesc: paymentResult.responseDesc ?? 'Success',
        transactionService: _transactionService,
      );

      if (transactionDocId != null && paymentResult.responseCode == 'INS-0') {
        await confirmTransactionBalance(
          transactionDocId: transactionDocId,
          amount: double.parse(amount),
          transactionService: _transactionService,
        );
      }
    } catch (e) {
      print(
          '[VodacomPaymentViewModel] ✗ Background transaction finalization failed: $e');
    }
  }

  Future<void> _recordFailedPayment({
    required VodacomPaymentResult paymentResult,
    required String amount,
  }) async {
    try {
      await _transactionService.saveFailedTransaction(
        amount: double.parse(amount),
        currency: paymentResult.currency ?? 'TZS',
        transactionId: paymentResult.transactionId ?? '',
        conversationId: paymentResult.conversationId ?? '',
        thirdPartyConversationId: paymentResult.thirdPartyConversationId ?? '',
        responseCode: paymentResult.responseCode ?? 'FAILED',
        responseDesc: paymentResult.responseDesc ?? paymentResult.message,
        failureReason: paymentResult.message,
      );
    } catch (e) {
      print(
          '[VodacomPaymentViewModel] ✗ Background failed-transaction save failed: $e');
    }
  }

  /// Saves transaction record to Firestore after successful payment
  /// This should be called from UI after receiving successful payment response
  ///
  /// The transaction will be:
  /// - Status: 'pending' initially (waiting for callback confirmation)
  /// - Status: 'confirmed' when Cloud Function callback updates balance
  /// - Status: 'failed' if callback indicates failure
  Future<String?> saveTransactionRecord({
    required double amount,
    required String currency,
    required String transactionId,
    required String conversationId,
    required String thirdPartyConversationId,
    required String responseCode,
    required String responseDesc,
    required VodacomTransactionService transactionService,
  }) async {
    try {
      print('[VodacomPayment] Saving transaction record...');
      final transactionDocId = await transactionService.savePendingTransaction(
        amount: amount,
        currency: currency,
        transactionId: transactionId,
        conversationId: conversationId,
        thirdPartyConversationId: thirdPartyConversationId,
        responseCode: responseCode,
        responseDesc: responseDesc,
      );
      print('[VodacomPayment] ✓ Transaction saved: $transactionDocId');
      return transactionDocId;
    } catch (e) {
      print('[VodacomPayment] ✗ Error saving transaction: $e');
      return null;
    }
  }

  /// Confirms a transaction (adds balance to user account)
  /// Should be called by:
  /// 1. Cloud Function callback handler (for async payments)
  /// 2. UI directly (for sync payments with immediate confirmation)
  Future<bool> confirmTransactionBalance({
    required String transactionDocId,
    required double amount,
    required VodacomTransactionService transactionService,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      print('[VodacomPayment] ✗ No authenticated user found');
      return false;
    }

    try {
      print('[VodacomPayment] Confirming transaction and updating balance...');
      await transactionService.confirmTransaction(
        transactionDocId: transactionDocId,
        userId: user.uid,
        amount: amount,
      );
      print('[VodacomPayment] ✓ Transaction confirmed and balance updated');
      return true;
    } catch (e) {
      print('[VodacomPayment] ✗ Error confirming transaction: $e');
      return false;
    }
  }

  /// Queries the status of a previous transaction
  Future<void> queryTransactionStatus({
    required String conversationId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      state = AsyncValue.data(
        VodacomPaymentOperationResult.error('No authenticated user found'),
      );
      return;
    }

    state = const AsyncValue.loading();
    try {
      // Get valid session key
      final sessionKey = await _getValidSessionKey();
      if (sessionKey == null) {
        return; // Error state already set
      }

      // Query transaction status
      final queryResult = await _paymentService.queryTransactionStatus(
        sessionKey: sessionKey,
        conversationId: conversationId,
      );

      final operationResult = VodacomPaymentOperationResult(
        isSuccess: queryResult.isSuccess,
        message: queryResult.message,
        transactionId: queryResult.transactionId,
        conversationId: queryResult.conversationId,
        thirdPartyConversationId: queryResult.thirdPartyConversationId,
      );

      state = AsyncValue.data(operationResult);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Clears cached session key (useful when switching users)
  void clearSessionCache() {
    _cachedSessionKey = null;
    _sessionKeyExpiry = null;
  }

  /// Resets the state to initial value
  void reset() {
    state = const AsyncValue.data(null);
    clearSessionCache();
  }
}
