import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_chaja/features/chargenow_devices/api_exception/chargenow_api_exception.dart';
import 'package:smart_chaja/features/chargenow_devices/plan/model/plan.dart';
import 'package:smart_chaja/features/chargenow_devices/plan/model/plan_operation_response.dart';
import '../../../../authentication/register/model/user_model.dart';
import '../../../../authentication/register/viewmodels/auth_viewmodel.dart';


class ChargeNowPlanService {
  final FirebaseFirestore _firestore;
  final Ref _ref;

  ChargeNowPlanService(this._firestore, this._ref);

  UserModel? get _currentUser => _ref.read(authViewModelProvider).user;

  Future<List<Plan>> getPlans() async {
    try {
      print("ChargeNowPlanService: Fetching plans from global collection");
      final snapshot = await _firestore.collection('plans').get();
      final plans = snapshot.docs.map((doc) => Plan.fromJson(doc.data())).toList();
      print("ChargeNowPlanService: Retrieved ${plans.length} plans");
      return plans;
    } catch (e) {
      print("ChargeNowPlanService: Error fetching plans - ${e.toString()}");
      throw ChargeNowApiException(message: "Failed to fetch plans: ${e.toString()}");
    }
  }

  Future<PlanOperationResponse> createPlan({
    required String name,
    required int durationDays,
    required double price,
    required String currency,
  }) async {
    if (_currentUser == null) {
      return PlanOperationResponse(
        message: "User not authenticated.",
        success: false,
      );
    }
    if (_currentUser!.role != 'admin') {
      return PlanOperationResponse(
        message: "Unauthorized: Admin role required.",
        success: false,
      );
    }

    try {
      final planId = 'plan_${DateTime.now().millisecondsSinceEpoch}';
      final plan = Plan(
        id: planId,
        name: name,
        durationDays: durationDays,
        price: price,
        currency: currency,
      );

      print("ChargeNowPlanService: Creating plan $planId");
      await _firestore.collection('plans').doc(planId).set(plan.toJson());

      print("ChargeNowPlanService: Plan $planId created successfully");
      return PlanOperationResponse(
        message: "Plan created successfully",
        success: true,
      );
    } catch (e) {
      print("ChargeNowPlanService: Error creating plan - ${e.toString()}");
      return PlanOperationResponse(
        message: "Failed to create plan: ${e.toString()}",
        success: false,
      );
    }
  }

  Future<PlanOperationResponse> updatePlan({
    required String planId,
    required String name,
    required int durationDays,
    required double price,
    required String currency,
  }) async {
    if (_currentUser == null) {
      return PlanOperationResponse(
        message: "User not authenticated.",
        success: false,
      );
    }
    if (_currentUser!.role != 'admin') {
      return PlanOperationResponse(
        message: "Unauthorized: Admin role required.",
        success: false,
      );
    }

    try {
      final plan = Plan(
        id: planId,
        name: name,
        durationDays: durationDays,
        price: price,
        currency: currency,
      );

      print("ChargeNowPlanService: Updating plan $planId");
      await _firestore.collection('plans').doc(planId).update(plan.toJson());

      print("ChargeNowPlanService: Plan $planId updated successfully");
      return PlanOperationResponse(
        message: "Plan updated successfully",
        success: true,
      );
    } catch (e) {
      print("ChargeNowPlanService: Error updating plan - ${e.toString()}");
      return PlanOperationResponse(
        message: "Failed to update plan: ${e.toString()}",
        success: false,
      );
    }
  }

  Future<PlanOperationResponse> deletePlan(String planId) async {
    if (_currentUser == null) {
      return PlanOperationResponse(
        message: "User not authenticated.",
        success: false,
      );
    }
    if (_currentUser!.role != 'admin') {
      return PlanOperationResponse(
        message: "Unauthorized: Admin role required.",
        success: false,
      );
    }

    try {
      print("ChargeNowPlanService: Deleting plan $planId");
      await _firestore.collection('plans').doc(planId).delete();

      print("ChargeNowPlanService: Plan $planId deleted successfully");
      return PlanOperationResponse(
        message: "Plan deleted successfully",
        success: true,
      );
    } catch (e) {
      print("ChargeNowPlanService: Error deleting plan - ${e.toString()}");
      return PlanOperationResponse(
        message: "Failed to delete plan: ${e.toString()}",
        success: false,
      );
    }
  }
}