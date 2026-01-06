
class RentEjectResponse {
  final String msg;
  final int code; // 0 for success
  final dynamic data; // Changed from Map<String, dynamic>? to dynamic

  RentEjectResponse({
    required this.msg,
    required this.code,
    this.data,
  });

  factory RentEjectResponse.fromJson(Map<String, dynamic> json) {
    return RentEjectResponse(
      msg: json['msg'] ?? 'No message received',
      code: json['code'] ?? -1, // Default to error code if missing
      // No explicit type cast needed for 'data' anymore,
      // just assign whatever value is present in the JSON.
      // The condition `json['data'] != null && json['code'] == 0` is removed
      // to simply assign the 'data' field directly, regardless of its type or success code.
      data: json['data'],
    );
  }
}

