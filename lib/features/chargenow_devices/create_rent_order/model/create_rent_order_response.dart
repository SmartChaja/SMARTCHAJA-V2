  class RentOrderData {
    final String tradeNo;

    RentOrderData({required this.tradeNo});

    factory RentOrderData.fromJson(Map<String, dynamic> json) {
      return RentOrderData(
        tradeNo: json['tradeNo'] ?? 'UNKNOWN_TRADENO_${DateTime.now().millisecondsSinceEpoch}',
      );
    }
  }

  class CreateRentOrderResponse {
    final String msg;
    final int code; // 0 for success
    final RentOrderData? data;

    CreateRentOrderResponse({
      required this.msg,
      required this.code,
      this.data,
    });

    factory CreateRentOrderResponse.fromJson(Map<String, dynamic> json) {
      return CreateRentOrderResponse(
        msg: json['msg'] ?? 'No message received',
        code: json['code'] ?? -1, // Default to error code if missing
        data: json['data'] != null && json['code'] == 0 // Only parse data if code is 0 (success)
            ? RentOrderData.fromJson(json['data'])
            : null,
      );
    }
  }
  