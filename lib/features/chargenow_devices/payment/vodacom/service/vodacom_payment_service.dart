import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import 'encryption_service.dart';
import 'vodacom_secure_config.dart';
import '../model/vodacom_payment_model.dart';
import '../utils/msisdn_formatter.dart';

/// Configuration for Vodacom API
class VodacomConfig {
  static String getPublicKey(bool isSandbox) {
    try {
      final secureConfig = VodacomSecureConfig();
      return isSandbox
          ? secureConfig.sandboxRsaPublicKey
          : secureConfig.productionRsaPublicKey;
    } catch (e) {
      // Fallback to default RSA key if secure config not initialized
      // This is the official Vodacom M-Pesa public key
      return "MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEArv9yxA69XQKBo24BaF/D+fvlqmGdYjqLQ5WtNBb5tquqGvAvG3WMFETVUSow/LizQalxj2ElMVrUmzu5mGGkxK08bWEXF7a1DEvtVJs6nppIlFJc2SnrU14AOrIrB28ogm58JjAl5BOQawOXD5dfSk7MaAA82pVHoIqEu0FxA8BOKU+RGTihRU+ptw1j4bsAJYiPbSX6i71gfPvwHPYamM0bfI4CmlsUUR3KvCG24rB6FNPcRBhM3jDuv8ae2kC33w9hEq8qNB55uw51vK7hyXoAa+U7IqP1y6nBdlN25gkxEA8yrsl1678cspeXr+3ciRyqoRgj9RD/ONbJhhxFvt1cLBh+qwK2eqISfBb06eRnNeC71oBokDm3zyCnkOtMDGl7IvnMfZfEPFCfg5QgJVk1msPpRvQxmEsrX9MQRyFVzgy2CWNIb7c+jPapyrNwoUbANlN8adU1m6yOuoX7F49x+OjiG2se0EJ6nafeKUXw/+hiJZvELUYgzKUtMAZVTNZfT8jjb58j8GVtuS+6TM2AutbejaCV84ZK58E2CRJqhmjQibEUO6KPdD7oTlEkFy52Y1uOOBXgYpqMzufNPmfdqqqSM4dU70PO8ogyKGiLAIxCetMjjm6FCMEA3Kc8K0Ig7/XtFm9By6VxTJK1Mg36TlHaZKP6VzVLXMtesJECAwEAAQ==";
    }
  }

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
  final String serviceProviderCode;
  final bool sandbox;
  final String origin;

