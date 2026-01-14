import 'package:smart_chaja/authentication/beemafrica_service.dart/beem_sms_service.dart';
import 'dart:developer';

/// Test utility for SMS functionality
/// Use this to test sending SMS messages via Beem Africa API
class BeemSmsTestHelper {
  static final _smsService = BeemSmsService();

  /// Test sending a power bank rental SMS
  /// This will send an actual SMS to the provided phone number
  static Future<void> testSendRentalSMS({
    String phoneNumber = '0778412125',
    String userName = 'Test User',
    String deviceId = 'PB-001',
    String tradeNo = 'TEST123456',
  }) async {
    log('🧪 Testing Power Bank Rental SMS...');
    log('Phone: $phoneNumber');
    log('User: $userName');
    log('Device: $deviceId');
    log('Trade No: $tradeNo');

    try {
      final result = await _smsService.sendPowerBankRentalSMS(
        phoneNumber: phoneNumber,
        userName: userName,
        deviceId: deviceId,
        tradeNo: tradeNo,
      );

      if (result) {
        log('✅ TEST PASSED: Rental SMS sent successfully!');
      } else {
        log('❌ TEST FAILED: Rental SMS sending failed!');
      }
    } catch (e) {
      log('❌ TEST ERROR: ${e.toString()}');
    }
  }

  /// Test sending a power bank return SMS
  /// This will send an actual SMS to the provided phone number
  static Future<void> testSendReturnSMS({
    String phoneNumber = '0778412125',
    String userName = 'Test User',
    String deviceId = 'PB-001',
    String tradeNo = 'TEST123456',
  }) async {
    log('🧪 Testing Power Bank Return SMS...');
    log('Phone: $phoneNumber');
    log('User: $userName');
    log('Device: $deviceId');
    log('Trade No: $tradeNo');

    try {
      final result = await _smsService.sendPowerBankReturnSMS(
        phoneNumber: phoneNumber,
        userName: userName,
        deviceId: deviceId,
        tradeNo: tradeNo,
      );

      if (result) {
        log('✅ TEST PASSED: Return SMS sent successfully!');
      } else {
        log('❌ TEST FAILED: Return SMS sending failed!');
      }
    } catch (e) {
      log('❌ TEST ERROR: ${e.toString()}');
    }
  }

  /// Test both SMS types
  static Future<void> testBothSMS({
    String phoneNumber = '0778412125',
    String userName = 'Test User',
    String deviceId = 'PB-001',
    String tradeNo = 'TEST123456',
  }) async {
    log('🧪 Starting comprehensive SMS tests...');
    log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    // Test rental SMS
    await testSendRentalSMS(
      phoneNumber: phoneNumber,
      userName: userName,
      deviceId: deviceId,
      tradeNo: tradeNo,
    );

    await Future.delayed(const Duration(seconds: 2));

    log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    // Test return SMS
    await testSendReturnSMS(
      phoneNumber: phoneNumber,
      userName: userName,
      deviceId: deviceId,
      tradeNo: tradeNo,
    );

    log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    log('✅ All tests completed!');
  }

  /// Get preview of the messages that will be sent
  static void printMessagePreview({
    String phoneNumber = '0778412125',
    String userName = 'Test User',
    String deviceId = 'PB-001',
    String tradeNo = 'TEST123456',
  }) {
    log('📱 MESSAGE PREVIEW');
    log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    log('Phone Number: $phoneNumber');
    log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    final rentalMessage =
        'Hi $userName, your power bank rental ($deviceId) has been activated successfully. Trade No: $tradeNo. Visit SmartChaja for support.';
    log('Rental Message:');
    log(rentalMessage);

    log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    final returnMessage =
        'Hi $userName, your power bank ($deviceId) has been returned successfully. Trade No: $tradeNo. Thank you for using SmartChaja!';
    log('Return Message:');
    log(returnMessage);

    log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }
}
