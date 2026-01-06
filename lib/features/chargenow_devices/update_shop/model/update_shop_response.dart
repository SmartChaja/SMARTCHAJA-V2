class UpdateShopResponse {
  final String msg;
  final int code; // 0 for success (200 OK), 1 for created (201 Created)
  final Map<String, dynamic>? data; // Flexible data field for additional properties

  UpdateShopResponse({
    required this.msg,
    required this.code,
    this.data,
  });

  factory UpdateShopResponse.fromJson(Map<String, dynamic> json) {
    return UpdateShopResponse(
      msg: json['msg'] ?? 'No message received',
      code: json['code'] ?? -1, // Default to error code if missing
      data: json['data'] != null && (json['code'] == 0 || json['code'] == 1) // Include data for 200 or 201
          ? json['data'] as Map<String, dynamic>
          : null,
    );
  }
}