
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_chaja/features/chargenow_devices/payment/azam/model/payment_model.dart';
import 'package:smart_chaja/features/chargenow_devices/payment/azam/service/payment_service.dart';


class PaymentViewModel extends StateNotifier<AsyncValue<PaymentResult?>> {
  final PaymentService _paymentService;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  PaymentViewModel(this._paymentService) : super(const AsyncValue.data(null));

  Future<void> performMobileCheckout({
    required String merchantMobileNumber,
    required String amount,
    required String currency,
    required String provider,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      state = AsyncValue.data(PaymentResult(
        isSuccess: false,
        message: 'No authenticated user found',
      ));
      return;
    }

    state = const AsyncValue.loading();
    try {
      final result = await _paymentService.performMobileCheckout(
        merchantMobileNumber: merchantMobileNumber,
        amount: amount,
        currency: currency,
        provider: provider,
      );
      state = AsyncValue.data(PaymentResult(
        isSuccess: result['success'] ?? false,
        message: result['message'] ?? 'Unknown response',
        transactionId: result['transactionId'],
        amount: amount,
        provider: provider,
        transactionDocId: result['transactionDocId'],
      ));
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> performBankCheckout({
    required String merchantAccountNumber,
    required String merchantMobileNumber,
    String? merchantName,
    required String amount,
    required String currency,
    required String provider,
    required String otp,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      state = AsyncValue.data(PaymentResult(
        isSuccess: false,
        message: 'No authenticated user found',
      ));
      return;
    }

    state = const AsyncValue.loading();
    try {
      final result = await _paymentService.performBankCheckout(
        merchantAccountNumber: merchantAccountNumber,
        merchantMobileNumber: merchantMobileNumber,
        merchantName: merchantName,
        amount: amount,
        currency: currency,
        provider: provider,
        otp: otp,
      );
      state = AsyncValue.data(PaymentResult(
        isSuccess: result['success'] ?? false,
        message: result['message'] ?? 'Unknown response',
        referenceId: result['referenceId'],
        amount: amount,
        provider: provider,
        transactionDocId: result['transactionDocId'],
      ));
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}
