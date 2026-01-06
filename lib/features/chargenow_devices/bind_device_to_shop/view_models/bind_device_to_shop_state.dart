import 'package:smart_chaja/features/chargenow_devices/bind_device_to_shop/model/bind_device_to_shop_response.dart';

enum BindDeviceToShopStatus { initial, loading, success, error }

class BindDeviceToShopState {
  final BindDeviceToShopStatus status;
  final BindDeviceToShopResponse? bindDeviceToShopResponse;
  final String? errorMsg;
  final dynamic validationDetails;

  BindDeviceToShopState({
    required this.status,
    this.bindDeviceToShopResponse,
    this.errorMsg,
    this.validationDetails,
  });

  BindDeviceToShopState copyWith({
    BindDeviceToShopStatus? status,
    BindDeviceToShopResponse? bindDeviceToShopResponse,
    String? errorMsg,
    bool clearAll = false,
  }) {
    return BindDeviceToShopState(
      status: clearAll ? BindDeviceToShopStatus.initial : status ?? this.status,
      bindDeviceToShopResponse: clearAll ? null : bindDeviceToShopResponse ?? this.bindDeviceToShopResponse,
      errorMsg: clearAll ? null : errorMsg ?? this.errorMsg,
      validationDetails: clearAll ? null : validationDetails ?? this.validationDetails,
    );
  }
}