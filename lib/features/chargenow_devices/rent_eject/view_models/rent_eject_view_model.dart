import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_chaja/features/chargenow_devices/api_exception/chargenow_api_exception.dart';
import 'package:smart_chaja/features/chargenow_devices/rent_eject/model/rent_eject_params.dart';
import 'package:smart_chaja/features/chargenow_devices/rent_eject/service/charge_now_rent_eject_service.dart';
import 'package:smart_chaja/features/chargenow_devices/rent_eject/view_models/rent_eject_state.dart';

class RentEjectViewModel extends StateNotifier<RentEjectState> {
  final ChargeNowRentEjectService _rentEjectService;

  RentEjectViewModel(this._rentEjectService)
      : super(RentEjectState(status: RentEjectStatus.initial));

  Future<void> rentEjectBattery({
    required String cabinetId,
    required String rentOrderId,
    required String slotNum,
  }) async {
    if (cabinetId.trim().isEmpty) {
      state = state.copyWith(status: RentEjectStatus.error, errorMsg: "Cabinet ID cannot be empty.");
      return;
    }
    if (rentOrderId.trim().isEmpty) {
      state = state.copyWith(status: RentEjectStatus.error, errorMsg: "Rent Order ID cannot be empty.");
      return;
    }
    if (slotNum.trim().isEmpty) {
      state = state.copyWith(status: RentEjectStatus.error, errorMsg: "Slot Number cannot be empty.");
      return;
    }

    try {
      state = state.copyWith(status: RentEjectStatus.loading, clearAll: true);

      final params = RentEjectParams(
        cabinetId: cabinetId.trim(),
        rentOrderId: rentOrderId.trim(),
        slotNum: slotNum.trim(),
      );

      final result = await _rentEjectService.rentEjectBattery(params);

      if (result.code == 0) {
        state = state.copyWith(
          status: RentEjectStatus.success,
          rentEjectResponse: result,
        );
      } else {
        state = state.copyWith(
          status: RentEjectStatus.error,
          errorMsg: result.msg.isNotEmpty ? result.msg : "Failed to rent and eject battery (API Code: ${result.code}).",
        );
      }
    } on ChargeNowValidationException catch (e) {
      state = state.copyWith(status: RentEjectStatus.error, errorMsg: e.message);
    } on ChargeNowApiException catch (e) {
      state = state.copyWith(status: RentEjectStatus.error, errorMsg: e.message);
    } catch (e) {
      state = state.copyWith(status: RentEjectStatus.error, errorMsg: "Battery rent and eject failed: ${e.toString()}");
    }
  }

  void resetState() {
    state = RentEjectState(status: RentEjectStatus.initial);
  }
}