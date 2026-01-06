import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:smart_chaja/features/chargenow_devices/order_list/service/charge_now_order_list_service.dart';
import 'package:smart_chaja/features/chargenow_devices/order_list/view_models/order_list_state.dart';
import 'package:smart_chaja/features/chargenow_devices/order_list/view_models/order_list_view_model.dart';

// Reuse the same HTTP client provider as in other features
final chargeNowOrderListHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  return client;
});

// Provider for the ChargeNowOrderListService
final chargeNowOrderListServiceProvider = Provider<ChargeNowOrderListService>((ref) {
  final httpClient = ref.watch(chargeNowOrderListHttpClientProvider);
  return ChargeNowOrderListService(httpClient);
});

// StateNotifierProvider for the OrderListViewModel
final orderListViewModelProvider =
    StateNotifierProvider<OrderListViewModel, OrderListState>((ref) {
  final service = ref.watch(chargeNowOrderListServiceProvider);
  return OrderListViewModel(service);
});