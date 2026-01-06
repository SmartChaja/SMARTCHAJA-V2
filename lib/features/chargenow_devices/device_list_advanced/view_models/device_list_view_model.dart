import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_chaja/features/chargenow_devices/api_exception/chargenow_api_exception.dart';
import 'package:smart_chaja/features/chargenow_devices/device_list_advanced/service/charge_now_device_list_service.dart';
import 'package:smart_chaja/features/chargenow_devices/device_list_advanced/view_models/device_list_state.dart';

class DeviceListViewModel extends StateNotifier<DeviceListState> {
  final ChargeNowDeviceListService _deviceListService;

  DeviceListViewModel(this._deviceListService)
      : super(DeviceListState(status: DeviceListStatus.initial));

  Future<void> fetchAllDevices() async {
    try {
      state = state.copyWith(status: DeviceListStatus.loading, clearAll: true);

      final result = await _deviceListService.getAllDevices();

      if (result.code == 0 && result.data != null) {
        state = state.copyWith(
          status: DeviceListStatus.success,
          deviceListResponse: result,
        );
      } else {
        state = state.copyWith(
          status: DeviceListStatus.error,
          errorMsg: result.msg?.isNotEmpty == true ? result.msg : "Failed to fetch device list (API Code: ${result.code}).",
        );
      }
    } on ChargeNowValidationException catch (e) {
      state = state.copyWith(status: DeviceListStatus.error, errorMsg: e.message);
    } on ChargeNowApiException catch (e) {
      state = state.copyWith(status: DeviceListStatus.error, errorMsg: e.message);
    } catch (e) {
      state = state.copyWith(status: DeviceListStatus.error, errorMsg: "Device list fetch failed: ${e.toString()}");
    }
  }

  void resetState() {
    state = DeviceListState(status: DeviceListStatus.initial);
  }
}