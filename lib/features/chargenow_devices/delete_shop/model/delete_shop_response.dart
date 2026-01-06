class DeleteShopResponse {
  final String msg;
  final int code; // 0 for success (200 OK or 204 No Content)
  final Map<String, dynamic>? data; // Flexible data field for additional properties (200 OK)

  DeleteShopResponse({
    required this.msg,
    required this.code,
    this.data,
  });

  factory DeleteShopResponse.fromJson(Map<String, dynamic> json) {
    return DeleteShopResponse(
      msg: json['msg'] ?? 'No message received',
      code: json['code'] ?? -1, // Default to error code if missing
      data: json['data'] != null && json['code'] == 0 // Include data only for 200 OK
          ? json['data'] as Map<String, dynamic>
          : null,
    );
  }
}