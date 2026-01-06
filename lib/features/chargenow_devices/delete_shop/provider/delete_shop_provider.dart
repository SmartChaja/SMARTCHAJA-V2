import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:smart_chaja/features/chargenow_devices/delete_shop/service/charge_now_delete_shop_service.dart';
import 'package:smart_chaja/features/chargenow_devices/delete_shop/view_models/delete_shop_state.dart';
import 'package:smart_chaja/features/chargenow_devices/delete_shop/view_models/delete_shop_view_model.dart';


// Reuse the same HTTP client provider as in other features
final chargeNowDeleteShopHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  return client;
});

// Provider for the ChargeNowDeleteShopService
final chargeNowDeleteShopServiceProvider = Provider<ChargeNowDeleteShopService>((ref) {
  final httpClient = ref.watch(chargeNowDeleteShopHttpClientProvider);
  return ChargeNowDeleteShopService(httpClient);
});

// StateNotifierProvider for the DeleteShopViewModel
final deleteShopViewModelProvider =
    StateNotifierProvider<DeleteShopViewModel, DeleteShopState>((ref) {
  final service = ref.watch(chargeNowDeleteShopServiceProvider);
  return DeleteShopViewModel(service);
});