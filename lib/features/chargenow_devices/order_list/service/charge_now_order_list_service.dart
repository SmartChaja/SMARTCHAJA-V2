import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:smart_chaja/app_constants/charge_now_api_config.dart';
import 'package:smart_chaja/features/chargenow_devices/api_exception/chargenow_api_exception.dart';
import 'package:smart_chaja/features/chargenow_devices/order_list/model/order_list_params.dart';
import 'package:smart_chaja/features/chargenow_devices/order_list/model/order_list_response.dart';
import 'package:smart_chaja/features/core/utils/base64_encoder.dart';
import 'package:smart_chaja/features/core/config/env_config.dart';

class ChargeNowOrderListService {
  final http.Client _httpClient;

  ChargeNowOrderListService(this._httpClient);

  String _getBasicAuthHeader() {
    final username = EnvConfig.chargeNowUsername;
    final password = EnvConfig.chargeNowPassword;

    if (username.isEmpty || password.isEmpty) {
      print("ChargeNowOrderListService: ERROR - Username or Password for ChargeNow API is missing in EnvConfig.");
      throw ChargeNowApiException(message: "ChargeNow API credentials not configured.");
    }
    String credentials = '$username:$password';
    return 'Basic ${Base64Encoder.encode(credentials)}';
  }

  Future<OrderListResponse> getOrderList(OrderListParams params) async {
    final uri = Uri.parse(ChargeNowApiConfig.getOrderListUrl)
        .replace(queryParameters: params.toQueryParameters());

    print("ChargeNowOrderListService: Fetching order list at $uri");

    try {
      final response = await _httpClient.get(
        uri,
        headers: {
          'Authorization': _getBasicAuthHeader(),
          'Accept': 'application/json',
        },
      );

      String responseBodyPreview = response.body.length > 200 ? "${response.body.substring(0, 200)}..." : response.body;
      print("ChargeNowOrderListService (GetOrderList): Status: ${response.statusCode}, Body preview: $responseBodyPreview");

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        return OrderListResponse.fromJson(jsonResponse);
      } else {
        throw ChargeNowApiException.fromResponse(response.statusCode, response.body);
      }
    } on SocketException catch (e) {
      print("ChargeNowOrderListService: SocketException (GetOrderList) - ${e.message}");
      throw ChargeNowNetworkException(message: "Network error (GetOrderList): ${e.message}");
    } on ChargeNowApiException {
      rethrow;
    } on http.ClientException catch (e) {
      print("ChargeNowOrderListService: ClientException (GetOrderList) - ${e.message}");
      throw ChargeNowNetworkException(message: "HTTP Client error (GetOrderList): ${e.message}");
    } catch (e) {
      print("ChargeNowOrderListService: Generic Exception (GetOrderList) - ${e.toString()}");
      throw ChargeNowApiException(message: "Unexpected error (GetOrderList): ${e.toString()}");
    }
  }
}