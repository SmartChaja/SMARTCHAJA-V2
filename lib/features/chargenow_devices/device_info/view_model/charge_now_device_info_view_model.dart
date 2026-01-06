// File: lib/features/chargenow_devices/device_info/view_model/charge_now_device_info_view_model.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_chaja/features/chargenow_devices/api_exception/chargenow_api_exception.dart';
import 'package:smart_chaja/features/chargenow_devices/device_info/model/charge_now_device_info_response.dart';
import 'package:smart_chaja/features/chargenow_devices/device_info/service/charge_now_service.dart';


enum DeviceInfoStatus { initial, loading, success, error, notFound }

class DeviceInfoState {
  final DeviceInfoStatus status;
  final DeviceInfoData? deviceInfo;
  final String? errorMsg;
  // Optionally, store the specific ChargeNowApiException for more detailed error handling in UI if needed
  final ChargeNowApiException? apiException;

  DeviceInfoState({
    required this.status,
    this.deviceInfo,
    this.errorMsg,
    this.apiException,
  });

  DeviceInfoState copyWith({
    DeviceInfoStatus? status,
    DeviceInfoData? deviceInfo,
    String? errorMsg,
    ChargeNowApiException? apiException,
    bool clearError = false, // Clears both errorMsg and apiException
    bool clearDeviceInfo = false,
  }) {
    return DeviceInfoState(
      status: status ?? this.status,
      deviceInfo: clearDeviceInfo ? null : deviceInfo ?? this.deviceInfo,
      errorMsg: clearError ? null : errorMsg ?? this.errorMsg,
      apiException: clearError ? null : apiException ?? this.apiException,
    );
  }
}

class ChargeNowDeviceInfoViewModel extends StateNotifier<DeviceInfoState> {
  final ChargeNowService _service;
  final String deviceId;

  ChargeNowDeviceInfoViewModel(this._service, this.deviceId)
      : super(DeviceInfoState(status: DeviceInfoStatus.initial));

  Future<void> fetchDeviceInfo({bool forceRefresh = false}) async {
    if (state.status == DeviceInfoStatus.loading && !forceRefresh) return;
    // If already success and not forcing refresh, don't re-fetch.
    if (state.status == DeviceInfoStatus.success && state.deviceInfo != null && !forceRefresh) return;

    state = state.copyWith(status: DeviceInfoStatus.loading, clearError: true, clearDeviceInfo: true); // Clear previous data on new fetch attempt
    try {
      final response = await _service.getDeviceInfo(deviceId); // This service method throws ChargeNowApiException

      // The service layer now throws ChargeNowApiException for HTTP errors or API internal errors.
      // So, if we reach here, it means HTTP status was 200 and API internal code was 0.
      if (response.data != null) {
        state = state.copyWith(status: DeviceInfoStatus.success, deviceInfo: response.data);
      } else {
        // This case might occur if API returns code 0 but data is unexpectedly null
        state = state.copyWith(
            status: DeviceInfoStatus.error, // Or notFound if more appropriate
            errorMsg: response.msg.isNotEmpty ? response.msg : "Device data is missing despite successful response.",
            apiException: ChargeNowApiException(message: response.msg, apiInternalCode: response.code.toString(), errorDetail: "Data field was null")
        );
      }
    } on ChargeNowValidationException catch (e) { // Specific subtype for 422
        print("ViewModel: Caught ChargeNowValidationException - ${e.message}");
        state = state.copyWith(
          status: DeviceInfoStatus.error,
          errorMsg: e.message,
          apiException: e,
        );
    } on ChargeNowApiException catch (e) { // Catches all other ChargeNowApiExceptions (400, 401, 5xx, or code !=0)
        print("ViewModel: Caught ChargeNowApiException (Status: ${e.statusCode}, API Code: ${e.apiInternalCode}) - ${e.message}");
        // Check if the API exception indicates a "not found" scenario, e.g., by specific message or internal code
        // This depends on how your API signals "not found" vs other errors.
        // For now, a general error is set. If your service layer throws a specific ChargeNowNotFoundException,
        // you could catch that separately.
        // The service layer's getDeviceInfo already handles HTTP 404 by potentially throwing NotFoundException
        // if you map it in ChargeNowApiException.fromResponse.
        // Let's assume `fromResponse` could return a base ChargeNowApiException that implies not found by its message.
        bool isNotFound = (e.statusCode == 404) || (e.message.toLowerCase().contains("not found")); // Example check

        state = state.copyWith(
          status: isNotFound ? DeviceInfoStatus.notFound : DeviceInfoStatus.error,
          errorMsg: e.message,
          apiException: e,
        );
    } catch (e) { // Catches other unexpected errors (e.g., programming errors in this ViewModel)
      print("ViewModel: Caught generic Exception - ${e.toString()}");
      state = state.copyWith(
        status: DeviceInfoStatus.error,
        errorMsg: "An unexpected error occurred: ${e.toString()}",
        // Optionally create a generic ChargeNowApiException for consistency if desired
        // apiException: ChargeNowApiException(message: "Unexpected error: ${e.toString()}"),
      );
    }
  }

  void resetState() {
    state = DeviceInfoState(status: DeviceInfoStatus.initial);
  }
}