  VodacomPaymentService({
    required this.apiKey,
    required this.serviceProviderCode,
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
        VodacomConfig.getPublicKey(sandbox),
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
      dio.options.connectTimeout = const Duration(seconds: 60);
      dio.options.receiveTimeout = const Duration(seconds: 90);
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
      // Validate and format MSISDN (phone number)
      String formattedMsisdn;
      try {
        formattedMsisdn = MsisdnFormatter.formatToMsisdn(customerMsisdn);
        print(
            '[VodacomAPI] ✓ MSISDN formatted: $customerMsisdn → $formattedMsisdn');
      } catch (e) {
        print('[VodacomAPI] ✗ MSISDN format error: $e');
        print('[VodacomAPI] TROUBLESHOOTING:');
        print(
            '[VodacomAPI] - MSISDN must be 12-14 digits (country code + phone)');
        print(
            '[VodacomAPI] - Examples: "0712345678" → "255712345678" (Tanzania)');
        print('[VodacomAPI] - Or: "+255712345678" → "255712345678"');
        print(
            '[VodacomAPI] - Error: ${MsisdnFormatter.getErrorMessage(customerMsisdn)}');
        return VodacomPaymentResult.error(
          'Invalid phone number format: ${MsisdnFormatter.getErrorMessage(customerMsisdn)}',
        );
      }

      // Validate all required parameters per API docs
      print(
          '[VodacomAPI] Validating parameters against Vodacom API requirements...');

      // Validate Amount: ^\d*\.?\d+$
      if (amount.isEmpty || !RegExp(r'^\d*\.?\d+$').hasMatch(amount)) {
        print('[VodacomAPI] ✗ Invalid Amount: "$amount"');
        print('[VodacomAPI] - Amount must be numeric (e.g., 10 or 10.50)');
        return VodacomPaymentResult.error(
            'Invalid amount format. Must be numeric (e.g., 5000 or 5000.50)');
      }

      // Validate Service Provider Code: ^([0-9A-Za-z]{4,12})$
      if (serviceProviderCode == null ||
          serviceProviderCode.isEmpty ||
          !RegExp(r'^([0-9A-Za-z]{4,12})$').hasMatch(serviceProviderCode)) {
        print(
            '[VodacomAPI] ✗ Invalid ServiceProviderCode: "$serviceProviderCode"');
        print(
            '[VodacomAPI] - Must be 4-12 alphanumeric characters (e.g., ORG001)');
        return VodacomPaymentResult.error(
            'Invalid service provider code. Must be 4-12 alphanumeric characters.');
      }

      // Validate Transaction Reference: ^[0-9a-zA-Z \w+]{1,20}$
      if (transactionReference.isEmpty ||
          transactionReference.length > 20 ||
          !RegExp(r'^[0-9a-zA-Z \w+]{1,20}$').hasMatch(transactionReference)) {
        print(
            '[VodacomAPI] ✗ Invalid TransactionReference: "$transactionReference"');
        print(
            '[VodacomAPI] - Must be 1-20 characters (alphanumeric, space, or underscore)');
        return VodacomPaymentResult.error(
            'Invalid transaction reference. Must be 1-20 characters.');
      }

      // Validate Purchased Items Description: ^[0-0a-zA-Z \w+]{1,256}$
      if (purchasedItemsDesc.isEmpty ||
          purchasedItemsDesc.length > 256 ||
          !RegExp(r'^[0-9a-zA-Z \w+]{1,256}$').hasMatch(purchasedItemsDesc)) {
        print(
            '[VodacomAPI] ✗ Invalid PurchasedItemsDesc: "$purchasedItemsDesc"');
        print(
            '[VodacomAPI] - Must be 1-256 characters (alphanumeric, space, or underscore)');
        return VodacomPaymentResult.error(
            'Invalid purchased items description. Must be 1-256 characters.');
      }

      // Validate Country is set
      if (VodacomConfig.country.isEmpty) {
        print('[VodacomAPI] ✗ Country not configured');
        return VodacomPaymentResult.error('Country configuration missing.');
      }

      // Validate Currency is set
      if (VodacomConfig.currency.isEmpty) {
        print('[VodacomAPI] ✗ Currency not configured');
        return VodacomPaymentResult.error('Currency configuration missing.');
      }

      print('[VodacomAPI] ✓ All parameters validated successfully');

      // Encrypt the session key
      final encryptedSessionKey = EncryptionService.encryptWithPublicKey(
        VodacomConfig.getPublicKey(sandbox),
        sessionKey,
      );

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $encryptedSessionKey',
        'Origin': origin,
      };

      final body = {
        'input_Amount': amount,
        'input_Country': VodacomConfig.country,
        'input_Currency': VodacomConfig.currency,
        // Use formatted MSISDN (12-14 digits, international format)
        'input_CustomerMSISDN': formattedMsisdn,
        'input_ServiceProviderCode': serviceProviderCode,
        // Use test value for sandbox, UUID (without dashes) for production
        // API regex: ^[0-9a-zA-Z \w+]{1,40}$ (no dashes allowed)
        'input_ThirdPartyConversationID':
            sandbox ? 'test1234567891' : const Uuid().v4().replaceAll('-', ''),
        'input_TransactionReference': transactionReference,
        'input_PurchasedItemsDesc': purchasedItemsDesc,
      };

      final baseUrl =
          '$_baseUrl/${VodacomConfig.market}/c2bPayment/singleStage/';

      // Debug: Print request details
      print('[VodacomAPI] C2B Payment Request URL: $baseUrl');
      print('[VodacomAPI] C2B Payment Headers:');
      headers.forEach((k, v) =>
          print('  $k: ${k == 'Authorization' ? '<encrypted_key>' : v}'));
      print('[VodacomAPI] C2B Payment Request Body: ${jsonEncode(body)}');

      // Initialize Dio with timeout and disable status code validation
      final dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 60);
      dio.options.receiveTimeout = const Duration(seconds: 90);
      dio.options.validateStatus =
          (_) => true; // Don't throw on any status code

      final response = await dio.post(
        baseUrl,
        data: jsonEncode(body),
        options: Options(headers: headers),
      );

      print('[VodacomAPI] C2B Payment Response Status: ${response.statusCode}');
      print('[VodacomAPI] C2B Payment Response Body: ${response.data}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = response.data is String
            ? jsonDecode(response.data) as Map<String, dynamic>
            : response.data as Map<String, dynamic>;
        final result = VodacomPaymentResult.fromResponse(responseData);
        print('[VodacomAPI] ✓ C2B Payment Success: $responseData');
        return result.copyWith(
            amount: amount, currency: VodacomConfig.currency);
      } else {
        // Try to extract as much error info as possible
        Map<String, dynamic>? responseData;
        String errorDesc = 'Payment failed';
        try {
          if (response.data is String) {
            responseData = jsonDecode(response.data) as Map<String, dynamic>;
          } else if (response.data is Map) {
            responseData = response.data as Map<String, dynamic>;
          }
          if (responseData != null) {
            errorDesc = responseData['output_ResponseDesc'] ??
                responseData['error'] ??
                responseData.toString();
            print('[VodacomAPI] ✗ C2B Payment Error: $errorDesc');
            print('[VodacomAPI] ✗ Full Error Response: $responseData');
          } else {
            print(
                '[VodacomAPI] ✗ C2B Payment Error: Unable to parse error response');
          }
        } catch (e) {
          print(
              '[VodacomAPI] ✗ C2B Payment Error: Exception parsing error response: $e');
        }
        return VodacomPaymentResult.error(errorDesc);
      }
    } catch (e, stack) {
      print('[VodacomAPI] ✗ C2B payment exception: $e');
      print('[VodacomAPI] ✗ Stack trace: $stack');
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
        VodacomConfig.getPublicKey(sandbox),
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
      dio.options.connectTimeout = const Duration(seconds: 60);
      dio.options.receiveTimeout = const Duration(seconds: 90);
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
