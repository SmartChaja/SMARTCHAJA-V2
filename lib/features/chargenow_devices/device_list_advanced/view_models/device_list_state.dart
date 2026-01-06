import 'package:smart_chaja/features/chargenow_devices/device_list_advanced/model/device_list_response.dart';

enum DeviceListStatus { initial, loading, success, error }

class DeviceListState {
  final DeviceListStatus status;
  final DeviceListResponse? deviceListResponse;
  final String? errorMsg;
  final dynamic validationDetails;

  DeviceListState({
    required this.status,
    this.deviceListResponse,
    this.errorMsg,
    this.validationDetails,
  });

  DeviceListState copyWith({
    DeviceListStatus? status,
    DeviceListResponse? deviceListResponse,
    String? errorMsg,
    bool clearAll = false,
  }) {
    return DeviceListState(
      status: clearAll ? DeviceListStatus.initial : status ?? this.status,
      deviceListResponse: clearAll ? null : deviceListResponse ?? this.deviceListResponse,
      errorMsg: clearAll ? null : errorMsg ?? this.errorMsg,
      validationDetails: clearAll ? null : validationDetails ?? this.validationDetails,
    );
  }
}