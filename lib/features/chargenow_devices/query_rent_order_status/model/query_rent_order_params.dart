class QueryRentOrderParams {
  final String tradeNo;

  QueryRentOrderParams({
    required this.tradeNo,
  });

  Map<String, String> toQueryParameters() {
    return {
      'tradeNo': tradeNo,
    };
  }
}