import 'package:smart_chaja/features/chargenow_devices/plan/model/plan.dart';
import 'package:smart_chaja/features/chargenow_devices/plan/model/plan_operation_response.dart';

enum PlanStatus { initial, loading, success, error }

class PlanState {
  final PlanStatus status;
  final List<Plan>? plans;
  final Plan? selectedPlan;
  final PlanOperationResponse? operationResponse;
  final String? errorMsg;

  PlanState({
    required this.status,
    this.plans,
    this.selectedPlan,
    this.operationResponse,
    this.errorMsg,
  });

  PlanState copyWith({
    PlanStatus? status,
    List<Plan>? plans,
    Plan? selectedPlan,
    PlanOperationResponse? operationResponse,
    String? errorMsg,
    bool clearAll = false,
  }) {
    return PlanState(
      status: clearAll ? PlanStatus.initial : status ?? this.status,
      plans: clearAll ? null : plans ?? this.plans,
      selectedPlan: clearAll ? null : selectedPlan ?? this.selectedPlan,
      operationResponse: clearAll ? null : operationResponse ?? this.operationResponse,
      errorMsg: clearAll ? null : errorMsg ?? this.errorMsg,
    );
  }
}