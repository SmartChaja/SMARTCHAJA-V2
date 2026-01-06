import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:smart_chaja/app_constants/charge_now_api_config.dart';
import 'package:smart_chaja/features/chargenow_devices/api_exception/chargenow_api_exception.dart';
import 'package:smart_chaja/features/chargenow_devices/bind_device_to_shop/model/bind_device_to_shop_response.dart';
import 'package:smart_chaja/features/core/utils/base64_encoder.dart';
import 'package:smart_chaja/features/core/config/env_config.dart';

class ChargeNowBindDeviceToShopService {
  final http.Client _httpClient;

  ChargeNowBindDeviceToShopService(this._httpClient);

  String _getBasicAuthHeader() {
    final username = EnvConfig.chargeNowUsername;
    final password = EnvConfig.chargeNowPassword;

    if (username.isEmpty || password.isEmpty) {
      print("ChargeNowBindDeviceToShopService: ERROR - Username or Password for ChargeNow API is missing in EnvConfig.");
      throw ChargeNowApiException(message: "ChargeNow API credentials not configured.");
    }
    String credentials = '$username:$password';
    return 'Basic ${Base64Encoder.encode(credentials)}';
  }

  Future<BindDeviceToShopResponse> bindDeviceToShop(String qrCode, String shopId) async {
    final uri = Uri.parse('${ChargeNowApiConfig.bindDeviceToShopUrl}/$qrCode/$shopId');

    print("ChargeNowBindDeviceToShopService: Binding device to shop at $uri");

    try {
      final response = await _httpClient.post(
        uri,
        headers: {
          'Authorization': _getBasicAuthHeader(),
          'Accept': 'application/json',
        },
      );

      String responseBodyPreview = response.body.length > 200 ? "${response.body.substring(0, 200)}..." : response.body;
      print("ChargeNowBindDeviceToShopService (BindDeviceToShop): Status: ${response.statusCode}, Body preview: $responseBodyPreview");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        return BindDeviceToShopResponse.fromJson(jsonResponse);
      } else {
        throw ChargeNowApiException.fromResponse(response.statusCode, response.body);
      }
    } on SocketException catch (e) {
      print("ChargeNowBindDeviceToShopService: SocketException (BindDeviceToShop) - ${e.message}");
      throw ChargeNowNetworkException(message: "Network error (BindDeviceToShop): ${e.message}");
    } on ChargeNowApiException {
      rethrow;
    } on http.ClientException catch (e) {
      print("ChargeNowBindDeviceToShopService: ClientException (BindDeviceToShop) - ${e.message}");
      throw ChargeNowNetworkException(message: "HTTP Client error (BindDeviceToShop): ${e.message}");
    } catch (e) {
      print("ChargeNowBindDeviceToShopService: Generic Exception (BindDeviceToShop) - ${e.toString()}");
      throw ChargeNowApiException(message: "Unexpected error (BindDeviceToShop): ${e.toString()}");
    }
  }
}