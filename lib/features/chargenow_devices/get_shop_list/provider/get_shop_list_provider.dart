import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:smart_chaja/features/chargenow_devices/get_shop_list/service/charge_now_get_shop_list_service.dart';
import 'package:smart_chaja/features/chargenow_devices/get_shop_list/view_models/get_shop_list_state.dart';
import 'package:smart_chaja/features/chargenow_devices/get_shop_list/view_models/get_shop_list_view_model.dart';

// Reuse the same HTTP client provider as in other features
final chargeNowGetShopListHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  return client;
});

// Provider for the ChargeNowGetShopListService
final chargeNowGetShopListServiceProvider = Provider<ChargeNowGetShopListService>((ref) {
  final httpClient = ref.watch(chargeNowGetShopListHttpClientProvider);
  return ChargeNowGetShopListService(httpClient);
});

// StateNotifierProvider for the GetShopListViewModel
final getShopListViewModelProvider =
    StateNotifierProvider<GetShopListViewModel, GetShopListState>((ref) {
  final service = ref.watch(chargeNowGetShopListServiceProvider);
  return GetShopListViewModel(service);
});