import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_chaja/features/chargenow_devices/api_exception/chargenow_api_exception.dart';
import 'package:smart_chaja/features/chargenow_devices/order_list/model/order_list_params.dart';
import 'package:smart_chaja/features/chargenow_devices/order_list/service/charge_now_order_list_service.dart';
import 'package:smart_chaja/features/chargenow_devices/order_list/view_models/order_list_state.dart';

class OrderListViewModel extends StateNotifier<OrderListState> {
  final ChargeNowOrderListService _orderListService;

  OrderListViewModel(this._orderListService)
      : super(OrderListState(status: OrderListStatus.initial));

  Future<void> fetchOrderList({
    int? dataLevel,
    String? sTime,
    String? eTime,
    bool isLoadMore = false,
  }) async {
    final currentPage = isLoadMore ? state.currentPage + 1 : 1;
    final limit = state.pageSize;

    if (!isLoadMore && state.status == OrderListStatus.loading) return;
    if (isLoadMore && (state.status == OrderListStatus.loadingMore || state.currentPage >= state.totalPages)) return;

    try {
      state = state.copyWith(
        status: isLoadMore ? OrderListStatus.loadingMore : OrderListStatus.loading,
        records: isLoadMore ? state.records : [],
        currentPage: isLoadMore ? state.currentPage : 1,
      );

      final params = OrderListParams(
        page: currentPage,
        limit: limit,
        dataLevel: dataLevel,
        sTime: sTime,
        eTime: eTime,
      );

      final result = await _orderListService.getOrderList(params);

      if (result.code == 0 && result.page != null) {
        final newRecords = result.page!.records;
        state = state.copyWith(
          status: OrderListStatus.success,
          records: isLoadMore ? [...state.records, ...newRecords] : newRecords,
          currentPage: result.page!.current,
          totalPages: result.page!.pages,
          pageSize: result.page!.size,
        );
      } else {
        state = state.copyWith(
          status: OrderListStatus.error,
          errorMsg: result.msg.isNotEmpty ? result.msg : "Failed to fetch order list (API Code: ${result.code}).",
        );
      }
    } on ChargeNowValidationException catch (e) {
      state = state.copyWith(status: OrderListStatus.error, errorMsg: e.message);
    } on ChargeNowApiException catch (e) {
      state = state.copyWith(status: OrderListStatus.error, errorMsg: e.message);
    } catch (e) {
      state = state.copyWith(status: OrderListStatus.error, errorMsg: "Order list fetch failed: ${e.toString()}");
    }
  }

  void resetState() {
    state = OrderListState(status: OrderListStatus.initial);
  }
}