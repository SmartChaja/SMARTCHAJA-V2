class OrderListParams {
  final int page;
  final int limit;
  final int? dataLevel;
  final String? sTime;
  final String? eTime;

  OrderListParams({
    required this.page,
    required this.limit,
    this.dataLevel,
    this.sTime,
    this.eTime,
  });

  Map<String, String> toQueryParameters() {
    final params = {
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (dataLevel != null) {
      params['dataLevel'] = dataLevel.toString();
    }
    if (sTime != null && sTime!.isNotEmpty) {
      params['sTime'] = sTime!;
    }
    if (eTime != null && eTime!.isNotEmpty) {
      params['eTime'] = eTime!;
    }
    return params;
  }
}