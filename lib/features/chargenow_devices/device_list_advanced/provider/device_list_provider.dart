import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:smart_chaja/features/chargenow_devices/device_list_advanced/service/charge_now_device_list_service.dart';
import 'package:smart_chaja/features/chargenow_devices/device_list_advanced/view_models/device_list_state.dart';
import 'package:smart_chaja/features/chargenow_devices/device_list_advanced/view_models/device_list_view_model.dart';

// Reuse the same HTTP client provider as in other features
final chargeNowDeviceListHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  return client;
});

// Provider for the ChargeNowDeviceListService
final chargeNowDeviceListServiceProvider = Provider<ChargeNowDeviceListService>((ref) {
  final httpClient = ref.watch(chargeNowDeviceListHttpClientProvider);
  return ChargeNowDeviceListService(httpClient);
});

// StateNotifierProvider for the DeviceListViewModel
final deviceListViewModelProvider =
    StateNotifierProvider<DeviceListViewModel, DeviceListState>((ref) {
  final service = ref.watch(chargeNowDeviceListServiceProvider);
  return DeviceListViewModel(service);
});