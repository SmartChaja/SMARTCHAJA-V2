
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_chaja/features/chargenow_devices/payment/azam/model/payment_model.dart';
import 'package:smart_chaja/features/chargenow_devices/payment/azam/service/payment_service.dart';
import 'package:smart_chaja/features/chargenow_devices/payment/azam/service/power_bank_service.dart';
import 'package:smart_chaja/features/chargenow_devices/payment/azam/view_model/payment_view_model.dart';

final paymentServiceProvider = Provider<PaymentService>((ref) => PaymentService());
final powerBankServiceProvider = Provider<PowerBankService>((ref) => PowerBankService());

final paymentViewModelProvider = StateNotifierProvider<PaymentViewModel, AsyncValue<PaymentResult?>>(
  (ref) => PaymentViewModel(ref.read(paymentServiceProvider)),
);
