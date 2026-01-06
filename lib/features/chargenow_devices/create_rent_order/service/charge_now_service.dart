// File: lib/features/chargenow_rent/service/charge_now_rent_service.dart

import 'dart:convert';
import 'dart:io'; // For SocketException
import 'package:http/http.dart' as http;
import 'package:smart_chaja/app_constants/charge_now_api_config.dart';
import 'package:smart_chaja/features/chargenow_devices/create_rent_order/model/create_rent_order_params.dart';
import 'package:smart_chaja/features/chargenow_devices/create_rent_order/model/create_rent_order_response.dart';
import 'package:smart_chaja/features/core/utils/base64_encoder.dart';
import 'package:smart_chaja/features/chargenow_devices/api_exception/chargenow_api_exception.dart';
import 'package:smart_chaja/features/core/config/env_config.dart';


class ChargeNowRentService {
  final http.Client _httpClient;

  ChargeNowRentService(this._httpClient);

  String _getBasicAuthHeader() {
    final username = EnvConfig.chargeNowUsername;
    final password = EnvConfig.chargeNowPassword;

    if (username.isEmpty || password.isEmpty) {
      print("ChargeNowRentService: ERROR - Username or Password for ChargeNow API is missing in EnvConfig.");
      throw ChargeNowApiException(message: "ChargeNow API credentials not configured.");
    }
    String credentials = '$username:$password';
    return 'Basic ${Base64Encoder.encode(credentials)}';
  }

  Future<CreateRentOrderResponse> createRentOrder(CreateRentOrderParams params) async {
    final uri = Uri.parse(ChargeNowApiConfig.createRentOrderUrl) // Use from ChargeNowApiConfig
        .replace(queryParameters: params.toQueryParameters());

    print("ChargeNowRentService: Creating rent order at $uri");

    try {
      final response = await _httpClient.post(
        uri,
        headers: {
          'Authorization': _getBasicAuthHeader(),
          'Accept': 'application/json',
          // 'Content-Type' is not typically needed for POST with only query params and no body
        },
        // No body, as parameters are in the query
      );

      String responseBodyPreview = response.body.length > 200 ? "${response.body.substring(0, 200)}..." : response.body;
      print("ChargeNowRentService (CreateRentOrder): Status: ${response.statusCode}, Body preview: $responseBodyPreview");

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        // The CreateRentOrderResponse.fromJson handles checking the internal 'code'
        return CreateRentOrderResponse.fromJson(jsonResponse);
      } else {
        // Use the dedicated ChargeNowApiException factory for HTTP errors
        throw ChargeNowApiException.fromResponse(response.statusCode, response.body);
      }
    } on SocketException catch (e) {
      print("ChargeNowRentService: SocketException (CreateRentOrder) - ${e.message}");
      throw ChargeNowNetworkException(message: "Network error (CreateRentOrder): ${e.message}");
    } on ChargeNowApiException { // Re-throw if it's already a ChargeNowApiException
      rethrow;
    } on http.ClientException catch(e) { // Catch other http client errors
      print("ChargeNowRentService: ClientException (CreateRentOrder) - ${e.message}");
      throw ChargeNowNetworkException(message: "HTTP Client error (CreateRentOrder): ${e.message}");
    } catch (e) { // Catch-all for other unexpected errors
      print("ChargeNowRentService: Generic Exception (CreateRentOrder) - ${e.toString()}");
      throw ChargeNowApiException(message: "Unexpected error (CreateRentOrder): ${e.toString()}");
    }
  }
}