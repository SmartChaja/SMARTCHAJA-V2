class PaymentResult {
  final bool isSuccess;
  final String message;
  final String? transactionId;
  final String? referenceId;
  final String? amount;
  final String? provider;
  final String? transactionDocId;

  PaymentResult({
    required this.isSuccess,
    required this.message,
    this.transactionId,
    this.referenceId,
    this.amount,
    this.provider,
    this.transactionDocId,
  });
}

