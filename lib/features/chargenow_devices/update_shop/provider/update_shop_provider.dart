import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:smart_chaja/features/chargenow_devices/update_shop/service/charge_now_update_shop_service.dart';
import 'package:smart_chaja/features/chargenow_devices/update_shop/view_models/update_shop_state.dart';
import 'package:smart_chaja/features/chargenow_devices/update_shop/view_models/update_shop_view_model.dart';

// Reuse the same HTTP client provider as in other features
final chargeNowUpdateShopHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  return client;
});

// Provider for the ChargeNowUpdateShopService
final chargeNowUpdateShopServiceProvider = Provider<ChargeNowUpdateShopService>((ref) {
  final httpClient = ref.watch(chargeNowUpdateShopHttpClientProvider);
  return ChargeNowUpdateShopService(httpClient);
});

// StateNotifierProvider for the UpdateShopViewModel
final updateShopViewModelProvider =
    StateNotifierProvider<UpdateShopViewModel, UpdateShopState>((ref) {
  final service = ref.watch(chargeNowUpdateShopServiceProvider);
  return UpdateShopViewModel(service);
});