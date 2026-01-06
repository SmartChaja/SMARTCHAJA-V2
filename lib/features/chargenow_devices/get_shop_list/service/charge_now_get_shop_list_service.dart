import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:smart_chaja/app_constants/charge_now_api_config.dart';
import 'package:smart_chaja/features/chargenow_devices/api_exception/chargenow_api_exception.dart';
import 'package:smart_chaja/features/chargenow_devices/get_shop_list/model/get_shop_list_response.dart';
import 'package:smart_chaja/features/core/utils/base64_encoder.dart';
import 'package:smart_chaja/features/core/config/env_config.dart';

class ChargeNowGetShopListService {
  final http.Client _httpClient;

  ChargeNowGetShopListService(this._httpClient);

  String _getBasicAuthHeader() {
    final username = EnvConfig.chargeNowUsername;
    final password = EnvConfig.chargeNowPassword;

    if (username.isEmpty || password.isEmpty) {
      print("ChargeNowGetShopListService: ERROR - Username or Password for ChargeNow API is missing in EnvConfig.");
      throw ChargeNowApiException(message: "ChargeNow API credentials not configured.");
    }
    String credentials = '$username:$password';
    return 'Basic ${Base64Encoder.encode(credentials)}';
  }

  Future<GetShopListResponse> getShopList() async {
    final uri = Uri.parse(ChargeNowApiConfig.getShopListUrl);

    print("ChargeNowGetShopListService: Fetching shop list at $uri");

    try {
      final response = await _httpClient.get(
        uri,
        headers: {
          'Authorization': _getBasicAuthHeader(),
          'Accept': 'application/json',
        },
      );

      String responseBodyPreview = response.body.length > 200 ? "${response.body.substring(0, 200)}..." : response.body;
      print("ChargeNowGetShopListService (GetShopList): Status: ${response.statusCode}, Body preview: $responseBodyPreview");

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        return GetShopListResponse.fromJson(jsonResponse);
      } else {
        throw ChargeNowApiException.fromResponse(response.statusCode, response.body);
      }
    } on SocketException catch (e) {
      print("ChargeNowGetShopListService: SocketException (GetShopList) - ${e.message}");
      throw ChargeNowNetworkException(message: "Network error (GetShopList): ${e.message}");
    } on ChargeNowApiException {
      rethrow;
    } on http.ClientException catch (e) {
      print("ChargeNowGetShopListService: ClientException (GetShopList) - ${e.message}");
      throw ChargeNowNetworkException(message: "HTTP Client error (GetShopList): ${e.message}");
    } catch (e) {
      print("ChargeNowGetShopListService: Generic Exception (GetShopList) - ${e.toString()}");
      throw ChargeNowApiException(message: "Unexpected error (GetShopList): ${e.toString()}");
    }
  }
}