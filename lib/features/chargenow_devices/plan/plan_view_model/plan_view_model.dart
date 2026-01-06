import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_chaja/features/chargenow_devices/api_exception/chargenow_api_exception.dart';
import 'package:smart_chaja/features/chargenow_devices/plan/model/plan.dart';
import 'package:smart_chaja/features/chargenow_devices/plan/model/plan_state.dart';
import 'package:smart_chaja/features/chargenow_devices/plan/service/charge_now_plan_service.dart';

class PlanViewModel extends StateNotifier<PlanState> {
  final ChargeNowPlanService _planService;

  PlanViewModel(this._planService) : super(PlanState(status: PlanStatus.initial));

  Future<void> fetchPlans() async {
    if (state.status == PlanStatus.loading) return;

    try {
      state = state.copyWith(status: PlanStatus.loading, clearAll: true);

      final plans = await _planService.getPlans();

      state = state.copyWith(
        status: PlanStatus.success,
        plans: plans,
      );
    } on ChargeNowApiException catch (e) {
      state = state.copyWith(status: PlanStatus.error, errorMsg: e.message);
    } catch (e) {
      state = state.copyWith(status: PlanStatus.error, errorMsg: "Failed to fetch plans: ${e.toString()}");
    }
  }

  Future<void> createPlan({
    required String name,
    required int durationDays,
    required double price,
    required String currency,
  }) async {
    if (state.status == PlanStatus.loading) return;

    try {
      state = state.copyWith(status: PlanStatus.loading, operationResponse: null);

      final result = await _planService.createPlan(
        name: name,
        durationDays: durationDays,
        price: price,
        currency: currency,
      );

      state = state.copyWith(
        status: result.success ? PlanStatus.success : PlanStatus.error,
        operationResponse: result,
        errorMsg: result.success ? null : result.message,
      );

      if (result.success) {
        await fetchPlans(); // Refresh plans after creation
      }
    } catch (e) {
      state = state.copyWith(
        status: PlanStatus.error,
        errorMsg: "Failed to create plan: ${e.toString()}",
      );
    }
  }

  Future<void> updatePlan({
    required String planId,
    required String name,
    required int durationDays,
    required double price,
    required String currency,
  }) async {
    if (state.status == PlanStatus.loading) return;

    try {
      state = state.copyWith(status: PlanStatus.loading, operationResponse: null);

      final result = await _planService.updatePlan(
        planId: planId,
        name: name,
        durationDays: durationDays,
        price: price,
        currency: currency,
      );

      state = state.copyWith(
        status: result.success ? PlanStatus.success : PlanStatus.error,
        operationResponse: result,
        errorMsg: result.success ? null : result.message,
      );

      if (result.success) {
        await fetchPlans(); // Refresh plans after update
      }
    } catch (e) {
      state = state.copyWith(
        status: PlanStatus.error,
        errorMsg: "Failed to update plan: ${e.toString()}",
      );
    }
  }

  Future<void> deletePlan(String planId) async {
    if (state.status == PlanStatus.loading) return;

    try {
      state = state.copyWith(status: PlanStatus.loading, operationResponse: null);

      final result = await _planService.deletePlan(planId);

      state = state.copyWith(
        status: result.success ? PlanStatus.success : PlanStatus.error,
        operationResponse: result,
        errorMsg: result.success ? null : result.message,
      );

      if (result.success) {
        await fetchPlans(); // Refresh plans after deletion
      }
    } catch (e) {
      state = state.copyWith(
        status: PlanStatus.error,
        errorMsg: "Failed to delete plan: ${e.toString()}",
      );
    }
  }

  void selectPlan(Plan? plan) {
    state = state.copyWith(selectedPlan: plan);
  }

  void resetState() {
    state = PlanState(status: PlanStatus.initial);
  }
}