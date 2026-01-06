class GetOrderDetailParams {
  final String tradeNo;

  GetOrderDetailParams({
    required this.tradeNo,
  });

  Map<String, String> toQueryParameters() {
    return {
      'tradeNo': tradeNo,
    };
  }
}