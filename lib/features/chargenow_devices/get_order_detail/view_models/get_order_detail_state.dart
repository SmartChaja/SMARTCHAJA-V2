// Keep this file as is. No changes needed here for the error fix or UI.
import 'package:smart_chaja/features/chargenow_devices/get_order_detail/model/get_order_detail_response.dart';

enum GetOrderDetailStatus { initial, loading, success, error }

class GetOrderDetailState {
  final GetOrderDetailStatus status;
  final GetOrderDetailResponse? detailResponse;
  final String? errorMsg;
  final dynamic validationDetails; // Can be used for more specific error details

  GetOrderDetailState({
    required this.status,
    this.detailResponse,
    this.errorMsg,
    this.validationDetails,
  });

  GetOrderDetailState copyWith({
    GetOrderDetailStatus? status,
    GetOrderDetailResponse? detailResponse,
    String? errorMsg,
    bool clearAll = false, // If true, resets all mutable fields to initial/null
  }) {
    return GetOrderDetailState(
      status: clearAll ? GetOrderDetailStatus.initial : status ?? this.status,
      detailResponse: clearAll ? null : detailResponse ?? this.detailResponse,
      errorMsg: clearAll ? null : errorMsg ?? this.errorMsg,
      validationDetails: clearAll ? null : validationDetails ?? this.validationDetails,
    );
  }
}