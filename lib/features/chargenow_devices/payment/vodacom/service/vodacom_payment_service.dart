import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import 'encryption_service.dart';
import '../model/vodacom_payment_model.dart';

/// Configuration for Vodacom API
class VodacomConfig {
  static const String publicKey =
      "MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEArv9yxA69XQKBo24BaF/D+fvlqmGdYjqLQ5WtNBb5tquqGvAvG3WMFETVUSow/LizQalxj2ElMVrUmzu5mGGkxK08bWEXF7a1DEvtVJs6nppIlFJc2SnrU14AOrIrB28ogm58JjAl5BOQawOXD5dfSk7MaAA82pVHoIqEu0FxA8BOKU+RGTihRU+ptw1j4bsAJYiPbSX6i71gfPvwHPYamM0bfI4CmlsUUR3KvCG24rB6FNPcRBhM3jDuv8ae2kC33w9hEq8qNB55uw51vK7hyXoAa+U7IqP1y6nBdlN25gkxEA8yrsl1678cspeXr+3ciRyqoRgj9RD/ONbJhhxFvt1cLBh+qwK2eqISfBb06eRnNeC71oBokDm3zyCnkOtMDGl7IvnMfZfEPFCfg5QgJVk1msPpRvQxmEsrX9MQRyFVzgy2CWNIb7c+jPapyrNwoUbANlN8adU1m6yOuoX7F49x+OjiG2se0EJ6nafeKUXw/+hiJZvELUYgzKUtMAZVTNZfT8jjb58j8GVtuS+6TM2AutbejaCV84ZK58E2CRJqhmjQibEUO6KPdD7oTlEkFy52Y1uOOBXgYpqMzufNPmfdqqqSM4dU70PO8ogyKGiLAIxCetMjjm6FCMEA3Kc8K0Ig7/XtFm9By6VxTJK1Mg36TlHaZKP6VzVLXMtesJECAwEAAQ==";

  static const String sandboxHost = "openapi.m-pesa.com";
  static const String sandboxPath = "/sandbox/ipg/v2";
  static const String productionPath = "/openapi/ipg/v2";

  // Market configurations - Vodacom Tanzania
  static const String market = "vodacomTZN"; // Vodacom Tanzania
  static const String country = "TZN";
  static const String currency = "TZS"; // Tanzanian Shilling
  static const int port = 443;
}

/// Vodacom Payment Service for M-Pesa OpenAPI integration
class VodacomPaymentService {
  final String apiKey;
  final bool sandbox;
  final String origin;

  VodacomPaymentService({
    required this.apiKey,
    this.sandbox = true,
    this.origin = '*',
  });

  String get _baseUrl => sandbox
      ? "https://${VodacomConfig.sandboxHost}${VodacomConfig.sandboxPath}"
      : "https://${VodacomConfig.sandboxHost}${VodacomConfig.productionPath}";

  /// Generates a session key by calling the getSession endpoint
  /// Must be called before making payment requests
  /// Per API docs: Session ID takes up to 30 seconds to become 'live' in the system
  Future<VodacomSessionResponse> generateSessionKey() async {
    try {
      print('[VodacomAPI] ════════════════════════════════════════');
      print('[VodacomAPI] Generating Session Key');
      print('[VodacomAPI] API Key: $apiKey');
      print('[VodacomAPI] Market: ${VodacomConfig.market}');
      print('[VodacomAPI] Origin: $origin');

      // Encrypt the API key with RSA - required for authentication
      final encryptedApiKey = EncryptionService.encryptWithPublicKey(
        VodacomConfig.publicKey,
        apiKey,
      );

      print('[VodacomAPI] Encrypted API Key length: ${encryptedApiKey.length}');
      final displayLength =
          encryptedApiKey.length > 50 ? 50 : encryptedApiKey.length;
      print(
          '[VodacomAPI] Encrypted key (first $displayLength chars): ${encryptedApiKey.substring(0, displayLength)}...');

      final baseUrl = '$_baseUrl/${VodacomConfig.market}/getSession/';
      final url = Uri.parse(baseUrl);

      // Build headers - Origin header MUST match M-Pesa application configuration
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $encryptedApiKey',
        // CRITICAL: Origin header must match the value(s) defined in your M-Pesa Application
        // If empty, server may reject request. Check M-Pesa dashboard for allowed origins.
        if (origin.isNotEmpty) 'Origin': origin,
      };

      print('[VodacomAPI] Request URL: $baseUrl');
      print(
          '[VodacomAPI] Headers: Content-Type=application/json, Authorization=Bearer <encrypted_key>${origin.isNotEmpty ? ', Origin=$origin' : ', (no Origin header)'}');

      // Initialize Dio with timeout and disable status code validation
      final dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 30);
      dio.options.receiveTimeout = const Duration(seconds: 30);
      dio.options.validateStatus =
          (_) => true; // Don't throw on any status code

      final response = await dio.get(
        baseUrl,
        options: Options(headers: headers),
      );

