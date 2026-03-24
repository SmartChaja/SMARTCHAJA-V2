import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../response/vodacom_payment_result.dart';
import '../service/vodacom_payment_service.dart';

/// ViewModel for managing Vodacom payment operations
class VodacomPaymentViewModel
    extends StateNotifier<AsyncValue<VodacomPaymentOperationResult?>> {
  final VodacomPaymentService _paymentService;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Store session key to avoid regenerating for multiple payments
  String? _cachedSessionKey;
  DateTime? _sessionKeyExpiry;

  VodacomPaymentViewModel(this._paymentService)
      : super(const AsyncValue.data(null));

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
            '[VodacomPaymentViewModel] Generated SessionID: ${_cachedSessionKey?.substring(0, 20)}...');

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

      // Perform C2B payment
      final paymentResult = await _paymentService.performC2BPayment(
        sessionKey: sessionKey,
        amount: amount,
        customerMsisdn: customerMsisdn,
        serviceProviderCode: serviceProviderCode,
        transactionReference: transactionReference,
        purchasedItemsDesc: purchasedItemsDesc,
      );

      // Build operation result
      final operationResult = VodacomPaymentOperationResult(
        isSuccess: paymentResult.isSuccess,
        message: paymentResult.message,
        transactionId: paymentResult.transactionId,
        conversationId: paymentResult.conversationId,
        thirdPartyConversationId: paymentResult.thirdPartyConversationId,
        amount: amount,
        currency: paymentResult.currency,
        provider: 'Vodacom',
      );

      state = AsyncValue.data(operationResult);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
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
