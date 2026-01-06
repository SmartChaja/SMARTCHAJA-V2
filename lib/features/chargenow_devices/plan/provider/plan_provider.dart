import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_chaja/features/chargenow_devices/plan/model/plan_state.dart';
import 'package:smart_chaja/features/chargenow_devices/plan/plan_view_model/plan_view_model.dart';
import 'package:smart_chaja/features/chargenow_devices/plan/service/charge_now_plan_service.dart';


// Provider for FirebaseFirestore instance
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

// Provider for ChargeNowPlanService
final chargeNowPlanServiceProvider = Provider<ChargeNowPlanService>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return ChargeNowPlanService(firestore, ref);
});

// StateNotifierProvider for PlanViewModel
final planViewModelProvider = StateNotifierProvider<PlanViewModel, PlanState>((ref) {
  final service = ref.watch(chargeNowPlanServiceProvider);
  return PlanViewModel(service);
});