// File: lib/features/chargenow_devices/service/charge_now_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:smart_chaja/app_constants/charge_now_api_config.dart';
import 'package:smart_chaja/features/core/utils/base64_encoder.dart';
import 'package:http/http.dart' as http;
import 'package:smart_chaja/features/chargenow_devices/api_exception/chargenow_api_exception.dart';
import 'package:smart_chaja/features/chargenow_devices/device_info/model/charge_now_device_info_response.dart';
import 'package:smart_chaja/features/core/config/env_config.dart';


class ChargeNowService {
  final http.Client _httpClient;

  ChargeNowService(this._httpClient);

  String _getBasicAuthHeader() {
    final username = EnvConfig.chargeNowUsername;
    final password = EnvConfig.chargeNowPassword; 

    if (username.isEmpty || password.isEmpty) {
        print("ChargeNowService: Username or Password for ChargeNow API is missing in EnvConfig.");
        // It's better to throw an error that can be caught and displayed rather than just printing
        throw ChargeNowApiException(message: "ChargeNow API credentials not configured. Please check environment settings.");
    }
    String credentials = '$username:$password';
    // Assuming Base64Encoder.encode is a utility you have
    return 'Basic ${Base64Encoder.encode(credentials)}';
  }

 
  Future<ChargeNowDeviceInfoResponse> getDeviceInfo(String deviceId) async {
    final uri = Uri.parse(ChargeNowApiConfig.deviceInfoUrl) // Using updated config
        .replace(queryParameters: {'deviceId': deviceId});

    print("ChargeNowService: Creating GET request for Device Info: $uri");

    try {
      final response = await _httpClient.get( 
        uri,
        headers: {
          'Authorization': _getBasicAuthHeader(),
          'Accept': 'application/json',
        },
      );

      String responseBodyPreview = response.body.length > 200 ? "${response.body.substring(0, 200)}..." : response.body;
      print("ChargeNowService (GetDeviceInfo): Status: ${response.statusCode}, Body preview: $responseBodyPreview");

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse['code'] == 0) {
          // Ensure data is not null before parsing, or handle null in DeviceInfoData.fromJson
          if (jsonResponse['data'] == null) {
            throw ChargeNowApiException(
              message: jsonResponse['msg'] ?? 'Device data not found for ID $deviceId, but API returned success.',
              statusCode: response.statusCode,
              apiInternalCode: jsonResponse['code']?.toString(),
            );
          }
          return ChargeNowDeviceInfoResponse.fromJson(jsonResponse);
        } else {
          throw ChargeNowApiException(
            message: jsonResponse['msg'] ?? 'ChargeNow API error (code ${jsonResponse['code']}) for device info.',
            statusCode: response.statusCode,
            apiInternalCode: jsonResponse['code']?.toString(),
            errorDetail: jsonResponse['data'], // Include data from response if error
          );
        }
      } else {
        throw ChargeNowApiException.fromResponse(response.statusCode, response.body);
      }
    } on SocketException catch (e) {
      throw ChargeNowNetworkException(message: "Network error (DeviceInfo): ${e.message}");
    } on ChargeNowApiException {
      rethrow;
    } on http.ClientException catch(e) {
      throw ChargeNowNetworkException(message: "HTTP Client error (DeviceInfo): ${e.message}");
    } catch (e) {
      throw ChargeNowApiException(message: "Unexpected error (DeviceInfo): ${e.toString()}");
    }
  }
}