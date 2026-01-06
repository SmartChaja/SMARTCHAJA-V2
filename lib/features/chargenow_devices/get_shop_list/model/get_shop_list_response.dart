class GetShopListResponse {
  final String msg;
  final int code; // 0 for success (200 OK)
  final List<Map<String, dynamic>>? data; // Flexible list of shops

  GetShopListResponse({
    required this.msg,
    required this.code,
    this.data,
  });

  factory GetShopListResponse.fromJson(Map<String, dynamic> json) {
    return GetShopListResponse(
      msg: json['msg'] ?? 'No message received',
      code: json['code'] ?? -1, // Default to error code if missing
      data: json['data'] != null && json['code'] == 0 // Include data only for success
          ? (json['data'] as List<dynamic>).map((item) => Map<String, dynamic>.from(item)).toList()
          : null,
    );
  }
}