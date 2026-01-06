class QueryRentOrderResponse {
  final String msg;
  final int code; // 0 for success
  final dynamic data; // Changed to dynamic to handle null or other types

  QueryRentOrderResponse({
    required this.msg,
    required this.code,
    this.data,
  });

  factory QueryRentOrderResponse.fromJson(Map<String, dynamic> json) {
    return QueryRentOrderResponse(
      msg: json['msg'] ?? 'No message received',
      code: json['code'] ?? -1, // Default to error code if missing
      data: json['data'], // Accept any data type (null, Map, etc.)
    );
  }
}