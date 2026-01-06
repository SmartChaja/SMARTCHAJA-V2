// smart_chaja/features/chargenow_devices/get_order_detail/model/get_order_detail_response.dart

class OrderDetailData {
  final String cabinetId;
  final String orderId;
  final String batteryId;
  final int dailyMaxPrice; // Potential double from API
  final int freeMinutes;   // Potential double from API
  final int orderAmount;   // Potential double from API
  final String borrowTime;
  final double price; // This is correctly a double
  final String currency;
  final String deviceType;
  final String priceMinute;
  final int borrowSlot;    // Potential double from API
  final String? returnTime;
  final int borrowStatus;  // Potential double from API
  final int deposit;       // Potential double from API
  final String orderType; // Added based on your log preview: "orderType":"OpenAccount"

  OrderDetailData({
    required this.cabinetId,
    required this.orderId,
    required this.batteryId,
    required this.dailyMaxPrice,
    required this.freeMinutes,
    required this.orderAmount,
    required this.borrowTime,
    required this.price,
    required this.currency,
    required this.deviceType,
    required this.priceMinute,
    required this.borrowSlot,
    this.returnTime,
    required this.borrowStatus,
    required this.deposit,
    required this.orderType, // Include in constructor
  });

  factory OrderDetailData.fromJson(Map<String, dynamic> json) {
    return OrderDetailData(
      cabinetId: json['cabinetId'] ?? '',
      orderId: json['orderId'] ?? '',
      batteryId: json['batteryId'] ?? '',
      // FIX: Safely convert any numeric type to int for these fields
      dailyMaxPrice: (json['dailyMaxPrice'] as num?)?.toInt() ?? 0,
      freeMinutes: (json['freeMinutes'] as num?)?.toInt() ?? 0,
      orderAmount: (json['orderAmount'] as num?)?.toInt() ?? 0,
      borrowTime: json['borrowTime'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0, // Already correct for double
      currency: json['currency'] ?? '',
      deviceType: json['deviceType'] ?? '',
      priceMinute: json['priceMinute'] ?? '',
      borrowSlot: (json['borrowSlot'] as num?)?.toInt() ?? 0,
      returnTime: json['returnTime'],
      borrowStatus: (json['borrowStatus'] as num?)?.toInt() ?? 0,
      deposit: (json['deposit'] as num?)?.toInt() ?? 0,
      orderType: json['orderType'] ?? '', // Parsing for the new field
    );
  }
}

class GetOrderDetailResponse {
  final String msg;
  final int code; // 0 for success
  final OrderDetailData? data;

  GetOrderDetailResponse({
    required this.msg,
    required this.code,
    this.data,
  });

  factory GetOrderDetailResponse.fromJson(Map<String, dynamic> json) {
    return GetOrderDetailResponse(
      msg: json['msg'] ?? 'No message received',
      // FIX: Also make the 'code' parsing robust, just in case
      code: (json['code'] as num?)?.toInt() ?? -1,
      // Only parse data if code is 0 (success) after robust parsing
      data: json['data'] != null && (json['code'] as num?)?.toInt() == 0
          ? OrderDetailData.fromJson(json['data'])
          : null,
    );
  }
}