      print('[VodacomAPI] Response Status: ${response.statusCode}');
      print('[VodacomAPI] Response Body: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data is String
            ? jsonDecode(response.data) as Map<String, dynamic>
            : response.data as Map<String, dynamic>;
        final sessionResponse =
            VodacomSessionResponse.fromResponse(responseData);

        if (sessionResponse.isSuccess) {
          print(
              '[VodacomAPI] ✓ Session ID obtained: ${sessionResponse.sessionId}');
          print(
              '[VodacomAPI] ⚠️  IMPORTANT: Session ID takes up to 30 seconds to become live in M-Pesa system');
        }

        return sessionResponse;
      } else {
        // Return the actual server response for debugging
        String errorBody = response.data.toString();
        try {
          if (response.data is String) {
            final jsonError = jsonDecode(response.data) as Map<String, dynamic>;
            errorBody = jsonError.toString();
          } else if (response.data is Map) {
            errorBody = response.data.toString();
          }
        } catch (e) {
          // Response is not JSON, keep raw body
        }

        final errorMsg =
            'Failed to generate session key (${response.statusCode}): $errorBody';
        print('[VodacomAPI] ✗ $errorMsg');
        print('[VodacomAPI] TROUBLESHOOTING TIPS:');
        print(
            '[VodacomAPI] 1. If "Bad API Key" (400): Check Origin header matches M-Pesa app configuration');
        print(
            '[VodacomAPI] 2. Verify API key is valid and associated with correct application');
        print(
            '[VodacomAPI] 3. Ensure application status is "Development" or "Production" (not unapproved)');
        print('[VodacomAPI] ════════════════════════════════════════');

        return VodacomSessionResponse.error(errorMsg);
      }
    } catch (e) {
      final errorMsg = 'Session key generation error: $e';
      print('[VodacomAPI] ✗ $errorMsg');
      return VodacomSessionResponse.error(errorMsg);
    }
  }

  /// Performs a C2B single stage payment
  /// Requires a valid session key
  Future<VodacomPaymentResult> performC2BPayment({
    required String sessionKey,
    required String amount,
    required String customerMsisdn,
    String? serviceProviderCode,
    required String transactionReference,
    required String purchasedItemsDesc,
  }) async {
    try {
      // Validate inputs
      if (amount.isEmpty || customerMsisdn.isEmpty) {
        return VodacomPaymentResult.error('Invalid amount or customer MSISDN');
      }

      // Encrypt the session key
      final encryptedSessionKey = EncryptionService.encryptWithPublicKey(
        VodacomConfig.publicKey,
        sessionKey,
      );

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $encryptedSessionKey',
        'Origin': origin,
      };

      final thirdPartyConversationId = const Uuid().v4();

      final body = {
        'input_Amount': amount,
        'input_Country': VodacomConfig.country,
        'input_Currency': VodacomConfig.currency,
        'input_CustomerMSISDN': customerMsisdn,
        // Always use '000000' for sandbox testing
        'input_ServiceProviderCode':
            sandbox ? '000000' : (serviceProviderCode ?? ''),
        'input_ThirdPartyConversationID': thirdPartyConversationId,
        'input_TransactionReference': transactionReference,
        'input_PurchasedItemsDesc': purchasedItemsDesc,
      };

      final baseUrl =
          '$_baseUrl/${VodacomConfig.market}/c2bPayment/singleStage/';

      // Initialize Dio with timeout and disable status code validation
      final dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 30);
      dio.options.receiveTimeout = const Duration(seconds: 30);
      dio.options.validateStatus =
          (_) => true; // Don't throw on any status code

      final response = await dio.post(
        baseUrl,
        data: jsonEncode(body),
        options: Options(headers: headers),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = response.data is String
            ? jsonDecode(response.data) as Map<String, dynamic>
            : response.data as Map<String, dynamic>;
        final result = VodacomPaymentResult.fromResponse(responseData);
        return result.copyWith(
            amount: amount, currency: VodacomConfig.currency);
      } else {
        final responseData = response.data is String
            ? jsonDecode(response.data) as Map<String, dynamic>
            : response.data as Map<String, dynamic>;
        final errorDesc =
            responseData['output_ResponseDesc'] ?? 'Payment failed';
        return VodacomPaymentResult.error(errorDesc);
      }
    } catch (e) {
      return VodacomPaymentResult.error('C2B payment error: $e');
    }
  }

  /// Queries the status of a transaction
  Future<VodacomPaymentResult> queryTransactionStatus({
    required String sessionKey,
    required String conversationId,
  }) async {
    try {
      final encryptedSessionKey = EncryptionService.encryptWithPublicKey(
        VodacomConfig.publicKey,
        sessionKey,
      );

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $encryptedSessionKey',
        'Origin': origin,
      };

      final body = {
        'input_ConversationID': conversationId,
      };

      final baseUrl =
          '$_baseUrl/${VodacomConfig.market}/queryTransactionStatus/';

      // Initialize Dio with timeout and disable status code validation
      final dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 30);
      dio.options.receiveTimeout = const Duration(seconds: 30);
      dio.options.validateStatus =
          (_) => true; // Don't throw on any status code

      final response = await dio.post(
        baseUrl,
        data: jsonEncode(body),
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final responseData = response.data is String
            ? jsonDecode(response.data) as Map<String, dynamic>
            : response.data as Map<String, dynamic>;
        return VodacomPaymentResult.fromResponse(responseData);
      } else {
        return VodacomPaymentResult.error('Failed to query transaction status');
      }
    } catch (e) {
      return VodacomPaymentResult.error('Query error: $e');
    }
  }
}

/// Extension to add copyWith method to VodacomPaymentResult
extension VodacomPaymentResultExt on VodacomPaymentResult {
  VodacomPaymentResult copyWith({
    bool? isSuccess,
    String? message,
    String? transactionId,
    String? conversationId,
    String? thirdPartyConversationId,
    String? amount,
    String? currency,
    String? transactionDocId,
    String? responseCode,
    String? responseDesc,
  }) {
    return VodacomPaymentResult(
      isSuccess: isSuccess ?? this.isSuccess,
      message: message ?? this.message,
      transactionId: transactionId ?? this.transactionId,
      conversationId: conversationId ?? this.conversationId,
      thirdPartyConversationId:
          thirdPartyConversationId ?? this.thirdPartyConversationId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      transactionDocId: transactionDocId ?? this.transactionDocId,
      responseCode: responseCode ?? this.responseCode,
      responseDesc: responseDesc ?? this.responseDesc,
    );
  }
}
