import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'dart:developer';

/// Service to handle SMS sending via Beem Africa API
/// This service provides methods to send SMS notifications for power bank operations
class BeemSmsService {
  // Beem Africa API Credentials
  final String _apiKey = '247b432f75dbf2cd';
  final String _secretKey =
      'YTA3Zjg0NmFiZDhlMGZmZTc5YzRhMTk0ZDViZDQwMjE1ZmY4Njc0ZjU5MzVmZDcwMDc1NjdmOGMwYzE5OTQ4Ng==';
  final String _senderId = 'SmartChaja';

  // Tanzania country code
  static const String _tanzaniaCountryCode = '255';

  // API endpoint
  static const String _apiEndpoint = 'https://apisms.beem.africa/v1/send';

  /// Lazy initialize Dio instance with proper configuration
  late final Dio _dio = _initializeDio();

  /// Initialize Dio with proper headers and configuration
  Dio _initializeDio() {
    return Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        contentType: 'application/json',
        headers: {
          'Authorization': _getBasicAuth(),
        },
      ),
    );
  }

  /// Generate Basic Authentication header
  String _getBasicAuth() {
    String credentials = '$_apiKey:$_secretKey';
    String base64Credentials = base64Encode(utf8.encode(credentials));
    return 'Basic $base64Credentials';
  }

  /// Format phone number to international format with Tanzania country code
  /// Removes spaces, dashes, plus signs and ensures Tanzania country code is present
  String _formatPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    // Remove leading zeros if present (common in Tanzania format)
    if (cleaned.startsWith('0')) {
      cleaned = cleaned.substring(1);
    }

    // Add Tanzania country code if not already present
    if (!cleaned.startsWith(_tanzaniaCountryCode)) {
      cleaned = _tanzaniaCountryCode + cleaned;
    }

    return cleaned;
  }

  /// Send SMS for successful power bank rental
  /// Returns true if SMS sent successfully, false otherwise
  Future<bool> sendPowerBankRentalSMS({
    required String phoneNumber,
    required String userName,
    required String deviceId,
    required String tradeNo,
  }) async {
    final formattedPhone = _formatPhoneNumber(phoneNumber);
    final message =
        'Hi $userName your power bank $deviceId rental activated. Trade $tradeNo. SmartChaja';

    return _sendSms(
      phoneNumber: formattedPhone,
      message: message,
      operationType: 'Power Bank Rental',
    );
  }

  /// Send SMS for successful power bank return
  /// Returns true if SMS sent successfully, false otherwise
  Future<bool> sendPowerBankReturnSMS({
    required String phoneNumber,
    required String userName,
    required String deviceId,
    required String tradeNo,
  }) async {
    final formattedPhone = _formatPhoneNumber(phoneNumber);
    final message =
        'Hi $userName your power bank $deviceId returned successfully. Trade $tradeNo. Thank you SmartChaja';

    return _sendSms(
      phoneNumber: formattedPhone,
      message: message,
      operationType: 'Power Bank Return',
    );
  }

  /// Internal method to send SMS via Beem Africa API
  /// Returns true if successful, false otherwise
  Future<bool> _sendSms({
    required String phoneNumber,
    required String message,
    required String operationType,
  }) async {
    try {
      log('📱 Sending $operationType SMS to: $phoneNumber');

      final requestBody = {
        'source_addr': _senderId,
        'encoding': 0, // NUMBER
        'message': message,
        'recipients': [
          {
            'recipient_id': 1, // NUMBER (can also be string)
            'dest_addr': phoneNumber,
          }
        ],
      };

      log('Request body: ${jsonEncode(requestBody)}');

      final response = await _dio
          .post(
        _apiEndpoint,
        data: requestBody,
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          log('❌ SMS request timeout for $operationType');
          throw Exception('SMS request timeout');
        },
      );

      log('Response status: ${response.statusCode}');
      log('Response body: ${response.data}');

      // API returns 200 on success
      if (response.statusCode == 200) {
        try {
          final responseData = response.data;

          // Check if 'successful' field exists and is true
          if (responseData['successful'] == true) {
            log('✅ $operationType SMS sent successfully!');
            log('Valid: ${responseData['valid']}, Request ID: ${responseData['request_id']}');
            return true;
          } else if (responseData['code'] != null) {
            log('❌ $operationType SMS failed: ${responseData['message']}');
            log('Code: ${responseData['code']}');
            return false;
          } else {
            // Empty response body - treat as processing
            log('⚠️  $operationType SMS returned status ${response.statusCode} with empty body');
            log('SMS may have been processed. Check delivery reports.');
            return true; // Optimistically assume it was sent
          }
        } catch (e) {
          log('❌ Error parsing SMS response: $e');
          return false;
        }
      } else {
        log('❌ SMS API returned unexpected status code: ${response.statusCode}');
        return false;
      }
    } on DioException catch (e) {
      log('❌ Dio error during SMS sending: ${e.message}');
      log('Status: ${e.response?.statusCode}');
      log('Response: ${e.response?.data}');
      return false;
    } catch (e) {
      log('❌ Exception during SMS sending: $e');
      return false;
    }
  }
}
