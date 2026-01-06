import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:smart_chaja/features/chargenow_devices/rent_eject/service/charge_now_rent_eject_service.dart';
import 'package:smart_chaja/features/chargenow_devices/rent_eject/view_models/rent_eject_state.dart';
import 'package:smart_chaja/features/chargenow_devices/rent_eject/view_models/rent_eject_view_model.dart';

// Reuse the same HTTP client provider as in other features
final chargeNowRentEjectHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  return client;
});

// Provider for the ChargeNowRentEjectService
final chargeNowRentEjectServiceProvider = Provider<ChargeNowRentEjectService>((ref) {
  final httpClient = ref.watch(chargeNowRentEjectHttpClientProvider);
  return ChargeNowRentEjectService(httpClient);
});

// StateNotifierProvider for the RentEjectViewModel
final rentEjectViewModelProvider =
    StateNotifierProvider<RentEjectViewModel, RentEjectState>((ref) {
  final service = ref.watch(chargeNowRentEjectServiceProvider);
  return RentEjectViewModel(service);
});