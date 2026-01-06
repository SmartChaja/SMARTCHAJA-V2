import 'package:smart_chaja/features/chargenow_devices/close_rent_order/model/close_rent_order_response.dart';

enum CloseRentOrderStatus { initial, loading, success, error }

class CloseRentOrderState {
  final CloseRentOrderStatus status;
  final CloseRentOrderResponse? closeResponse;
  final String? errorMsg;
  final dynamic validationDetails;

  CloseRentOrderState({
    required this.status,
    this.closeResponse,
    this.errorMsg,
    this.validationDetails,
  });

  CloseRentOrderState copyWith({
    CloseRentOrderStatus? status,
    CloseRentOrderResponse? closeResponse,
    String? errorMsg,
    bool clearAll = false,
  }) {
    return CloseRentOrderState(
      status: clearAll ? CloseRentOrderStatus.initial : status ?? this.status,
      closeResponse: clearAll ? null : closeResponse ?? this.closeResponse,
      errorMsg: clearAll ? null : errorMsg ?? this.errorMsg,
      validationDetails: clearAll ? null : validationDetails ?? this.validationDetails,
    );
  }
}