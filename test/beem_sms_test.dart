import 'package:flutter_test/flutter_test.dart';
import 'package:smart_chaja/utils/beem_sms_test_helper.dart';

void main() {
  group('Beem SMS Service Tests', () {
    test('Send Power Bank Rental SMS', () async {
      print('📋 Testing Power Bank Rental SMS\n');

      BeemSmsTestHelper.printMessagePreview(
        phoneNumber: '0778412125',
        userName: 'Test User',
        deviceId: 'PB-001',
        tradeNo: 'TEST123456',
      );

      print('\n⏳ Sending Rental SMS...\n');
      await BeemSmsTestHelper.testSendRentalSMS(
        phoneNumber: '0778412125',
        userName: 'Test User',
        deviceId: 'PB-001',
        tradeNo: 'TEST123456',
      );
    });

    test('Send Power Bank Return SMS', () async {
      print('📋 Testing Power Bank Return SMS\n');

      print('\n⏳ Sending Return SMS...\n');
      await BeemSmsTestHelper.testSendReturnSMS(
        phoneNumber: '0778412125',
        userName: 'Test User',
        deviceId: 'PB-001',
        tradeNo: 'TEST123456',
      );
    });

    test('Send Both SMS Types', () async {
      print('📋 Testing Both SMS Types\n');

      print('\n⏳ Sending both SMS messages...\n');
      await BeemSmsTestHelper.testBothSMS(
        phoneNumber: '0778412125',
        userName: 'Test User',
        deviceId: 'PB-001',
        tradeNo: 'TEST123456',
      );
    });
  });
}
