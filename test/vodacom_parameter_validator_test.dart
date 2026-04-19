import 'package:flutter_test/flutter_test.dart';
import 'package:smart_chaja/features/chargenow_devices/payment/vodacom/utils/vodacom_parameter_validator.dart';

void main() {
  group('Vodacom Parameter Validator', () {
    group('Amount Validation', () {
      test('Valid numeric amount', () {
        final result = VodacomParameterValidator.validateAmount('5000');
        expect(result.isValid, isTrue);
      });

      test('Valid amount with decimal', () {
        final result = VodacomParameterValidator.validateAmount('5000.50');
        expect(result.isValid, isTrue);
      });

      test('Invalid - empty string', () {
        final result = VodacomParameterValidator.validateAmount('');
        expect(result.isValid, isFalse);
        expect(result.error, contains('empty'));
      });

      test('Invalid - alphabetic characters', () {
        final result = VodacomParameterValidator.validateAmount('5000 TZS');
        expect(result.isValid, isFalse);
        expect(result.error, contains('numeric'));
      });

      test('Invalid - negative number', () {
        final result = VodacomParameterValidator.validateAmount('-5000');
        expect(result.isValid, isFalse);
        expect(result.error, contains('greater than 0'));
      });

      test('Invalid - zero', () {
        final result = VodacomParameterValidator.validateAmount('0');
        expect(result.isValid, isFalse);
        expect(result.error, contains('greater than 0'));
      });
    });

    group('Service Provider Code Validation', () {
      test('Valid code - minimum length', () {
        final result =
            VodacomParameterValidator.validateServiceProviderCode('ORG1');
        expect(result.isValid, isTrue);
      });

      test('Valid code - maximum length', () {
        final result = VodacomParameterValidator.validateServiceProviderCode(
            'ORG123456789');
        expect(result.isValid, isTrue);
      });

      test('Valid code - numeric only', () {
        final result =
            VodacomParameterValidator.validateServiceProviderCode('123456789');
        expect(result.isValid, isTrue);
      });

      test('Invalid - too short', () {
        final result =
            VodacomParameterValidator.validateServiceProviderCode('ORG');
        expect(result.isValid, isFalse);
        expect(result.error, contains('too short'));
      });

      test('Invalid - too long', () {
        final result = VodacomParameterValidator.validateServiceProviderCode(
            'ORG1234567890');
        expect(result.isValid, isFalse);
        expect(result.error, contains('too long'));
      });

      test('Invalid - contains special characters', () {
        final result =
            VodacomParameterValidator.validateServiceProviderCode('ORG-001');
        expect(result.isValid, isFalse);
        expect(result.error, contains('invalid characters'));
      });

      test('Invalid - empty', () {
        final result =
            VodacomParameterValidator.validateServiceProviderCode('');
        expect(result.isValid, isFalse);
      });
    });

    group('Transaction Reference Validation', () {
      test('Valid - alphanumeric', () {
        final result =
            VodacomParameterValidator.validateTransactionReference('T12344C');
        expect(result.isValid, isTrue);
      });

      test('Valid - with underscore', () {
        final result =
            VodacomParameterValidator.validateTransactionReference('TXN_001');
        expect(result.isValid, isTrue);
      });

      test('Valid - with space', () {
        final result =
            VodacomParameterValidator.validateTransactionReference('TX 001');
        expect(result.isValid, isTrue);
      });

      test('Invalid - too long', () {
        final result = VodacomParameterValidator.validateTransactionReference(
            'T1234567890123456789012');
        expect(result.isValid, isFalse);
        expect(result.error, contains('too long'));
      });

      test('Invalid - special characters', () {
        final result =
            VodacomParameterValidator.validateTransactionReference('TX-001');
        expect(result.isValid, isFalse);
        expect(result.error, contains('invalid characters'));
      });

      test('Invalid - empty', () {
        final result =
            VodacomParameterValidator.validateTransactionReference('');
        expect(result.isValid, isFalse);
      });
    });

    group('Third Party Conversation ID Validation', () {
      test('Valid - UUID format', () {
        final result =
            VodacomParameterValidator.validateThirdPartyConversationID(
          '1e9b774d1da34af78412a498cbc28f5e',
        );
        expect(result.isValid, isTrue);
      });

      test('Valid - alphanumeric', () {
        final result =
            VodacomParameterValidator.validateThirdPartyConversationID(
                'ABC123XYZ');
        expect(result.isValid, isTrue);
      });

      test('Valid - with underscore', () {
        final result =
            VodacomParameterValidator.validateThirdPartyConversationID(
                'USER_123_TIMESTAMP');
        expect(result.isValid, isTrue);
      });

      test('Invalid - too long', () {
        final result =
            VodacomParameterValidator.validateThirdPartyConversationID(
          'A' * 50,
        );
        expect(result.isValid, isFalse);
        expect(result.error, contains('too long'));
      });

      test('Invalid - special characters', () {
        final result =
            VodacomParameterValidator.validateThirdPartyConversationID(
                'USER@123');
        expect(result.isValid, isFalse);
      });

      test('Invalid - empty', () {
        final result =
            VodacomParameterValidator.validateThirdPartyConversationID('');
        expect(result.isValid, isFalse);
      });
    });

    group('Purchased Items Description Validation', () {
      test('Valid - simple text', () {
        final result = VodacomParameterValidator.validatePurchasedItemsDesc(
            'Test Payment');
        expect(result.isValid, isTrue);
      });

      test('Valid - with comma', () {
        final result = VodacomParameterValidator.validatePurchasedItemsDesc(
            'Item 1, Item 2');
        expect(result.isValid, isTrue);
      });

      test('Valid - with underscore', () {
        final result = VodacomParameterValidator.validatePurchasedItemsDesc(
            'DESC_123_PAYMENT');
        expect(result.isValid, isTrue);
      });

      test('Invalid - too long', () {
        final result =
            VodacomParameterValidator.validatePurchasedItemsDesc('A' * 300);
        expect(result.isValid, isFalse);
        expect(result.error, contains('too long'));
      });

      test('Invalid - special characters', () {
        final result =
            VodacomParameterValidator.validatePurchasedItemsDesc('Item@#\$%');
        expect(result.isValid, isFalse);
      });

      test('Invalid - empty', () {
        final result = VodacomParameterValidator.validatePurchasedItemsDesc('');
        expect(result.isValid, isFalse);
      });
    });

    group('All Parameters Validation', () {
      test('All valid parameters', () {
        final result = VodacomParameterValidator.validateAllParameters(
          amount: '5000',
          serviceProviderCode: 'ORG001',
          transactionReference: 'T12344C',
          thirdPartyConversationId: '1e9b774d1da34af78412a498cbc28f5e',
          purchasedItemsDesc: 'Test Payment',
          country: 'TZN',
          currency: 'TZS',
        );
        expect(result, isTrue);
      });

      test('Invalid amount fails validation', () {
        final result = VodacomParameterValidator.validateAllParameters(
          amount: 'invalid',
          serviceProviderCode: 'ORG001',
          transactionReference: 'T12344C',
          thirdPartyConversationId: '1e9b774d',
          purchasedItemsDesc: 'Test',
        );
        expect(result, isFalse);
      });

      test('Invalid service provider code fails validation', () {
        final result = VodacomParameterValidator.validateAllParameters(
          amount: '5000',
          serviceProviderCode: 'AB', // Too short
          transactionReference: 'T12344C',
          thirdPartyConversationId: '1e9b774d',
          purchasedItemsDesc: 'Test',
        );
        expect(result, isFalse);
      });
    });

    group('Get All Validation Errors', () {
      test('Returns all errors for invalid parameters', () {
        final errors = VodacomParameterValidator.getAllValidationErrors(
          amount: 'invalid',
          serviceProviderCode: 'AB',
          transactionReference: '',
          thirdPartyConversationId: '',
          purchasedItemsDesc: '',
        );
        expect(errors.length, greaterThan(0));
        expect(errors[0], contains('Amount'));
      });

      test('Returns empty list for valid parameters', () {
        final errors = VodacomParameterValidator.getAllValidationErrors(
          amount: '5000',
          serviceProviderCode: 'ORG001',
          transactionReference: 'T12344C',
          thirdPartyConversationId: 'conv123',
          purchasedItemsDesc: 'Payment',
        );
        expect(errors.isEmpty, isTrue);
      });
    });

    group('Real-World Test Cases', () {
      test('Typical payment flow parameters', () {
        final result = VodacomParameterValidator.validateAllParameters(
          amount: '10000',
          serviceProviderCode: 'SHOP001',
          transactionReference: 'ORD_2026_001',
          thirdPartyConversationId:
              DateTime.now().millisecondsSinceEpoch.toString(),
          purchasedItemsDesc: 'Online Purchase',
        );
        expect(result, isTrue);
      });

      test('Detect Invalid Use Case - missing service provider', () {
        final codeResult =
            VodacomParameterValidator.validateServiceProviderCode('');
        expect(codeResult.isValid, isFalse);
        print('Error: ${codeResult.error}');
        print('This could cause "Invalid Use Case" error from Vodacom API');
      });

      test('Detect Invalid Use Case - invalid transaction ref', () {
        final refResult =
            VodacomParameterValidator.validateTransactionReference(
                'TX/2024/001');
        expect(refResult.isValid, isFalse);
        print('Error: ${refResult.error}');
        print('This could cause "Invalid Use Case" error from Vodacom API');
      });
    });
  });
}

/// HOW TO USE THIS TEST FILE:
///
/// 1. Update the import path to match your app's package name:
///    Change: import 'package:your_app/...'
///    To: import 'package:chaja_app/...'
///
/// 2. Run all tests:
///    flutter test test/vodacom_parameter_validator_test.dart
///
/// 3. Run specific test group:
///    flutter test test/vodacom_parameter_validator_test.dart -k "Amount"
///
/// 4. Run with verbose output:
///    flutter test test/vodacom_parameter_validator_test.dart -v
///
/// TEST COVERAGE:
/// ✓ Amount validation (numeric, decimal, zero, negative)
/// ✓ Service provider code (length, alphanumeric, special chars)
/// ✓ Transaction reference (length, valid chars, special chars)
/// ✓ Third party conversation ID (length, alphanumeric)
/// ✓ Purchased items description (length, valid chars)
/// ✓ All parameters validation
/// ✓ Error collection
/// ✓ Real-world test cases
///
/// OUTCOME:
/// If any test fails, it means one of your parameters doesn't match
/// the Vodacom API requirements, which could cause "Invalid Use Case" error
