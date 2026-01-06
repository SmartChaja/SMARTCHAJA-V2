// File: lib/features/chargenow_rent/provider/create_rent_order_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:smart_chaja/features/chargenow_devices/create_rent_order/service/charge_now_service.dart';
import 'package:smart_chaja/features/chargenow_devices/create_rent_order/view_model/create_rent_order_view_model.dart';
import 'package:smart_chaja/features/chargenow_devices/create_rent_order/service/rented_power_bank_service.dart';
import 'package:smart_chaja/authentication/register/repositories/auth_repository.dart';

// Provider for a basic http.Client instance
final chargeNowRentHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  return client;
});

// Provider for the ChargeNowRentService
final chargeNowRentServiceProvider = Provider<ChargeNowRentService>((ref) {
  final httpClient = ref.watch(chargeNowRentHttpClientProvider);
  return ChargeNowRentService(httpClient);
});

// StateNotifierProvider for the CreateRentOrderViewModel
final createRentOrderViewModelProvider =
    StateNotifierProvider<CreateRentOrderViewModel, CreateRentOrderState>((ref) {
  final chargeNowService = ref.watch(chargeNowRentServiceProvider);
  final rentedPowerBankService = ref.watch(rentedPowerBankServiceProvider);
  final authRepository = ref.watch(authRepositoryProvider); // NEW: Add AuthRepository
  
  return CreateRentOrderViewModel(
    chargeNowService,
    rentedPowerBankService,
    authRepository, // NEW: Pass AuthRepository
  );
});