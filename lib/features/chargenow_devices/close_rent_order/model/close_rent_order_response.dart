class CloseRentOrderResponse {
  final String msg;
  final int code; // 0 for success
  final Map<String, dynamic>? data; // Flexible data field as per API response

  CloseRentOrderResponse({
    required this.msg,
    required this.code,
    this.data,
  });

  factory CloseRentOrderResponse.fromJson(Map<String, dynamic> json) {
    return CloseRentOrderResponse(
      msg: json['msg'] ?? 'No message received',
      code: json['code'] ?? -1, // Default to error code if missing
      data: json['data'] != null && json['code'] == 0 // Only include data if code is 0 (success)
          ? json['data'] as Map<String, dynamic>
          : null,
    );
  }
}