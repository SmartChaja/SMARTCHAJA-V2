import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../response/vodacom_payment_result.dart';
import '../service/vodacom_payment_service.dart';
import '../service/vodacom_transaction_service.dart';
import '../service/vodacom_secure_config.dart';
import '../view_model/vodacom_payment_view_model.dart';

/// Vodacom API Configuration
/// Toggle PRODUCTION_MODE to switch between sandbox and production
/// IMPORTANT: API keys are now securely managed via Firebase Remote Config
/// See VodacomSecureConfig for setup instructions
const bool PRODUCTION_MODE = true; // Set to true for production

/// Provider for secure credential management
final vodacomSecureConfigProvider = Provider<VodacomSecureConfig>((ref) {
  return VodacomSecureConfig();
});

/// Provides the Vodacom Payment Service instance
final vodacomPaymentServiceProvider = Provider<VodacomPaymentService>((ref) {
  final secureConfig = VodacomSecureConfig();
  return VodacomPaymentService(
    apiKey: PRODUCTION_MODE
        ? secureConfig.productionApiKey
        : secureConfig.sandboxApiKey,
    serviceProviderCode: PRODUCTION_MODE
        ? secureConfig.productionServiceCode
        : secureConfig.sandboxServiceCode,
    sandbox: !PRODUCTION_MODE,
    origin:
        '*', // Update to your domain for production (e.g., 'yourdomain.com')
  );
});

/// Provides the Vodacom Payment ViewModel with state management
final vodacomPaymentViewModelProvider = StateNotifierProvider<
    VodacomPaymentViewModel, AsyncValue<VodacomPaymentOperationResult?>>((ref) {
  final paymentService = ref.watch(vodacomPaymentServiceProvider);
  return VodacomPaymentViewModel(paymentService);
});

/// Provides the Vodacom Transaction Service for wallet balance updates
final vodacomTransactionServiceProvider =
    Provider<VodacomTransactionService>((ref) {
  return VodacomTransactionService(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});
