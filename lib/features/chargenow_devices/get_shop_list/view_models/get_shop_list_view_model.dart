import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_chaja/features/chargenow_devices/api_exception/chargenow_api_exception.dart';
import 'package:smart_chaja/features/chargenow_devices/get_shop_list/service/charge_now_get_shop_list_service.dart';
import 'package:smart_chaja/features/chargenow_devices/get_shop_list/view_models/get_shop_list_state.dart';

class GetShopListViewModel extends StateNotifier<GetShopListState> {
  final ChargeNowGetShopListService _getShopListService;

  GetShopListViewModel(this._getShopListService)
      : super(GetShopListState(status: GetShopListStatus.initial));

  Future<void> fetchShopList() async {
    if (state.status == GetShopListStatus.loading) return;

    try {
      state = state.copyWith(status: GetShopListStatus.loading, clearAll: true);

      final result = await _getShopListService.getShopList();

      if (result.code == 0 && result.data != null) {
        state = state.copyWith(
          status: GetShopListStatus.success,
          shops: result.data,
        );
      } else {
        state = state.copyWith(
          status: GetShopListStatus.error,
          errorMsg: result.msg.isNotEmpty ? result.msg : "Failed to fetch shop list (API Code: ${result.code}).",
        );
      }
    } on ChargeNowValidationException catch (e) {
      state = state.copyWith(status: GetShopListStatus.error, errorMsg: e.message);
    } on ChargeNowApiException catch (e) {
      state = state.copyWith(status: GetShopListStatus.error, errorMsg: e.message);
    } catch (e) {
      state = state.copyWith(status: GetShopListStatus.error, errorMsg: "Shop list fetch failed: ${e.toString()}");
    }
  }

  void resetState() {
    state = GetShopListState(status: GetShopListStatus.initial);
  }
}