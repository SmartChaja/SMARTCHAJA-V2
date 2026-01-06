import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_chaja/features/chargenow_devices/api_exception/chargenow_api_exception.dart';
import 'package:smart_chaja/features/chargenow_devices/query_rent_order_status/model/query_rent_order_params.dart';
import 'package:smart_chaja/features/chargenow_devices/query_rent_order_status/service/charge_now_query_service.dart';
import 'package:smart_chaja/features/chargenow_devices/query_rent_order_status/view_models/query_rent_order_state.dart';

class QueryRentOrderViewModel extends StateNotifier<QueryRentOrderState> {
  final ChargeNowQueryService _queryService;

  QueryRentOrderViewModel(this._queryService)
      : super(QueryRentOrderState(status: QueryRentOrderStatus.initial));

  Future<void> queryRentOrder({
    required String tradeNo,
  }) async {
    if (tradeNo.trim().isEmpty) {
      state = state.copyWith(status: QueryRentOrderStatus.error, errorMsg: "Trade No cannot be empty.");
      return;
    }

    try {
      state = state.copyWith(status: QueryRentOrderStatus.loading, clearAll: true);

      final params = QueryRentOrderParams(
        tradeNo: tradeNo.trim(),
      );

      final result = await _queryService.queryRentOrder(params);

      if (result.code == 0) {
        state = state.copyWith(
          status: QueryRentOrderStatus.success,
          queryResponse: result,
        );
      } else {
        state = state.copyWith(
          status: QueryRentOrderStatus.error,
          errorMsg: result.msg.isNotEmpty ? result.msg : "Failed to query rent order (API Code: ${result.code}).",
        );
      }
    } on ChargeNowValidationException catch (e) {
      state = state.copyWith(status: QueryRentOrderStatus.error, errorMsg: e.message);
    } on ChargeNowApiException catch (e) {
      state = state.copyWith(status: QueryRentOrderStatus.error, errorMsg: e.message);
    } catch (e) {
      state = state.copyWith(status: QueryRentOrderStatus.error, errorMsg: "Order query failed: ${e.toString()}");
    }
  }

  void resetState() {
    state = QueryRentOrderState(status: QueryRentOrderStatus.initial);
  }
}