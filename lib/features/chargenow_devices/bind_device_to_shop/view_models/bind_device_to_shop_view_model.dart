import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_chaja/features/chargenow_devices/api_exception/chargenow_api_exception.dart';
import 'package:smart_chaja/features/chargenow_devices/bind_device_to_shop/service/charge_now_bind_device_to_shop_service.dart';
import 'package:smart_chaja/features/chargenow_devices/bind_device_to_shop/view_models/bind_device_to_shop_state.dart';

class BindDeviceToShopViewModel extends StateNotifier<BindDeviceToShopState> {
  final ChargeNowBindDeviceToShopService _bindDeviceToShopService;

  BindDeviceToShopViewModel(this._bindDeviceToShopService)
      : super(BindDeviceToShopState(status: BindDeviceToShopStatus.initial));

  Future<void> bindDeviceToShop(String qrCode, String shopId) async {
    if (qrCode.trim().isEmpty) {
      state = state.copyWith(status: BindDeviceToShopStatus.error, errorMsg: "Device ID or QR Code cannot be empty.");
      return;
    }
    if (shopId.trim().isEmpty) {
      state = state.copyWith(status: BindDeviceToShopStatus.error, errorMsg: "Shop ID cannot be empty.");
      return;
    }

    try {
      state = state.copyWith(status: BindDeviceToShopStatus.loading, clearAll: true);

      final result = await _bindDeviceToShopService.bindDeviceToShop(qrCode.trim(), shopId.trim());

      if (result.code == 0 || result.code == 1) {
        state = state.copyWith(
          status: BindDeviceToShopStatus.success,
          bindDeviceToShopResponse: result,
        );
      } else {
        state = state.copyWith(
          status: BindDeviceToShopStatus.error,
          errorMsg: result.msg.isNotEmpty ? result.msg : "Failed to bind device to shop (API Code: ${result.code}).",
        );
      }
    } on ChargeNowValidationException catch (e) {
      state = state.copyWith(status: BindDeviceToShopStatus.error, errorMsg: e.message);
    } on ChargeNowApiException catch (e) {
      state = state.copyWith(status: BindDeviceToShopStatus.error, errorMsg: e.message);
    } catch (e) {
      state = state.copyWith(status: BindDeviceToShopStatus.error, errorMsg: "Device binding failed: ${e.toString()}");
    }
  }

  void resetState() {
    state = BindDeviceToShopState(status: BindDeviceToShopStatus.initial);
  }
}