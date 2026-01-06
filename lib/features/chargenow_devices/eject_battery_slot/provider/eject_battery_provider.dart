import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:smart_chaja/features/chargenow_devices/eject_battery_slot/service/charge_now_eject_service.dart';
import 'package:smart_chaja/features/chargenow_devices/eject_battery_slot/view_models/eject_battery_state.dart';
import 'package:smart_chaja/features/chargenow_devices/eject_battery_slot/view_models/eject_battery_view_model.dart';

// Reuse the same HTTP client provider as in other features
final chargeNowEjectHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  return client;
});

// Provider for the ChargeNowEjectService
final chargeNowEjectServiceProvider = Provider<ChargeNowEjectService>((ref) {
  final httpClient = ref.watch(chargeNowEjectHttpClientProvider);
  return ChargeNowEjectService(httpClient);
});

// StateNotifierProvider for the EjectBatteryViewModel
final ejectBatteryViewModelProvider =
    StateNotifierProvider<EjectBatteryViewModel, EjectBatteryState>((ref) {
  final service = ref.watch(chargeNowEjectServiceProvider);
  return EjectBatteryViewModel(service);
});
