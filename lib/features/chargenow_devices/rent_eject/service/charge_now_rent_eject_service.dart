import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:smart_chaja/app_constants/charge_now_api_config.dart';
import 'package:smart_chaja/features/chargenow_devices/api_exception/chargenow_api_exception.dart';
import 'package:smart_chaja/features/chargenow_devices/rent_eject/model/rent_eject_params.dart';
import 'package:smart_chaja/features/chargenow_devices/rent_eject/model/rent_eject_response.dart';
import 'package:smart_chaja/features/core/utils/base64_encoder.dart';
import 'package:smart_chaja/features/core/config/env_config.dart';

class ChargeNowRentEjectService {
  final http.Client _httpClient;

  ChargeNowRentEjectService(this._httpClient);

  String _getBasicAuthHeader() {
    final username = EnvConfig.chargeNowUsername;
    final password = EnvConfig.chargeNowPassword;

    if (username.isEmpty || password.isEmpty) {
      print("ChargeNowRentEjectService: ERROR - Username or Password for ChargeNow API is missing in EnvConfig.");
      throw ChargeNowApiException(message: "ChargeNow API credentials not configured.");
    }
    String credentials = '$username:$password';
    return 'Basic ${Base64Encoder.encode(credentials)}';
  }

  Future<RentEjectResponse> rentEjectBattery(RentEjectParams params) async {
    final uri = Uri.parse(ChargeNowApiConfig.rentEjectUrl)
        .replace(queryParameters: params.toQueryParameters());

    print("ChargeNowRentEjectService: Renting and ejecting battery at $uri");

    try {
      final response = await _httpClient.post(
        uri,
        headers: {
          'Authorization': _getBasicAuthHeader(),
          'Accept': 'application/json',
        },
      );

      String responseBodyPreview = response.body.length > 200 ? "${response.body.substring(0, 200)}..." : response.body;
      print("ChargeNowRentEjectService (RentEjectBattery): Status: ${response.statusCode}, Body preview: $responseBodyPreview");

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        return RentEjectResponse.fromJson(jsonResponse);
      } else {
        throw ChargeNowApiException.fromResponse(response.statusCode, response.body);
      }
    } on SocketException catch (e) {
      print("ChargeNowRentEjectService: SocketException (RentEjectBattery) - ${e.message}");
      throw ChargeNowNetworkException(message: "Network error (RentEjectBattery): ${e.message}");
    } on ChargeNowApiException {
      rethrow;
    } on http.ClientException catch (e) {
      print("ChargeNowRentEjectService: ClientException (RentEjectBattery) - ${e.message}");
      throw ChargeNowNetworkException(message: "HTTP Client error (RentEjectBattery): ${e.message}");
    } catch (e) {
      print("ChargeNowRentEjectService: Generic Exception (RentEjectBattery) - ${e.toString()}");
      throw ChargeNowApiException(message: "Unexpected error (RentEjectBattery): ${e.toString()}");
    }
  }
}