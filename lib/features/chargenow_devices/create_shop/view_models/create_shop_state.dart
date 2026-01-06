import 'package:smart_chaja/features/chargenow_devices/create_shop/model/create_shop_response.dart';

enum CreateShopStatus { initial, loading, success, error }

class CreateShopState {
  final CreateShopStatus status;
  final CreateShopResponse? createShopResponse;
  final String? errorMsg;
  final dynamic validationDetails;

  CreateShopState({
    required this.status,
    this.createShopResponse,
    this.errorMsg,
    this.validationDetails,
  });

  CreateShopState copyWith({
    CreateShopStatus? status,
    CreateShopResponse? createShopResponse,
    String? errorMsg,
    bool clearAll = false,
  }) {
    return CreateShopState(
      status: clearAll ? CreateShopStatus.initial : status ?? this.status,
      createShopResponse: clearAll ? null : createShopResponse ?? this.createShopResponse,
      errorMsg: clearAll ? null : errorMsg ?? this.errorMsg,
      validationDetails: clearAll ? null : validationDetails ?? this.validationDetails,
    );
  }
}