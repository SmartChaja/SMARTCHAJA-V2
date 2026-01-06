class EjectBatteryResponse {
  final String msg;
  final int code; // 0 for success
  final dynamic data; // Changed to dynamic to handle any type (bool, Map, etc.)

  EjectBatteryResponse({
    required this.msg,
    required this.code,
    this.data,
  });

  factory EjectBatteryResponse.fromJson(Map<String, dynamic> json) {
    return EjectBatteryResponse(
      msg: json['msg'] ?? 'No message received',
      code: json['code'] ?? -1, // Default to error code if missing
      data: json['data'], // Accept any data type (bool, Map, null, etc.)
    );
  }
}