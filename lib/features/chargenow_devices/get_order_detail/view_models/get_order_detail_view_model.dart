import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_chaja/features/chargenow_devices/api_exception/chargenow_api_exception.dart';
import 'package:smart_chaja/features/chargenow_devices/get_order_detail/model/get_order_detail_params.dart';
import 'package:smart_chaja/features/chargenow_devices/get_order_detail/service/charge_now_detail_service.dart';
import 'package:smart_chaja/features/chargenow_devices/get_order_detail/view_models/get_order_detail_state.dart';

class GetOrderDetailViewModel extends StateNotifier<GetOrderDetailState> {
  final ChargeNowDetailService _detailService;

  GetOrderDetailViewModel(this._detailService)
      : super(GetOrderDetailState(status: GetOrderDetailStatus.initial));

  Future<void> getOrderDetail({
    required String tradeNo,
  }) async {
    if (tradeNo.trim().isEmpty) {
      state = state.copyWith(status: GetOrderDetailStatus.error, errorMsg: "Trade No cannot be empty.");
      return;
    }

    try {
      // When going to loading, clear previous success/error data
      state = state.copyWith(status: GetOrderDetailStatus.loading, detailResponse: null, errorMsg: null);

      final params = GetOrderDetailParams(
        tradeNo: tradeNo.trim(),
      );

      final result = await _detailService.getOrderDetail(params);

      if (result.code == 0 && result.data != null) {
        state = state.copyWith(
          status: GetOrderDetailStatus.success,
          detailResponse: result,
        );
      } else {
        state = state.copyWith(
          status: GetOrderDetailStatus.error,
          errorMsg: result.msg.isNotEmpty ? result.msg : "Failed to fetch order details (API Code: ${result.code}).",
        );
      }
    } on ChargeNowValidationException catch (e) {
      state = state.copyWith(status: GetOrderDetailStatus.error, errorMsg: e.message);
    } on ChargeNowApiException catch (e) {
      state = state.copyWith(status: GetOrderDetailStatus.error, errorMsg: e.message);
    } catch (e) {
      // Catch all other exceptions, including the 'double' to 'int' conversion error
      state = state.copyWith(status: GetOrderDetailStatus.error, errorMsg: "Order detail fetch failed: ${e.toString()}");
    }
  }

  void resetState() {
    state = GetOrderDetailState(status: GetOrderDetailStatus.initial);
  }
}