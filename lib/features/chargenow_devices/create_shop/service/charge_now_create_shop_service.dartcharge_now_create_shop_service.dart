import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:smart_chaja/app_constants/charge_now_api_config.dart';
import 'package:smart_chaja/features/chargenow_devices/api_exception/chargenow_api_exception.dart';
import 'package:smart_chaja/features/chargenow_devices/create_shop/model/create_shop_params.dart';
import 'package:smart_chaja/features/chargenow_devices/create_shop/model/create_shop_response.dart';
import 'package:smart_chaja/features/core/utils/base64_encoder.dart';
import 'package:smart_chaja/features/core/config/env_config.dart';

class ChargeNowCreateShopService {
  final http.Client _httpClient;

  ChargeNowCreateShopService(this._httpClient);

  String _getBasicAuthHeader() {
    final username = EnvConfig.chargeNowUsername;
    final password = EnvConfig.chargeNowPassword;

    if (username.isEmpty || password.isEmpty) {
      print("ChargeNowCreateShopService: ERROR - Username or Password for ChargeNow API is missing in EnvConfig.");
      throw ChargeNowApiException(message: "ChargeNow API credentials not configured.");
    }
    String credentials = '$username:$password';
    return 'Basic ${Base64Encoder.encode(credentials)}';
  }

  Future<CreateShopResponse> createShop(CreateShopParams params) async {
    final uri = Uri.parse(ChargeNowApiConfig.createShopUrl);

    print("ChargeNowCreateShopService: Creating shop at $uri");

    try {
      final response = await _httpClient.post(
        uri,
        headers: {
          'Authorization': _getBasicAuthHeader(),
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(params.toJson()),
      );

      String responseBodyPreview = response.body.length > 200 ? "${response.body.substring(0, 200)}..." : response.body;
      print("ChargeNowCreateShopService (CreateShop): Status: ${response.statusCode}, Body preview: $responseBodyPreview");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        return CreateShopResponse.fromJson(jsonResponse);
      } else {
        throw ChargeNowApiException.fromResponse(response.statusCode, response.body);
      }
    } on SocketException catch (e) {
      print("ChargeNowCreateShopService: SocketException (CreateShop) - ${e.message}");
      throw ChargeNowNetworkException(message: "Network error (CreateShop): ${e.message}");
    } on ChargeNowApiException {
      rethrow;
    } on http.ClientException catch (e) {
      print("ChargeNowCreateShopService: ClientException (CreateShop) - ${e.message}");
      throw ChargeNowNetworkException(message: "HTTP Client error (CreateShop): ${e.message}");
    } catch (e) {
      print("ChargeNowCreateShopService: Generic Exception (CreateShop) - ${e.toString()}");
      throw ChargeNowApiException(message: "Unexpected error (CreateShop): ${e.toString()}");
    }
  }
}