import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:smart_chaja/app_constants/charge_now_api_config.dart';
import 'package:smart_chaja/features/chargenow_devices/api_exception/chargenow_api_exception.dart';
import 'package:smart_chaja/features/chargenow_devices/delete_shop/model/delete_shop_response.dart';
import 'package:smart_chaja/features/core/utils/base64_encoder.dart';
import 'package:smart_chaja/features/core/config/env_config.dart';

class ChargeNowDeleteShopService {
  final http.Client _httpClient;

  ChargeNowDeleteShopService(this._httpClient);

  String _getBasicAuthHeader() {
    final username = EnvConfig.chargeNowUsername;
    final password = EnvConfig.chargeNowPassword;

    if (username.isEmpty || password.isEmpty) {
      print("ChargeNowDeleteShopService: ERROR - Username or Password for ChargeNow API is missing in EnvConfig.");
      throw ChargeNowApiException(message: "ChargeNow API credentials not configured.");
    }
    String credentials = '$username:$password';
    return 'Basic ${Base64Encoder.encode(credentials)}';
  }

  Future<DeleteShopResponse> deleteShop(String shopId) async {
    final uri = Uri.parse('${ChargeNowApiConfig.deleteShopUrl}/$shopId');

    print("ChargeNowDeleteShopService: Deleting shop at $uri");

    try {
      final response = await _httpClient.delete(
        uri,
        headers: {
          'Authorization': _getBasicAuthHeader(),
          'Accept': 'application/json',
        },
      );

      String responseBodyPreview = response.body.length > 200 ? "${response.body.substring(0, 200)}..." : response.body;
      print("ChargeNowDeleteShopService (DeleteShop): Status: ${response.statusCode}, Body preview: $responseBodyPreview");

      if (response.statusCode == 200 || response.statusCode == 204) {
        if (response.statusCode == 204) {
          return DeleteShopResponse(msg: 'Shop deleted successfully', code: 0, data: null);
        }
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        return DeleteShopResponse.fromJson(jsonResponse);
      } else {
        throw ChargeNowApiException.fromResponse(response.statusCode, response.body);
      }
    } on SocketException catch (e) {
      print("ChargeNowDeleteShopService: SocketException (DeleteShop) - ${e.message}");
      throw ChargeNowNetworkException(message: "Network error (DeleteShop): ${e.message}");
    } on ChargeNowApiException {
      rethrow;
    } on http.ClientException catch (e) {
      print("ChargeNowDeleteShopService: ClientException (DeleteShop) - ${e.message}");
      throw ChargeNowNetworkException(message: "HTTP Client error (DeleteShop): ${e.message}");
    } catch (e) {
      print("ChargeNowDeleteShopService: Generic Exception (DeleteShop) - ${e.toString()}");
      throw ChargeNowApiException(message: "Unexpected error (DeleteShop): ${e.toString()}");
    }
  }
}