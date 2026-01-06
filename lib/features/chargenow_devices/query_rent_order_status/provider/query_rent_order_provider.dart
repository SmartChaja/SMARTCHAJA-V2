import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:smart_chaja/features/chargenow_devices/query_rent_order_status/service/charge_now_query_service.dart';
import 'package:smart_chaja/features/chargenow_devices/query_rent_order_status/view_models/query_rent_order_state.dart';
import 'package:smart_chaja/features/chargenow_devices/query_rent_order_status/view_models/query_rent_order_view_model.dart';

// Reuse the same HTTP client provider as in CreateRentOrder
final chargeNowQueryHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  return client;
});

// Provider for the ChargeNowQueryService
final chargeNowQueryServiceProvider = Provider<ChargeNowQueryService>((ref) {
  final httpClient = ref.watch(chargeNowQueryHttpClientProvider);
  return ChargeNowQueryService(httpClient);
});

// StateNotifierProvider for the QueryRentOrderViewModel
final queryRentOrderViewModelProvider =
    StateNotifierProvider<QueryRentOrderViewModel, QueryRentOrderState>((ref) {
  final service = ref.watch(chargeNowQueryServiceProvider);
  return QueryRentOrderViewModel(service);
});