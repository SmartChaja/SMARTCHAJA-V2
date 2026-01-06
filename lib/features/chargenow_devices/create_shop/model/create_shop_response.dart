class CreateShopResponse {
  final String msg;
  final int code; // 0 for success (200 OK), 1 for created (201 Created)
  final Map<String, dynamic>? data; // Flexible data field for additional properties

  CreateShopResponse({
    required this.msg,
    required this.code,
    this.data,
  });

  factory CreateShopResponse.fromJson(Map<String, dynamic> json) {
    return CreateShopResponse(
      msg: json['msg'] ?? 'No message received',
      code: json['code'] ?? -1, // Default to error code if missing
      data: json['data'] != null && (json['code'] == 0 || json['code'] == 1) // Include data for 200 or 201
          ? json['data'] as Map<String, dynamic>
          : null,
    );
  }
}