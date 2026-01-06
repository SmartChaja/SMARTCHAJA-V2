import 'package:smart_chaja/features/chargenow_devices/delete_shop/model/delete_shop_response.dart';

enum DeleteShopStatus { initial, loading, success, error }

class DeleteShopState {
  final DeleteShopStatus status;
  final DeleteShopResponse? deleteShopResponse;
  final String? errorMsg;
  final dynamic validationDetails;

  DeleteShopState({
    required this.status,
    this.deleteShopResponse,
    this.errorMsg,
    this.validationDetails,
  });

  DeleteShopState copyWith({
    DeleteShopStatus? status,
    DeleteShopResponse? deleteShopResponse,
    String? errorMsg,
    bool clearAll = false,
  }) {
    return DeleteShopState(
      status: clearAll ? DeleteShopStatus.initial : status ?? this.status,
      deleteShopResponse: clearAll ? null : deleteShopResponse ?? this.deleteShopResponse,
      errorMsg: clearAll ? null : errorMsg ?? this.errorMsg,
      validationDetails: clearAll ? null : validationDetails ?? this.validationDetails,
    );
  }
}