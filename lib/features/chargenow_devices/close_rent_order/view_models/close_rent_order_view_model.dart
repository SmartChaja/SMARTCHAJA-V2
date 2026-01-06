import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_chaja/features/chargenow_devices/api_exception/chargenow_api_exception.dart';
import 'package:smart_chaja/features/chargenow_devices/close_rent_order/model/close_rent_order_params.dart';
import 'package:smart_chaja/features/chargenow_devices/close_rent_order/service/charge_now_close_service.dart';
import 'package:smart_chaja/features/chargenow_devices/close_rent_order/view_models/close_rent_order_state.dart';

class CloseRentOrderViewModel extends StateNotifier<CloseRentOrderState> {
  final ChargeNowCloseService _closeService;

  CloseRentOrderViewModel(this._closeService)
      : super(CloseRentOrderState(status: CloseRentOrderStatus.initial));

  Future<void> closeRentOrder({
    required String tradeNo,
  }) async {
    if (tradeNo.trim().isEmpty) {
      state = state.copyWith(status: CloseRentOrderStatus.error, errorMsg: "Trade No cannot be empty.");
      return;
    }

    try {
      state = state.copyWith(status: CloseRentOrderStatus.loading, clearAll: true);

      final params = CloseRentOrderParams(
        tradeNo: tradeNo.trim(),
      );

      final result = await _closeService.closeRentOrder(params);

      if (result.code == 0) {
        state = state.copyWith(
          status: CloseRentOrderStatus.success,
          closeResponse: result,
        );
      } else {
        state = state.copyWith(
          status: CloseRentOrderStatus.error,
          errorMsg: result.msg.isNotEmpty ? result.msg : "Failed to close rent order (API Code: ${result.code}).",
        );
      }
    } on ChargeNowValidationException catch (e) {
      state = state.copyWith(status: CloseRentOrderStatus.error, errorMsg: e.message);
    } on ChargeNowApiException catch (e) {
      state = state.copyWith(status: CloseRentOrderStatus.error, errorMsg: e.message);
    } catch (e) {
      state = state.copyWith(status: CloseRentOrderStatus.error, errorMsg: "Order close failed: ${e.toString()}");
    }
  }

  void resetState() {
    state = CloseRentOrderState(status: CloseRentOrderStatus.initial);
  }
}