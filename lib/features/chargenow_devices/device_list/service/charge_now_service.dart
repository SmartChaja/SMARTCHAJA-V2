// File: lib/features/chargenow_devices/service/charge_now_service.dart
import 'dart:convert';
import 'dart:io';

import 'package:smart_chaja/app_constants/charge_now_api_config.dart';
import 'package:smart_chaja/features/chargenow_devices/api_exception/chargenow_api_exception.dart';
import 'package:smart_chaja/features/chargenow_devices/device_list/model/charge_now_device_list_response.dart';
import 'package:smart_chaja/features/chargenow_devices/device_list/model/charge_now_device_params.dart';
import 'package:smart_chaja/features/core/config/env_config.dart';
import 'package:smart_chaja/features/core/utils/base64_encoder.dart';
import 'package:http/http.dart' as http;


class ChargeNowService {
  final http.Client _httpClient; // Use a standard http.Client for Basic Auth

  ChargeNowService(this._httpClient); // Inject a standard client

  String _getBasicAuthHeader() {
    final username = EnvConfig.chargeNowUsername;
    final password = EnvConfig.chargeNowPassword;

    if (username.isEmpty || password.isEmpty) {
        print("ChargeNowService: Username or Password for ChargeNow API is missing in .env file.");
        throw ChargeNowApiException(message: "ChargeNow API credentials not configured.");
    }
    String credentials = '$username:$password';
    return 'Basic ${Base64Encoder.encode(credentials)}';
  }

  Future<ChargeNowDeviceListResponse> getDeviceList(ChargeNowDeviceParams params) async {
    final uri = Uri.parse(ChargeNowApiConfig.deviceListUrl)
        .replace(queryParameters: params.toQueryParameters());

    print("ChargeNowService: Creating POST request for $uri");

    final request = http.Request('POST', uri);

    // Set headers on the request object
    request.headers.addAll({
      'Authorization': _getBasicAuthHeader(), // Basic Auth is set here
      'Accept': 'application/json',
    });
    // No body for this POST request as per API spec (params are query params)

    try {
      print("ChargeNowService: Sending request to $uri with headers: ${request.headers}");
      // Use the standard client's send method
      final http.StreamedResponse streamedResponse = await _httpClient.send(request);
      
      final response = await http.Response.fromStream(streamedResponse);

      String responseBodyPreview = response.body.length > 200 ? "${response.body.substring(0, 200)}..." : response.body;
      print("ChargeNowService (GetDeviceList): Status: ${response.statusCode}, Body preview: $responseBodyPreview");

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse['code'] == 0) {
          return ChargeNowDeviceListResponse.fromJson(jsonResponse);
        } else {
          throw ChargeNowApiException(
            message: jsonResponse['msg'] ?? 'ChargeNow API indicated an error with code ${jsonResponse['code']}.',
            statusCode: response.statusCode,
            apiInternalCode: jsonResponse['code']?.toString(),
            errorDetail: jsonResponse['msg'],
          );
        }
      } else {
        throw ChargeNowApiException.fromResponse(response.statusCode, response.body);
      }
    } on SocketException catch (e) {
      throw ChargeNowNetworkException(message: "Could not reach ChargeNow server. (${e.message})");
    } on ChargeNowApiException {
      rethrow;
    } on http.ClientException catch(e) {
      throw ChargeNowNetworkException(message: "HTTP Client error: ${e.message}");
    } catch (e) {
      throw ChargeNowApiException(message: "Unexpected error fetching devices: ${e.toString()}");
    }
  }
}