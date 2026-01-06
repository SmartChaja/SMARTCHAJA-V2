class OrderListPage {
  final int current;
  final int total;
  final int pages;
  final int size;
  final Map<String, dynamic> sumValues;
  final List<Map<String, dynamic>> records;
  final bool searchCount;

  OrderListPage({
    required this.current,
    required this.total,
    required this.pages,
    required this.size,
    required this.sumValues,
    required this.records,
    required this.searchCount,
  });

  factory OrderListPage.fromJson(Map<String, dynamic> json) {
    return OrderListPage(
      current: json['current'] ?? 0,
      total: json['total'] ?? 0,
      pages: json['pages'] ?? 0,
      size: json['size'] ?? 0,
      sumValues: json['sumValues'] != null ? Map<String, dynamic>.from(json['sumValues']) : {},
      records: json['records'] != null
          ? (json['records'] as List<dynamic>).map((item) => Map<String, dynamic>.from(item)).toList()
          : [],
      searchCount: json['searchCount'] ?? true,
    );
  }
}

class OrderListResponse {
  final String msg;
  final int code; // 0 for success
  final OrderListPage? page;

  OrderListResponse({
    required this.msg,
    required this.code,
    this.page,
  });

  factory OrderListResponse.fromJson(Map<String, dynamic> json) {
    return OrderListResponse(
      msg: json['msg'] ?? 'No message received',
      code: json['code'] ?? -1, // Default to error code if missing
      page: json['page'] != null && json['code'] == 0 // Only parse page if code is 0 (success)
          ? OrderListPage.fromJson(json['page'])
          : null,
    );
  }
}