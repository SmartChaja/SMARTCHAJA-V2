import 'package:smart_chaja/features/chargenow_devices/update_shop/model/update_shop_response.dart';

enum UpdateShopStatus { initial, loading, success, error }

class UpdateShopState {
  final UpdateShopStatus status;
  final UpdateShopResponse? updateShopResponse;
  final String? errorMsg;
  final dynamic validationDetails;

  UpdateShopState({
    required this.status,
    this.updateShopResponse,
    this.errorMsg,
    this.validationDetails,
  });

  UpdateShopState copyWith({
    UpdateShopStatus? status,
    UpdateShopResponse? updateShopResponse,
    String? errorMsg,
    bool clearAll = false,
  }) {
    return UpdateShopState(
      status: clearAll ? UpdateShopStatus.initial : status ?? this.status,
      updateShopResponse: clearAll ? null : updateShopResponse ?? this.updateShopResponse,
      errorMsg: clearAll ? null : errorMsg ?? this.errorMsg,
      validationDetails: clearAll ? null : validationDetails ?? this.validationDetails,
    );
  }
}