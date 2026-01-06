import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_chaja/features/chargenow_devices/api_exception/chargenow_api_exception.dart';
import 'package:smart_chaja/features/chargenow_devices/create_shop/model/create_shop_params.dart';
import 'package:smart_chaja/features/chargenow_devices/create_shop/service/charge_now_create_shop_service.dartcharge_now_create_shop_service.dart';
import 'package:smart_chaja/features/chargenow_devices/create_shop/view_models/create_shop_state.dart';

class CreateShopViewModel extends StateNotifier<CreateShopState> {
  final ChargeNowCreateShopService _createShopService;

  CreateShopViewModel(this._createShopService)
      : super(CreateShopState(status: CreateShopStatus.initial));

  Future<void> createShop({
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
      state = state.copyWith(status: CreateShopStatus.error, errorMsg: "Shop ID cannot be empty.");
      return;
    }
    if (pName.trim().isEmpty) {
      state = state.copyWith(status: CreateShopStatus.error, errorMsg: "Shop Name cannot be empty.");
      return;
    }
    if (pJingdu.trim().isEmpty) {
      state = state.copyWith(status: CreateShopStatus.error, errorMsg: "Longitude cannot be empty.");
      return;
    }
    if (pWeidu.trim().isEmpty) {
      state = state.copyWith(status: CreateShopStatus.error, errorMsg: "Latitude cannot be empty.");
      return;
    }

    try {
      state = state.copyWith(status: CreateShopStatus.loading, clearAll: true);

      final params = CreateShopParams(
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

      final result = await _createShopService.createShop(params);

      if (result.code == 0 || result.code == 1) {
        state = state.copyWith(
          status: CreateShopStatus.success,
          createShopResponse: result,
        );
      } else {
        state = state.copyWith(
          status: CreateShopStatus.error,
          errorMsg: result.msg.isNotEmpty ? result.msg : "Failed to create shop (API Code: ${result.code}).",
        );
      }
    } on ChargeNowValidationException catch (e) {
      state = state.copyWith(status: CreateShopStatus.error, errorMsg: e.message);
    } on ChargeNowApiException catch (e) {
      state = state.copyWith(status: CreateShopStatus.error, errorMsg: e.message);
    } catch (e) {
      state = state.copyWith(status: CreateShopStatus.error, errorMsg: "Shop creation failed: ${e.toString()}");
    }
  }

  void resetState() {
    state = CreateShopState(status: CreateShopStatus.initial);
  }
}