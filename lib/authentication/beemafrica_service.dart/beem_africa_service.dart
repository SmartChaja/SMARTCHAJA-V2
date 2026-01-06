// ============================================
// FILE: beem_africa_service.dart
// ============================================
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class BeemAfricaService {
  final String apiKey;
  final String secretKey; // IMPORTANT: This must be the RAW secret key
  final String senderId;
  final String baseUrl = 'https://apisms.beem.africa/v1';
  final String dlrBaseUrl = 'https://dlrapi.beem.africa/public/v1';
  final String balanceUrl =
      'https://apisms.beem.africa/public/v1/vendors/balance';

  BeemAfricaService({
    required this.apiKey,
    required this.secretKey,
    required this.senderId,
  });

  /// Helper to build the Basic Authentication header
  /// According to Beem docs: Authorization: Basic base64(api_key:secret_key)
  String _buildAuthHeader() {
    if (apiKey.isEmpty || secretKey.isEmpty) {
      throw Exception('API Key and Secret Key cannot be empty.');
    }

    // This implementation expects a RAW secret key.
    // It combines the api key and raw secret key, then base64-encodes the result.
    final credentials = '$apiKey:$secretKey';
    final encoded = base64Encode(utf8.encode(credentials));

    return 'Basic $encoded';
  }

  /// Helper to get standard request headers
  Map<String, String> _headers() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': _buildAuthHeader(),
    };
  }

  /// ✅ Send SMS
  Future<Map<String, dynamic>> sendSMS({
    required String phoneNumber,
    required String message,
  }) async {
    try {
      // Remove '+' if present - API expects international format without plus
      // e.g., +255786112616 -> 255786112616
      final cleanPhoneNumber = phoneNumber.replaceAll('+', '').trim();

      final data = {
        'source_addr': senderId,
        'encoding': 0,
        'message': message,
        'recipients': [
          {'recipient_id': 1, 'dest_addr': cleanPhoneNumber},
        ],
      };

      final url = Uri.parse('$baseUrl/send');
      final response =
          await http.post(url, headers: _headers(), body: jsonEncode(data));

      Map<String, dynamic> responseBody = {};
      try {
        responseBody = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        // Keep empty map if body isn't JSON
      }

      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          responseBody['successful'] == true) {
        debugPrint('✅ SMS submitted successfully to $cleanPhoneNumber');
        return responseBody;
      } else {
        final errorMessage = responseBody['message'] ?? response.body;
        // Provide clearer hints for common Beem failures
        final hint = () {
          if (response.statusCode == 401 ||
              (errorMessage
                  .toString()
                  .toLowerCase()
                  .contains('unauthorized'))) {
            return ' Check Beem credentials (API key/secret).';
          }
          if (errorMessage.toString().toLowerCase().contains('sender') &&
              errorMessage.toString().toLowerCase().contains('not')) {
            return ' Verify the sender ID is approved on Beem.';
          }
          if (response.statusCode == 400 &&
              errorMessage.toString().toLowerCase().contains('dest_addr')) {
            return ' Ensure phone number is in local format, e.g., 07XXXXXXXX.';
          }
          return '';
        }();
        throw Exception(
            'Failed to send SMS (${response.statusCode}): $errorMessage$hint');
      }
    } catch (e) {
      debugPrint('❌ Error in sendSMS: $e');
      rethrow;
    }
  }

  /// ✅ Check SMS balance
  Future<Map<String, dynamic>> checkBalance() async {
    final url = Uri.parse(balanceUrl);
    final response = await http.get(url, headers: _headers());

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          'Balance check failed (${response.statusCode}): ${response.body}');
    }
  }

  /// ✅ Check delivery report
  Future<Map<String, dynamic>> checkDeliveryReport({
    required String destAddr,
    required String requestId,
  }) async {
    final cleanDestAddr = destAddr.replaceAll('+', '').trim();

    final uri =
        Uri.parse('$dlrBaseUrl/delivery-reports').replace(queryParameters: {
      'dest_addr': cleanDestAddr,
      'request_id': requestId,
    });

    final response = await http.get(uri, headers: _headers());

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          'Delivery report failed (${response.statusCode}): ${response.body}');
    }
  }

  /// ✅ Get sender names
  Future<Map<String, dynamic>> getSenderNames(
      {String? q, String? status}) async {
    final params = <String, String>{};
    if (q != null) params['q'] = q;
    if (status != null) params['status'] = status;

    final uri =
        Uri.parse('$baseUrl/sender-names').replace(queryParameters: params);
    final response = await http.get(uri, headers: _headers());

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          'Failed to get sender names (${response.statusCode}): ${response.body}');
    }
  }

  /// ✅ Request a new sender name
  Future<Map<String, dynamic>> requestSenderName({
    required String senderId,
    required String sampleContent,
  }) async {
    final data = {'senderid': senderId, 'sample_content': sampleContent};
    final url = Uri.parse('$baseUrl/sender-names');
    final response =
        await http.post(url, headers: _headers(), body: jsonEncode(data));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          'Failed to request sender name (${response.statusCode}): ${response.body}');
    }
  }
}
