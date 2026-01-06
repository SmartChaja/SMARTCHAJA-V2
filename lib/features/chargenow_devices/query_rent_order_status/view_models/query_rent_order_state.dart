import 'package:smart_chaja/features/chargenow_devices/query_rent_order_status/model/query_rent_order_response.dart';

enum QueryRentOrderStatus { initial, loading, success, error }

class QueryRentOrderState {
  final QueryRentOrderStatus status;
  final QueryRentOrderResponse? queryResponse;
  final String? errorMsg;
  final dynamic validationDetails;

  QueryRentOrderState({
    required this.status,
    this.queryResponse,
    this.errorMsg,
    this.validationDetails,
  });

  QueryRentOrderState copyWith({
    QueryRentOrderStatus? status,
    QueryRentOrderResponse? queryResponse,
    String? errorMsg,
    bool clearAll = false,
  }) {
    return QueryRentOrderState(
      status: clearAll ? QueryRentOrderStatus.initial : status ?? this.status,
      queryResponse: clearAll ? null : queryResponse ?? this.queryResponse,
      errorMsg: clearAll ? null : errorMsg ?? this.errorMsg,
      validationDetails: clearAll ? null : validationDetails ?? this.validationDetails,
    );
  }
}