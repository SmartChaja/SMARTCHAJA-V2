import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:smart_chaja/features/chargenow_devices/get_order_detail/service/charge_now_detail_service.dart';
import 'package:smart_chaja/features/chargenow_devices/get_order_detail/view_models/get_order_detail_state.dart';
import 'package:smart_chaja/features/chargenow_devices/get_order_detail/view_models/get_order_detail_view_model.dart';


// Reuse the same HTTP client provider as in other features
final chargeNowDetailHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  return client;
});

// Provider for the ChargeNowDetailService
final chargeNowDetailServiceProvider = Provider<ChargeNowDetailService>((ref) {
  final httpClient = ref.watch(chargeNowDetailHttpClientProvider);
  return ChargeNowDetailService(httpClient);
});

// StateNotifierProvider for the GetOrderDetailViewModel
final getOrderDetailViewModelProvider =
    StateNotifierProvider<GetOrderDetailViewModel, GetOrderDetailState>((ref) {
  final service = ref.watch(chargeNowDetailServiceProvider);
  return GetOrderDetailViewModel(service);
});