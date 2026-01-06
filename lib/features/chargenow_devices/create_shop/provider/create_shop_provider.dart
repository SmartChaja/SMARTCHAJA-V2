import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:smart_chaja/features/chargenow_devices/create_shop/service/charge_now_create_shop_service.dartcharge_now_create_shop_service.dart';
import 'package:smart_chaja/features/chargenow_devices/create_shop/view_models/create_shop_state.dart';
import 'package:smart_chaja/features/chargenow_devices/create_shop/view_models/create_shop_view_model.dart';

// Reuse the same HTTP client provider as in other features
final chargeNowCreateShopHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  return client;
});

// Provider for the ChargeNowCreateShopService
final chargeNowCreateShopServiceProvider = Provider<ChargeNowCreateShopService>((ref) {
  final httpClient = ref.watch(chargeNowCreateShopHttpClientProvider);
  return ChargeNowCreateShopService(httpClient);
});

// StateNotifierProvider for the CreateShopViewModel
final createShopViewModelProvider =
    StateNotifierProvider<CreateShopViewModel, CreateShopState>((ref) {
  final service = ref.watch(chargeNowCreateShopServiceProvider);
  return CreateShopViewModel(service);
});