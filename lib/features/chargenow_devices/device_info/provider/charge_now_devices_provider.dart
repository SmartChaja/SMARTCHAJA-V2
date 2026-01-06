// File: lib/features/chargenow_devices/provider/charge_now_devices_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:smart_chaja/features/chargenow_devices/device_info/service/charge_now_service.dart';
import 'package:smart_chaja/features/chargenow_devices/device_info/view_model/charge_now_device_info_view_model.dart';

final httpClientProvider = Provider<http.Client>((ref) => http.Client());

final chargeNowServiceProvider = Provider<ChargeNowService>((ref) {
  final client = ref.watch(httpClientProvider);
  return ChargeNowService(client);
});


final chargeNowDeviceInfoViewModelProvider = StateNotifierProvider.family<
    ChargeNowDeviceInfoViewModel, DeviceInfoState, String>(
  (ref, deviceId) {
    final service = ref.watch(chargeNowServiceProvider);
    return ChargeNowDeviceInfoViewModel(service, deviceId);
  },
);