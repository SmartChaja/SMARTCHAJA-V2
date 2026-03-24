import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../response/vodacom_payment_result.dart';
import '../service/vodacom_payment_service.dart';
import '../view_model/vodacom_payment_view_model.dart';

// API Key - Store in environment variables or secure storage in production
const String _vodacomApiKey = 'BBCFkqwvBIqV3sPXwsGdBGI5m3cM8GMK';

/// Provides the Vodacom Payment Service instance
final vodacomPaymentServiceProvider = Provider<VodacomPaymentService>((ref) {
  return VodacomPaymentService(
    apiKey: _vodacomApiKey,
    sandbox: true, // Set to false for production
    origin: '*',
  );
});

/// Provides the Vodacom Payment ViewModel with state management
final vodacomPaymentViewModelProvider = StateNotifierProvider<
    VodacomPaymentViewModel, AsyncValue<VodacomPaymentOperationResult?>>((ref) {
  final paymentService = ref.watch(vodacomPaymentServiceProvider);
  return VodacomPaymentViewModel(paymentService);
});
