import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:smart_chaja/app_constants/charge_now_api_config.dart';
import 'package:smart_chaja/features/chargenow_devices/api_exception/chargenow_api_exception.dart';
import 'package:smart_chaja/features/chargenow_devices/get_order_detail/model/get_order_detail_params.dart';
import 'package:smart_chaja/features/chargenow_devices/get_order_detail/model/get_order_detail_response.dart';
import 'package:smart_chaja/features/core/utils/base64_encoder.dart';
import 'package:smart_chaja/features/core/config/env_config.dart';

class ChargeNowDetailService {
  final http.Client _httpClient;

  ChargeNowDetailService(this._httpClient);

  String _getBasicAuthHeader() {
    final username = EnvConfig.chargeNowUsername;
    final password = EnvConfig.chargeNowPassword;

    if (username.isEmpty || password.isEmpty) {
      print("ChargeNowDetailService: ERROR - Username or Password for ChargeNow API is missing in EnvConfig.");
      throw ChargeNowApiException(message: "ChargeNow API credentials not configured.");
    }
    String credentials = '$username:$password';
    return 'Basic ${Base64Encoder.encode(credentials)}';
  }

  Future<GetOrderDetailResponse> getOrderDetail(GetOrderDetailParams params) async {
    final uri = Uri.parse(ChargeNowApiConfig.getOrderDetailUrl)
        .replace(queryParameters: params.toQueryParameters());

    print("ChargeNowDetailService: Fetching order details at $uri");

    try {
      final response = await _httpClient.get(
        uri,
        headers: {
          'Authorization': _getBasicAuthHeader(),
          'Accept': 'application/json',
        },
      );

      String responseBodyPreview = response.body.length > 200 ? "${response.body.substring(0, 200)}..." : response.body;
      print("ChargeNowDetailService (GetOrderDetail): Status: ${response.statusCode}, Body preview: $responseBodyPreview");

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        return GetOrderDetailResponse.fromJson(jsonResponse);
      } else {
        throw ChargeNowApiException.fromResponse(response.statusCode, response.body);
      }
    } on SocketException catch (e) {
      print("ChargeNowDetailService: SocketException (GetOrderDetail) - ${e.message}");
      throw ChargeNowNetworkException(message: "Network error (GetOrderDetail): ${e.message}");
    } on ChargeNowApiException {
      rethrow;
    } on http.ClientException catch (e) {
      print("ChargeNowDetailService: ClientException (GetOrderDetail) - ${e.message}");
      throw ChargeNowNetworkException(message: "HTTP Client error (GetOrderDetail): ${e.message}");
    } catch (e) {
      print("ChargeNowDetailService: Generic Exception (GetOrderDetail) - ${e.toString()}");
      throw ChargeNowApiException(message: "Unexpected error (GetOrderDetail): ${e.toString()}");
    }
  }
}