import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:smart_chaja/app_constants/charge_now_api_config.dart';

import 'package:smart_chaja/features/chargenow_devices/api_exception/chargenow_api_exception.dart';
import 'package:smart_chaja/features/chargenow_devices/close_rent_order/model/close_rent_order_params.dart';
import 'package:smart_chaja/features/chargenow_devices/close_rent_order/model/close_rent_order_response.dart';
import 'package:smart_chaja/features/core/utils/base64_encoder.dart';
import 'package:smart_chaja/features/core/config/env_config.dart';

class ChargeNowCloseService {
  final http.Client _httpClient;

  ChargeNowCloseService(this._httpClient);

  String _getBasicAuthHeader() {
    final username = EnvConfig.chargeNowUsername;
    final password = EnvConfig.chargeNowPassword;

    if (username.isEmpty || password.isEmpty) {
      print("ChargeNowCloseService: ERROR - Username or Password for ChargeNow API is missing in EnvConfig.");
      throw ChargeNowApiException(message: "ChargeNow API credentials not configured.");
    }
    String credentials = '$username:$password';
    return 'Basic ${Base64Encoder.encode(credentials)}';
  }

  Future<CloseRentOrderResponse> closeRentOrder(CloseRentOrderParams params) async {
    final uri = Uri.parse(ChargeNowApiConfig.closeRentOrderUrl)
        .replace(queryParameters: params.toQueryParameters());

    print("ChargeNowCloseService: Closing rent order at $uri");

    try {
      final response = await _httpClient.post(
        uri,
        headers: {
          'Authorization': _getBasicAuthHeader(),
          'Accept': 'application/json',
        },
      );

      String responseBodyPreview = response.body.length > 200 ? "${response.body.substring(0, 200)}..." : response.body;
      print("ChargeNowCloseService (CloseRentOrder): Status: ${response.statusCode}, Body preview: $responseBodyPreview");

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        return CloseRentOrderResponse.fromJson(jsonResponse);
      } else {
        throw ChargeNowApiException.fromResponse(response.statusCode, response.body);
      }
    } on SocketException catch (e) {
      print("ChargeNowCloseService: SocketException (CloseRentOrder) - ${e.message}");
      throw ChargeNowNetworkException(message: "Network error (CloseRentOrder): ${e.message}");
    } on ChargeNowApiException {
      rethrow;
    } on http.ClientException catch (e) {
      print("ChargeNowCloseService: ClientException (CloseRentOrder) - ${e.message}");
      throw ChargeNowNetworkException(message: "HTTP Client error (CloseRentOrder): ${e.message}");
    } catch (e) {
      print("ChargeNowCloseService: Generic Exception (CloseRentOrder) - ${e.toString()}");
      throw ChargeNowApiException(message: "Unexpected error (CloseRentOrder): ${e.toString()}");
    }
  }
}