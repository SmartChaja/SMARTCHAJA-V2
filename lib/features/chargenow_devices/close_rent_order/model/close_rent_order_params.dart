class CloseRentOrderParams {
  final String tradeNo;

  CloseRentOrderParams({
    required this.tradeNo,
  });

  Map<String, String> toQueryParameters() {
    return {
      'tradeNo': tradeNo,
    };
  }
}