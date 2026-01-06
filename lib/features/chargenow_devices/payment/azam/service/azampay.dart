import 'dart:convert';
import 'package:http/http.dart' as http;

class AzamPay {
  AzamPay({
    required this.appName,
    required this.clientId,
    required this.clientSecret,
    this.xApiKey,
    required this.sandbox,
  });

  final bool sandbox;
  final String appName;
  final String clientId;
  final String clientSecret;
  final String? xApiKey;

    final String sandboxBaseUrl = "https://sandbox.azampay.co.tz";
    final String sandboxAuthyBaseUrl = "https://authenticator-sandbox.azampay.co.tz";

    final String productionBaseUrl = "https://checkout.azampay.co.tz";
    final String productionAuthyBaseUrl = "https://authenticator.azampay.co.tz";


  String get baseUrl {
    return sandbox ? sandboxBaseUrl : productionBaseUrl;
  }

  String get authyBaseUrl {
    return sandbox ? sandboxAuthyBaseUrl : productionAuthyBaseUrl;
  }
  
   Future<String> get accessToken async {
    var authyData = {
      'appName': appName,
      'clientId': clientId,
      'clientSecret': clientSecret,
    };

    var response = await http.post(
      Uri.parse("$authyBaseUrl/AppRegistration/GenerateToken"),
      headers: {"Content-Type": "application/json"},
      body: json.encode(authyData),
    );

    print('Response body (accessToken): ${response.body}');

    var data = json.decode(response.body);
    return data['data']['accessToken'];
  }


  Future mobileCheckout({
    required String merchantMobileNumber,
    required String amount,
    required String currency,
    required String provider,
    required String externalId,
    required String callbackUrl, // Added callback URL parameter
    Map<String, dynamic> additionalProperties = const {},
    void Function(bool success, dynamic responseData)? callback,
  }) async {
    final checkoutData = {
      "accountNumber": merchantMobileNumber,
      "amount": amount,
      "currency": currency,
      "provider": provider,
      "additionalProperties": {
        ...additionalProperties,
      },
      "externalId": externalId,
    };

    try {
      var gotToken = await accessToken;

      var headers = {
        "Authorization": "Bearer $gotToken",
        "Content-Type": "application/json",
      };

      if (!sandbox && xApiKey != null) {
        headers["X-API-Key"] = xApiKey!;
      }

      var response = await http.post(
        Uri.parse("$baseUrl/azampay/mno/checkout"),
        headers: headers,
        body: json.encode(checkoutData),
      );

      print('Response body (mobileCheckout): ${response.body}');

      var responseData = json.decode(response.body);
      callback?.call(responseData['success'], responseData);
      return response;
    } catch (e) {
      print("Error: $e");
      return null;
    }
  }

  Future bankCheckout({
    required String merchantAccountNumber,
    required String merchantMobileNumber,
    String? merchantName,
    required String amount,
    required String currency,
    required String provider,
    required String otp,
    required String referenceId,
      required String callbackUrl, // Added callback URL parameter
    Map<String, dynamic> additionalProperties = const {},
    void Function(bool success, dynamic responseData)? callback,
  }) async {
    final checkoutData = {
      "merchantAccountNumber": merchantAccountNumber,
      "merchantMobileNumber": merchantMobileNumber,
      "amount": amount,
       "merchantName": merchantName,
      "currencyCode": currency,
      "provider": provider,
      "otp": otp,
        "additionalProperties": {
        ...additionalProperties,
      },
      "referenceId": referenceId,
    };

    try {
      var gotToken = await accessToken;

      var headers = {
        "Authorization": "Bearer $gotToken",
        "Content-Type": "application/json",
      };

     if (!sandbox && xApiKey != null) {
        headers["X-API-Key"] = xApiKey!;
      }
      var response = await http.post(
        Uri.parse("$baseUrl/azampay/bank/checkout"),
        headers: headers,
        body: json.encode(checkoutData),
      );

      print('Response body (bankCheckout): ${response.body}');

      var responseData = json.decode(response.body);
       callback?.call(responseData['success'], responseData);
      return response;
    } catch (e) {
      print("Error: $e");
      return null;
    }
  }
}