// File: lib/features/chargenow_rent/view_model/create_rent_order_view_model.dart

import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_chaja/features/chargenow_devices/api_exception/chargenow_api_exception.dart';
import 'package:smart_chaja/features/chargenow_devices/create_rent_order/model/create_rent_order_params.dart';
import 'package:smart_chaja/features/chargenow_devices/create_rent_order/model/create_rent_order_response.dart';
import 'package:smart_chaja/features/chargenow_devices/create_rent_order/service/charge_now_service.dart';
import 'package:smart_chaja/features/chargenow_devices/create_rent_order/service/rented_power_bank_service.dart';
import 'package:smart_chaja/features/chargenow_devices/plan/model/plan.dart';
import 'package:smart_chaja/authentication/register/repositories/auth_repository.dart';

enum CreateRentOrderStatus { initial, loading, success, error }

class CreateRentOrderState {
  final CreateRentOrderStatus opStatus;
  final CreateRentOrderResponse? orderResponse;
  final String? errorMsg;
  final dynamic validationDetails;

  CreateRentOrderState({
    required this.opStatus,
    this.orderResponse,
    this.errorMsg,
    this.validationDetails,
  });

  CreateRentOrderState copyWith({
    CreateRentOrderStatus? opStatus,
    CreateRentOrderResponse? orderResponse,
    String? errorMsg,
    dynamic validationDetails,
    bool clearAll = false,
  }) {
    return CreateRentOrderState(
      opStatus: clearAll ? CreateRentOrderStatus.initial : opStatus ?? this.opStatus,
      orderResponse: clearAll ? null : orderResponse ?? this.orderResponse,
      errorMsg: clearAll ? null : errorMsg ?? this.errorMsg,
      validationDetails: clearAll ? null : validationDetails ?? this.validationDetails,
    );
  }
}

class CreateRentOrderViewModel extends StateNotifier<CreateRentOrderState> {
  final ChargeNowRentService _rentService;
  final RentedPowerBankService _rentedPowerBankService;
  final AuthRepository _authRepository;

  CreateRentOrderViewModel(
    this._rentService,
    this._rentedPowerBankService,
    this._authRepository,
  ) : super(CreateRentOrderState(opStatus: CreateRentOrderStatus.initial));

  Future<void> submitCreateRentOrder({
    required String deviceId,
    required String callbackURL,
    required Plan selectedPlan,
  }) async {
    // CRITICAL: Verify authentication before proceeding
    final currentUser = _authRepository.currentUser;
    if (currentUser == null) {
      log('ERROR: User not authenticated. Cannot save rent record.');
      state = state.copyWith(
        opStatus: CreateRentOrderStatus.error,
        errorMsg: "User not authenticated. Cannot save rent record.",
      );
      return;
    }

    log('Creating rent order for authenticated user: ${currentUser.uid}');

    if (deviceId.trim().isEmpty) {
      state = state.copyWith(
        opStatus: CreateRentOrderStatus.error,
        errorMsg: "Device ID cannot be empty.",
      );
      return;
    }
    
    if (callbackURL.trim().isEmpty || Uri.tryParse(callbackURL.trim())?.isAbsolute != true) {
      state = state.copyWith(
        opStatus: CreateRentOrderStatus.error,
        errorMsg: "A valid Callback URL is required.",
      );
      return;
    }

    try {
      state = state.copyWith(opStatus: CreateRentOrderStatus.loading, clearAll: true);

      final params = CreateRentOrderParams(
        deviceId: deviceId.trim(),
        callbackURL: callbackURL.trim(),
      );

      // Call ChargeNow API to create rent order
      final result = await _rentService.createRentOrder(params);

      // Check if API call was successful
      if (result.code == 0 && result.data != null) {
        final String tradeNo = result.data!.tradeNo;
        
        log('ChargeNow API call successful. TradeNo: $tradeNo');
        log('Saving rent record to Firestore for user: ${currentUser.uid}');

        // CRITICAL: Verify user is still authenticated before Firestore write
        final verifyUser = _authRepository.currentUser;
        if (verifyUser == null) {
          log('ERROR: User became unauthenticated during order creation!');
          state = state.copyWith(
            opStatus: CreateRentOrderStatus.error,
            errorMsg: "Authentication lost during order creation. Please try again.",
          );
          return;
        }

        if (verifyUser.uid != currentUser.uid) {
          log('ERROR: User UID mismatch! Original: ${currentUser.uid}, Current: ${verifyUser.uid}');
          state = state.copyWith(
            opStatus: CreateRentOrderStatus.error,
            errorMsg: "Authentication mismatch. Please log in again.",
          );
          return;
        }

        // Save the rented power bank record to Firestore
        try {
          await _rentedPowerBankService.saveRentedPowerBank(
            deviceId: deviceId,
            tradeNo: tradeNo,
            selectedPlan: selectedPlan,
          );
          
          log('✅ Rent order created successfully. TradeNo: $tradeNo');
          
          state = state.copyWith(
            opStatus: CreateRentOrderStatus.success,
            orderResponse: result,
          );
        } catch (firestoreError) {
          log('ERROR: Failed to save rent record to Firestore: ${firestoreError.toString()}');
          
          // Check if it's a permission error
          if (firestoreError.toString().contains('permission-denied') || 
              firestoreError.toString().contains('PERMISSION_DENIED')) {
            state = state.copyWith(
              opStatus: CreateRentOrderStatus.error,
              errorMsg: "Permission denied: User not authenticated. Please log in again.",
            );
          } else {
            state = state.copyWith(
              opStatus: CreateRentOrderStatus.error,
              errorMsg: "Failed to save rent record: ${firestoreError.toString()}",
            );
          }
        }
      } else {
        // API returned HTTP 200 but an error code in the body, or data was null
        log('ChargeNow API error. Code: ${result.code}, Message: ${result.msg}');
        state = state.copyWith(
          opStatus: CreateRentOrderStatus.error,
          errorMsg: result.msg.isNotEmpty 
            ? result.msg 
            : "Failed to create rent order (API Code: ${result.code}).",
        );
      }
    } on ChargeNowValidationException catch (e) {
      log('Validation exception: ${e.message}');
      state = state.copyWith(
        opStatus: CreateRentOrderStatus.error,
        errorMsg: e.message,
        validationDetails: e.errorDetail,
      );
    } on ChargeNowApiException catch (e) {
      log('ChargeNow API exception: ${e.message}');
      state = state.copyWith(
        opStatus: CreateRentOrderStatus.error,
        errorMsg: e.message,
      );
    } catch (e) {
      log('Unexpected error during rent order creation: ${e.toString()}');
      
      // Check for authentication-related errors
      if (e.toString().contains('permission-denied') ||
          e.toString().contains('PERMISSION_DENIED') ||
          e.toString().contains('UNAUTHENTICATED')) {
        state = state.copyWith(
          opStatus: CreateRentOrderStatus.error,
          errorMsg: "Authentication error: Please log in again.",
        );
      } else {
        state = state.copyWith(
          opStatus: CreateRentOrderStatus.error,
          errorMsg: "Order creation failed: ${e.toString()}",
        );
      }
    }
  }

  void resetState() {
    state = CreateRentOrderState(opStatus: CreateRentOrderStatus.initial);
  }
}