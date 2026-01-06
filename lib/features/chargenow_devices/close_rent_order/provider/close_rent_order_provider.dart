import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:smart_chaja/features/chargenow_devices/close_rent_order/service/charge_now_close_service.dart';
import 'package:smart_chaja/features/chargenow_devices/close_rent_order/view_models/close_rent_order_state.dart';
import 'package:smart_chaja/features/chargenow_devices/close_rent_order/view_models/close_rent_order_view_model.dart';

// Reuse the same HTTP client provider as in CreateRentOrder
final chargeNowCloseHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  return client;
});

// Provider for the ChargeNowCloseService
final chargeNowCloseServiceProvider = Provider<ChargeNowCloseService>((ref) {
  final httpClient = ref.watch(chargeNowCloseHttpClientProvider);
  return ChargeNowCloseService(httpClient);
});

// StateNotifierProvider for the CloseRentOrderViewModel
final closeRentOrderViewModelProvider =
    StateNotifierProvider<CloseRentOrderViewModel, CloseRentOrderState>((ref) {
  final service = ref.read(chargeNowCloseServiceProvider);
  return CloseRentOrderViewModel(service);
});