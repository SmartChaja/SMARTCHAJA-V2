import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:smart_chaja/app_constants/charge_now_api_config.dart';
import 'package:smart_chaja/features/chargenow_devices/api_exception/chargenow_api_exception.dart';
import 'package:smart_chaja/features/chargenow_devices/eject_battery_slot/model/eject_battery_params.dart';
import 'package:smart_chaja/features/chargenow_devices/eject_battery_slot/model/eject_battery_response.dart';
import 'package:smart_chaja/features/core/utils/base64_encoder.dart';
import 'package:smart_chaja/features/core/config/env_config.dart';

class ChargeNowEjectService {
  final http.Client _httpClient;

  ChargeNowEjectService(this._httpClient);

  String _getBasicAuthHeader() {
    final username = EnvConfig.chargeNowUsername;
    final password = EnvConfig.chargeNowPassword;

    if (username.isEmpty || password.isEmpty) {
      print("ChargeNowEjectService: ERROR - Username or Password for ChargeNow API is missing in EnvConfig.");
      throw ChargeNowApiException(message: "ChargeNow API credentials not configured.");
    }
    String credentials = '$username:$password';
    return 'Basic ${Base64Encoder.encode(credentials)}';
  }

  Future<EjectBatteryResponse> ejectBattery(EjectBatteryParams params) async {
    final uri = Uri.parse(ChargeNowApiConfig.ejectBatteryUrl)
        .replace(queryParameters: params.toQueryParameters());

    print("ChargeNowEjectService: Ejecting battery at $uri");

    try {
      final response = await _httpClient.post(
        uri,
        headers: {
          'Authorization': _getBasicAuthHeader(),
          'Accept': 'application/json',
        },
      );

      String responseBodyPreview = response.body.length > 200 ? "${response.body.substring(0, 200)}..." : response.body;
      print("ChargeNowEjectService (EjectBattery): Status: ${response.statusCode}, Body preview: $responseBodyPreview");

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        return EjectBatteryResponse.fromJson(jsonResponse);
      } else {
        throw ChargeNowApiException.fromResponse(response.statusCode, response.body);
      }
    } on SocketException catch (e) {
      print("ChargeNowEjectService: SocketException (EjectBattery) - ${e.message}");
      throw ChargeNowNetworkException(message: "Network error (EjectBattery): ${e.message}");
    } on ChargeNowApiException {
      rethrow;
    } on http.ClientException catch (e) {
      print("ChargeNowEjectService: ClientException (EjectBattery) - ${e.message}");
      throw ChargeNowNetworkException(message: "HTTP error (EjectBattery): ${e.message}");
    } catch (e) {
      print("ChargeNowEjectService: Generic Exception (EjectBattery) - ${e.toString()}");
      throw ChargeNowApiException(message: "Unexpected error (EjectBattery): ${e.toString()}");
    }
  }
}