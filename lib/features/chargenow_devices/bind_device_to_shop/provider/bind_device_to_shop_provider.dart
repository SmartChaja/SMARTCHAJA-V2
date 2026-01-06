import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:smart_chaja/features/chargenow_devices/bind_device_to_shop/view_models/bind_device_to_shop_state.dart';
import 'package:smart_chaja/features/chargenow_devices/bind_device_to_shop/view_models/bind_device_to_shop_view_model.dart';


import '../service/charge_now_bind_device_to_shop_service.dart';

// Reuse the same HTTP client provider as in other features
final chargeNowBindDeviceToShopHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  return client;
});

// Provider for the ChargeNowBindDeviceToShopService
final chargeNowBindDeviceToShopServiceProvider = Provider<ChargeNowBindDeviceToShopService>((ref) {
  final httpClient = ref.watch(chargeNowBindDeviceToShopHttpClientProvider);
  return ChargeNowBindDeviceToShopService(httpClient);
});

// StateNotifierProvider for the BindDeviceToShopViewModel
final bindDeviceToShopViewModelProvider =
    StateNotifierProvider<BindDeviceToShopViewModel, BindDeviceToShopState>((ref) {
  final service = ref.watch(chargeNowBindDeviceToShopServiceProvider);
  return BindDeviceToShopViewModel(service);
});