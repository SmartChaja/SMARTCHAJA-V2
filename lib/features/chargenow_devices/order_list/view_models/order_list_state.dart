enum OrderListStatus { initial, loading, success, error, loadingMore }

class OrderListState {
  final OrderListStatus status;
  final List<Map<String, dynamic>> records; // Accumulated records
  final int currentPage;
  final int totalPages;
  final int pageSize;
  final String? errorMsg;
  final dynamic validationDetails;

  OrderListState({
    required this.status,
    this.records = const [],
    this.currentPage = 1,
    this.totalPages = 0,
    this.pageSize = 10,
    this.errorMsg,
    this.validationDetails,
  });

  OrderListState copyWith({
    OrderListStatus? status,
    List<Map<String, dynamic>>? records,
    int? currentPage,
    int? totalPages,
    int? pageSize,
    String? errorMsg,
    dynamic validationDetails,
    bool clearAll = false,
  }) {
    return OrderListState(
      status: clearAll ? OrderListStatus.initial : status ?? this.status,
      records: clearAll ? [] : records ?? this.records,
      currentPage: clearAll ? 1 : currentPage ?? this.currentPage,
      totalPages: clearAll ? 0 : totalPages ?? this.totalPages,
      pageSize: clearAll ? 10 : pageSize ?? this.pageSize,
      errorMsg: clearAll ? null : errorMsg ?? this.errorMsg,
      validationDetails: clearAll ? null : validationDetails ?? this.validationDetails,
    );
  }
}