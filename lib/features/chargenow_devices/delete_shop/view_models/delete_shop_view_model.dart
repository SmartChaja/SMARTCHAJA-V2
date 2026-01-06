import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_chaja/features/chargenow_devices/api_exception/chargenow_api_exception.dart';
import 'package:smart_chaja/features/chargenow_devices/delete_shop/service/charge_now_delete_shop_service.dart';
import 'package:smart_chaja/features/chargenow_devices/delete_shop/view_models/delete_shop_state.dart';

class DeleteShopViewModel extends StateNotifier<DeleteShopState> {
  final ChargeNowDeleteShopService _deleteShopService;

  DeleteShopViewModel(this._deleteShopService)
      : super(DeleteShopState(status: DeleteShopStatus.initial));

  Future<void> deleteShop(String shopId) async {
    if (shopId.trim().isEmpty) {
      state = state.copyWith(status: DeleteShopStatus.error, errorMsg: "Shop ID cannot be empty.");
      return;
    }

    try {
      state = state.copyWith(status: DeleteShopStatus.loading, clearAll: true);

      final result = await _deleteShopService.deleteShop(shopId.trim());

      if (result.code == 0) {
        state = state.copyWith(
          status: DeleteShopStatus.success,
          deleteShopResponse: result,
        );
      } else {
        state = state.copyWith(
          status: DeleteShopStatus.error,
          errorMsg: result.msg.isNotEmpty ? result.msg : "Failed to delete shop (API Code: ${result.code}).",
        );
      }
    } on ChargeNowValidationException catch (e) {
      state = state.copyWith(status: DeleteShopStatus.error, errorMsg: e.message);
    } on ChargeNowApiException catch (e) {
      state = state.copyWith(status: DeleteShopStatus.error, errorMsg: e.message);
    } catch (e) {
      state = state.copyWith(status: DeleteShopStatus.error, errorMsg: "Shop deletion failed: ${e.toString()}");
    }
  }

  void resetState() {
    state = DeleteShopState(status: DeleteShopStatus.initial);
  }
}