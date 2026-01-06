// File: lib/features/chargenow_devices/provider/charge_now_devices_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../service/charge_now_service.dart';
import '../view_model/charge_now_devices_view_model.dart';

// Provider for a basic http.Client (can be shared or app-level)
final basicHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(() => client.close()); // Auto-dispose client
  return client;
});

final chargeNowServiceProvider = Provider<ChargeNowService>((ref) {
  final client = ref.watch(basicHttpClientProvider);
  return ChargeNowService(client);
});

final chargeNowDevicesViewModelProvider =
    StateNotifierProvider<ChargeNowDevicesViewModel, ChargeNowDevicesState>((ref) {
  final service = ref.watch(chargeNowServiceProvider);
  return ChargeNowDevicesViewModel(service);
});