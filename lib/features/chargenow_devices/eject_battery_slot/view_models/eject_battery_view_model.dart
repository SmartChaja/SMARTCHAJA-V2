import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_chaja/features/chargenow_devices/api_exception/chargenow_api_exception.dart';
import 'package:smart_chaja/features/chargenow_devices/eject_battery_slot/model/eject_battery_params.dart';
import 'package:smart_chaja/features/chargenow_devices/eject_battery_slot/service/charge_now_eject_service.dart';
import 'package:smart_chaja/features/chargenow_devices/eject_battery_slot/view_models/eject_battery_state.dart';

class EjectBatteryViewModel extends StateNotifier<EjectBatteryState> {
  final ChargeNowEjectService _ejectService;

  EjectBatteryViewModel(this._ejectService)
      : super(EjectBatteryState(status: EjectBatteryStatus.initial));

  Future<void> ejectBattery({
    required String cabinetId,
    String? slotNum,
  }) async {
    if (cabinetId.trim().isEmpty) {
      state = state.copyWith(status: EjectBatteryStatus.error, errorMsg: "Cabinet ID cannot be empty.");
      return;
    }

    try {
      state = state.copyWith(status: EjectBatteryStatus.loading, clearAll: true);

      final params = EjectBatteryParams(
        cabinetId: cabinetId.trim(),
        slotNum: slotNum?.trim(),
      );

      final result = await _ejectService.ejectBattery(params);

      if (result.code == 0) {
        state = state.copyWith(
          status: EjectBatteryStatus.success,
          ejectResponse: result,
        );
      } else {
        state = state.copyWith(
          status: EjectBatteryStatus.error,
          errorMsg: result.msg.isNotEmpty ? result.msg : "Failed to eject battery (API Code: ${result.code}).",
        );
      }
    } on ChargeNowValidationException catch (e) {
      state = state.copyWith(status: EjectBatteryStatus.error, errorMsg: e.message);
    } on ChargeNowApiException catch (e) {
      state = state.copyWith(status: EjectBatteryStatus.error, errorMsg: e.message);
    } catch (e) {
      state = state.copyWith(status: EjectBatteryStatus.error, errorMsg: "Battery ejection failed: ${e.toString()}");
    }
  }

  void resetState() {
    state = EjectBatteryState(status: EjectBatteryStatus.initial);
  }
}