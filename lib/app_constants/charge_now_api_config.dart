// File: lib/app_constants/charge_now_api_config.dart
class ChargeNowApiConfig {
  static const String baseUrl = "https://developer.chargenow.top/cdb-open-api/v1";

  // Endpoints for ChargeNow
  static String get deviceListUrl => '$baseUrl/rent/cabinet/list';
  static String get deviceInfoUrl => '$baseUrl/rent/cabinet/query';
  static String get createRentOrderUrl => '$baseUrl/rent/order/create';
  static const String queryRentOrderUrl = '$baseUrl/rent/order/query';
  static const String closeRentOrderUrl = '$baseUrl/rent/order/close';
  static const String getOrderDetailUrl = '$baseUrl/rent/order/detail';
  static const String ejectBatteryUrl = '$baseUrl/cabinet/ejectByRepair';
  static const String getAllDeviceUrl = '$baseUrl/cabinet/getAllDevice';
  static const String getOrderListUrl = '$baseUrl/order/list';
  static const String rentEjectUrl = '$baseUrl/cabinet/ejectByRent';
  static const String createShopUrl = '$baseUrl/shop/create';
  static const String getShopListUrl = '$baseUrl/shop/getShopList';
  static const String updateShopUrl = '$baseUrl/shop/update';
  static const String deleteShopUrl = '$baseUrl/shop/delete';
  static const String bindDeviceToShopUrl = '$baseUrl/cabinet/bind2shop';
  
  // Callback URL for rent orders (as an example, replace with your actual configured URL)
  static const String rentOrderCallbackUrl = "https://yourdomain.com/api/v1/chargenow/rent-callback"; 
}

