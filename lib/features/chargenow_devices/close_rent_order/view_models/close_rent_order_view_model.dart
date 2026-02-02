import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_chaja/features/chargenow_devices/api_exception/chargenow_api_exception.dart';
import 'package:smart_chaja/features/chargenow_devices/close_rent_order/model/close_rent_order_params.dart';
import 'package:smart_chaja/features/chargenow_devices/close_rent_order/service/charge_now_close_service.dart';
import 'package:smart_chaja/features/chargenow_devices/close_rent_order/view_models/close_rent_order_state.dart';
import 'package:smart_chaja/features/chargenow_devices/create_rent_order/service/rented_power_bank_service.dart';
import 'package:smart_chaja/authentication/beemafrica_service.dart/beem_sms_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void debugPrintSMS(String message) {
  if (kDebugMode) {
    debugPrint('💬 SMS Debug: $message');
  }
}

class CloseRentOrderViewModel extends StateNotifier<CloseRentOrderState> {
  final ChargeNowCloseService _closeService;
  final RentedPowerBankService _rentedPowerBankService;

  CloseRentOrderViewModel(
    this._closeService,
    this._rentedPowerBankService,
  ) : super(CloseRentOrderState(status: CloseRentOrderStatus.initial));

  Future<void> closeRentOrder({
    required String tradeNo,
  }) async {
    if (tradeNo.trim().isEmpty) {
      state = state.copyWith(
          status: CloseRentOrderStatus.error,
          errorMsg: "Trade No cannot be empty.");
      return;
    }

    try {
      state =
          state.copyWith(status: CloseRentOrderStatus.loading, clearAll: true);

      final params = CloseRentOrderParams(
        tradeNo: tradeNo.trim(),
      );

      final result = await _closeService.closeRentOrder(params);

      if (result.code == 0) {
        // Fetch rental details to send SMS
        try {
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null) {
            final rentalDetails = await _rentedPowerBankService
                .getRentedPowerBankByTradeNo(tradeNo.trim());

            if (rentalDetails != null) {
              final deviceId = rentalDetails['deviceId'] ?? 'Device';
              // Try to get phone number from multiple sources
              String userPhone = '';

              // First try: Rental details have user phone (preferred - stored at rental time)
              if (rentalDetails['userPhoneNumber'] != null &&
                  rentalDetails['userPhoneNumber'].toString().isNotEmpty) {
                userPhone = rentalDetails['userPhoneNumber'].toString();
                log('✅ Phone from rental record: $userPhone');
              }
              // Second try: Firebase phone number
              else if (currentUser.phoneNumber != null &&
                  currentUser.phoneNumber!.isNotEmpty) {
                userPhone = currentUser.phoneNumber!;
                log('✅ Phone from Firebase Auth: $userPhone');
              }
              // Third try: Fetch from users collection (fallback for old rentals)
              else {
                try {
                  final userDoc = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(currentUser.uid)
                      .get()
                      .timeout(
                        const Duration(seconds: 10),
                        onTimeout: () {
                          log('⚠️ Firestore fetch timeout');
                          throw TimeoutException('Firestore fetch timeout');
                        },
                      );

                  if (userDoc.exists) {
                    final userData = userDoc.data() as Map<String, dynamic>;
                    userPhone = userData['phoneNumber'] ?? '';
                    if (userPhone.isNotEmpty) {
                      log('✅ Phone from Firestore users collection: $userPhone');
                    }
                  }
                } catch (e) {
                  log('⚠️ Could not fetch phone from Firestore: $e');
                }
              }

              final userName = rentalDetails['userName'] ??
                  currentUser.displayName ??
                  'User';

              // Send SMS notification for successful power bank return
              try {
                final smsService = BeemSmsService();

                if (userPhone.isNotEmpty) {
                  log('📱 Attempting to send return SMS to: $userPhone');
                  final smsSent = await smsService.sendPowerBankReturnSMS(
                    phoneNumber: userPhone,
                    userName: userName,
                    deviceId: deviceId,
                    tradeNo: tradeNo.trim(),
                  );

                  if (smsSent) {
                    log('✅ SMS notification sent successfully for power bank return');
                  } else {
                    log('⚠️ Failed to send SMS notification, but return was successful');
                  }
                } else {
                  log('⚠️ No phone number available for SMS notification');
                  debugPrintSMS(
                      'Phone sources checked - Firebase: "${currentUser.phoneNumber}", Rental DB: "${rentalDetails['userPhoneNumber']}"');
                }
              } catch (smsError) {
                log('⚠️ SMS sending error (non-critical): $smsError');
                // Don't fail the operation if SMS fails
              }
            }
          }
        } catch (smsError) {
          log('⚠️ Error sending return SMS (non-critical): $smsError');
          // Don't fail the operation if SMS fails
        }

        state = state.copyWith(
          status: CloseRentOrderStatus.success,
          closeResponse: result,
        );
      } else {
        state = state.copyWith(
          status: CloseRentOrderStatus.error,
          errorMsg: result.msg.isNotEmpty
              ? result.msg
              : "Failed to close rent order (API Code: ${result.code}).",
        );
      }
    } on ChargeNowValidationException catch (e) {
      state = state.copyWith(
          status: CloseRentOrderStatus.error, errorMsg: e.message);
    } on ChargeNowApiException catch (e) {
      state = state.copyWith(
          status: CloseRentOrderStatus.error, errorMsg: e.message);
    } catch (e) {
      state = state.copyWith(
          status: CloseRentOrderStatus.error,
          errorMsg: "Order close failed: ${e.toString()}");
    }
  }

  void resetState() {
    state = CloseRentOrderState(status: CloseRentOrderStatus.initial);
  }
}
