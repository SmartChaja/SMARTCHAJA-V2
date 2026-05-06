/// Represents the result of a Vodacom payment operation
class VodacomPaymentOperationResult {
  final bool isSuccess;
  final bool isProvisional;
  final String message;
  final String? transactionId;
  final String? conversationId;
  final String? thirdPartyConversationId;
  final String? amount;
  final String? currency;
  final String? provider;
  final String? transactionDocId;
  final String? responseCode;
  final String? responseDesc;

  VodacomPaymentOperationResult({
    required this.isSuccess,
    this.isProvisional = false,
    required this.message,
    this.transactionId,
    this.conversationId,
    this.thirdPartyConversationId,
    this.amount,
    this.currency,
    this.provider,
    this.transactionDocId,
    this.responseCode,
    this.responseDesc,
  });

  /// Create from Vodacom API response
  factory VodacomPaymentOperationResult.fromApiResponse(
    Map<String, dynamic> response, {
    String? amount,
    String? currency,
    String? provider,
    String? transactionDocId,
  }) {
    final isSuccess = response['output_ResponseCode'] == 'INS-0';
    return VodacomPaymentOperationResult(
      isSuccess: isSuccess,
      isProvisional: false,
      message: response['output_ResponseDesc'] ?? 'Transaction processed',
      transactionId: response['output_TransactionID'],
      conversationId: response['output_ConversationID'],
      thirdPartyConversationId: response['output_ThirdPartyConversationID'],
      amount: amount,
      currency: currency,
      provider: provider,
      transactionDocId: transactionDocId,
    );
  }

  /// Create error result
  factory VodacomPaymentOperationResult.error(String message) {
    return VodacomPaymentOperationResult(
      isSuccess: false,
      isProvisional: false,
      message: message,
    );
  }
}
