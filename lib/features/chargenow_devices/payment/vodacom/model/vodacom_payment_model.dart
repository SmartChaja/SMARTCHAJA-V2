/// Represents a Vodacom payment result
class VodacomPaymentResult {
  final bool isSuccess;
  final String message;
  final String? transactionId;
  final String? conversationId;
  final String? thirdPartyConversationId;
  final String? amount;
  final String? currency;
  final String? transactionDocId;
  final String? responseCode;
  final String? responseDesc;

  VodacomPaymentResult({
    required this.isSuccess,
    required this.message,
    this.transactionId,
    this.conversationId,
    this.thirdPartyConversationId,
    this.amount,
    this.currency,
    this.transactionDocId,
    this.responseCode,
    this.responseDesc,
  });

  /// Factory constructor to create from API response
  factory VodacomPaymentResult.fromResponse(Map<String, dynamic> response) {
    final isSuccess = response['output_ResponseCode'] == 'INS-0';
    return VodacomPaymentResult(
      isSuccess: isSuccess,
      message: response['output_ResponseDesc'] ?? 'Transaction processed',
      transactionId: response['output_TransactionID'],
      conversationId: response['output_ConversationID'],
      thirdPartyConversationId: response['output_ThirdPartyConversationID'],
      responseCode: response['output_ResponseCode'],
      responseDesc: response['output_ResponseDesc'],
    );
  }

  /// Factory constructor for error cases
  factory VodacomPaymentResult.error(String message) {
    return VodacomPaymentResult(
      isSuccess: false,
      message: message,
    );
  }
}

/// Represents a Vodacom session key response
class VodacomSessionResponse {
  final bool isSuccess;
  final String? sessionId;
  final String? responseCode;
  final String? responseDesc;

  VodacomSessionResponse({
    required this.isSuccess,
    this.sessionId,
    this.responseCode,
    this.responseDesc,
  });

  /// Factory constructor from API response
  factory VodacomSessionResponse.fromResponse(Map<String, dynamic> response) {
    final isSuccess = response['output_ResponseCode'] == 'INS-0';
    return VodacomSessionResponse(
      isSuccess: isSuccess,
      sessionId: response['output_SessionID'],
      responseCode: response['output_ResponseCode'],
      responseDesc: response['output_ResponseDesc'],
    );
  }

  /// Factory constructor for error cases
  factory VodacomSessionResponse.error(String message) {
    return VodacomSessionResponse(
      isSuccess: false,
      responseDesc: message,
    );
  }
}
