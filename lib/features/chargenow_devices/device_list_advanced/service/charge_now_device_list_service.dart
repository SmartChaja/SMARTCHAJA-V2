import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:smart_chaja/app_constants/charge_now_api_config.dart';
import 'package:smart_chaja/features/chargenow_devices/api_exception/chargenow_api_exception.dart';
import 'package:smart_chaja/features/chargenow_devices/device_list_advanced/model/device_list_response.dart';
import 'package:smart_chaja/features/core/utils/base64_encoder.dart';

import 'package:smart_chaja/features/core/config/env_config.dart';

class ChargeNowDeviceListService {
  final http.Client _httpClient;

  ChargeNowDeviceListService(this._httpClient);

  String _getBasicAuthHeader() {
    final username = EnvConfig.chargeNowUsername;
    final password = EnvConfig.chargeNowPassword;

    if (username.isEmpty || password.isEmpty) {
      print("ChargeNowDeviceListService: ERROR - Username or Password for ChargeNow is missing in EnvConfig.");
      throw ChargeNowApiException(message:"No charge available due to missing credentials.");
    }
    String credentials = '$username:$password';
    return 'Basic ${Base64Encoder.encode(credentials)}';
  }

  Future<DeviceListResponse> getAllDevices() async {
    final uri = Uri.parse(ChargeNowApiConfig.getAllDeviceUrl);

    print("ChargeNowDeviceListService: Fetching all devices at $uri");

    try {
      final response = await _httpClient.get(
        uri,
        headers: {
          'Authorization': _getBasicAuthHeader(),
          'Accept': 'application/json',
        },
      );

      String responseBodyPreview = response.body.length > 200 ? "${response.body.substring(0, 200)}..." : response.body;
      print("ChargeNowDeviceListService (GetAllDevices): Status: ${response.statusCode}, Body preview: $responseBodyPreview");

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        return DeviceListResponse.fromJson(jsonResponse);
      } else {
        throw ChargeNowApiException.fromResponse(response.statusCode, response.body);
      }
    } on SocketException catch (e) {
      print("ChargeNowDeviceListService: SocketException (GetAllDevices) - ${e.message}");
      throw ChargeNowNetworkException(message: "Network error (GetAllDevices): ${e.message}");
    } on ChargeNowApiException {
      rethrow;
    } on http.ClientException catch (e) {
      print("ChargeNowDeviceListService: ClientException (GetAllDevices) - ${e.message}");
      throw ChargeNowNetworkException(message: "HTTP Client error (GetAllDevices): ${e.message}");
    } catch (e) {
      print("ChargeNowDeviceListService: Generic Exception (GetAllDevices) - ${e.toString()}");
      throw ChargeNowApiException(message: "Unexpected error (GetAllDevices): ${e.toString()}");
    }
  }
}