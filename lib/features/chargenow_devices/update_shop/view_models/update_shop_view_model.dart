import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_chaja/features/chargenow_devices/api_exception/chargenow_api_exception.dart';
import 'package:smart_chaja/features/chargenow_devices/update_shop/model/shop_params.dart';
import 'package:smart_chaja/features/chargenow_devices/update_shop/service/charge_now_update_shop_service.dart';
import 'package:smart_chaja/features/chargenow_devices/update_shop/view_models/update_shop_state.dart';

class UpdateShopViewModel extends StateNotifier<UpdateShopState> {
  final ChargeNowUpdateShopService _updateShopService;

  UpdateShopViewModel(this._updateShopService)
      : super(UpdateShopState(status: UpdateShopStatus.initial));

  Future<void> updateShop({
    required String pNewid,
    required String pName,
    int? pSceneType,
    int? pStoreType,
    String? pAddress,
    required String pJingdu,
    required String pWeidu,
    int? pAuditor,
    String? pContent,
    String? pCurrency,
    String? pLocationId,
    String? pLogo,
  }) async {
    if (pNewid.trim().isEmpty) {
      state = state.copyWith(status: UpdateShopStatus.error, errorMsg: "Shop ID cannot be empty.");
      return;
    }
    if (pName.trim().isEmpty) {
      state = state.copyWith(status: UpdateShopStatus.error, errorMsg: "Shop Name cannot be empty.");
      return;
    }
    if (pJingdu.trim().isEmpty) {
      state = state.copyWith(status: UpdateShopStatus.error, errorMsg: "Longitude cannot be empty.");
      return;
    }
    if (pWeidu.trim().isEmpty) {
      state = state.copyWith(status: UpdateShopStatus.error, errorMsg: "Latitude cannot be empty.");
      return;
    }

    try {
      state = state.copyWith(status: UpdateShopStatus.loading, clearAll: true);

      final params = ShopParams(
        pNewid: pNewid.trim(),
        pName: pName.trim(),
        pSceneType: pSceneType,
        pStoreType: pStoreType,
        pAddress: pAddress?.trim(),
        pJingdu: pJingdu.trim(),
        pWeidu: pWeidu.trim(),
        pAuditor: pAuditor,
        pContent: pContent?.trim(),
        pCurrency: pCurrency?.trim(),
        pLocationId: pLocationId?.trim(),
        pLogo: pLogo?.trim(),
      );

      final result = await _updateShopService.updateShop(params);

      if (result.code == 0 || result.code == 1) {
        state = state.copyWith(
          status: UpdateShopStatus.success,
          updateShopResponse: result,
        );
      } else {
        state = state.copyWith(
          status: UpdateShopStatus.error,
          errorMsg: result.msg.isNotEmpty ? result.msg : "Failed to update shop (API Code: ${result.code}).",
        );
      }
    } on ChargeNowValidationException catch (e) {
      state = state.copyWith(status: UpdateShopStatus.error, errorMsg: e.message);
    } on ChargeNowApiException catch (e) {
      state = state.copyWith(status: UpdateShopStatus.error, errorMsg: e.message);
    } catch (e) {
      state = state.copyWith(status: UpdateShopStatus.error, errorMsg: "Shop update failed: ${e.toString()}");
    }
  }

  void resetState() {
    state = UpdateShopState(status: UpdateShopStatus.initial);
  }
}