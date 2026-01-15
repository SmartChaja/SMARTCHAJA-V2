import 'lib/utils/beem_sms_test_helper.dart';

void main() async {
  print('Testing Reminder SMS...');
  await BeemSmsTestHelper.testSendReminderSMS(
    phoneNumber: '0778412125',
    userName: 'Tester',
    deviceId: 'PB-001',
    tradeNo: 'TEST-REM-001',
  );
}
