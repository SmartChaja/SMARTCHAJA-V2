import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:smart_chaja/app_constants/charge_now_api_config.dart';
import 'package:smart_chaja/features/chargenow_devices/api_exception/chargenow_api_exception.dart';
import 'package:smart_chaja/features/chargenow_devices/update_shop/model/shop_params.dart';
import 'package:smart_chaja/features/chargenow_devices/update_shop/model/update_shop_response.dart';
import 'package:smart_chaja/features/core/utils/base64_encoder.dart';
import 'package:smart_chaja/features/core/config/env_config.dart';

class ChargeNowUpdateShopService {
  final http.Client _httpClient;

  ChargeNowUpdateShopService(this._httpClient);

  String _getBasicAuthHeader() {
    final username = EnvConfig.chargeNowUsername;
    final password = EnvConfig.chargeNowPassword;

    if (username.isEmpty || password.isEmpty) {
      print("ChargeNowUpdateShopService: ERROR - Username or Password for ChargeNow API is missing in EnvConfig.");
      throw ChargeNowApiException(message: "ChargeNow API credentials not configured.");
    }
    String credentials = '$username:$password';
    return 'Basic ${Base64Encoder.encode(credentials)}';
  }

  Future<UpdateShopResponse> updateShop(ShopParams params) async {
    final uri = Uri.parse(ChargeNowApiConfig.updateShopUrl);

    print("ChargeNowUpdateShopService: Updating shop at $uri");

    try {
      final response = await _httpClient.put(
        uri,
        headers: {
          'Authorization': _getBasicAuthHeader(),
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(params.toJson()),
      );

      String responseBodyPreview = response.body.length > 200 ? "${response.body.substring(0, 200)}..." : response.body;
      print("ChargeNowUpdateShopService (UpdateShop): Status: ${response.statusCode}, Body preview: $responseBodyPreview");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        return UpdateShopResponse.fromJson(jsonResponse);
      } else {
        throw ChargeNowApiException.fromResponse(response.statusCode, response.body);
      }
    } on SocketException catch (e) {
      print("ChargeNowUpdateShopService: SocketException (UpdateShop) - ${e.message}");
      throw ChargeNowNetworkException(message: "Network error (UpdateShop): ${e.message}");
    } on ChargeNowApiException {
      rethrow;
    } on http.ClientException catch (e) {
      print("ChargeNowUpdateShopService: ClientException (UpdateShop) - ${e.message}");
      throw ChargeNowNetworkException(message: "HTTP Client error (UpdateShop): ${e.message}");
    } catch (e) {
      print("ChargeNowUpdateShopService: Generic Exception (UpdateShop) - ${e.toString()}");
      throw ChargeNowApiException(message: "Unexpected error (UpdateShop): ${e.toString()}");
    }
  }
}