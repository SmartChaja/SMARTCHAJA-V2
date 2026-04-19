import 'package:flutter_test/flutter_test.dart';
import 'package:your_app/features/chargenow_devices/payment/vodacom/utils/msisdn_formatter.dart';

void main() {
  group('MSISDN Formatter Tests', () {
    test('Test 1: Validate local Tanzania format with leading 0', () {
      // Input: Local format like 0712345678
      const localNumber = '0712345678';

      // Should format to full MSISDN
      final formatted = MsisdnFormatter.formatToMsisdn(localNumber);

      // Should have country code prepended
      expect(formatted, equals('255712345678'));
      expect(formatted.length, equals(12));
    });

    test('Test 2: Validate international format with +', () {
      // Input: International format with + prefix
      const intlNumber = '+255712345678';

      // Should remove + and use as-is
      final formatted = MsisdnFormatter.formatToMsisdn(intlNumber);

      // Should be 12 digits without +
      expect(formatted, equals('255712345678'));
      expect(formatted.length, equals(12));
    });

    test('Test 3: Validate already-formatted MSISDN', () {
      // Input: Already in correct format
      const msisdn = '255712345678';

      // Should return unchanged
      final formatted = MsisdnFormatter.formatToMsisdn(msisdn);

      expect(formatted, equals('255712345678'));
      expect(formatted.length, equals(12));
    });

    test('Test 4: Validate with spaces and dashes', () {
      // Input: With formatting characters
      const formatted_number = '+255 712-345-678';

      // Should remove all formatting
      final formatted = MsisdnFormatter.formatToMsisdn(formatted_number);

      expect(formatted, equals('255712345678'));
    });

    test('Test 5: Detect invalid format - too short', () {
      // Input: Too few digits
      const shortNumber = '071234';

      // Should throw FormatException
      expect(
        () => MsisdnFormatter.formatToMsisdn(shortNumber),
        throwsA(isA<FormatException>()),
      );
    });

    test('Test 6: Detect invalid format - too long', () {
      // Input: Too many digits
      const longNumber = '25571234567890123456';

      // Should throw FormatException
      expect(
        () => MsisdnFormatter.formatToMsisdn(longNumber),
        throwsA(isA<FormatException>()),
      );
    });

    test('Test 7: Detect invalid format - contains letters', () {
      // Input: Contains letters
      const invalidNumber = '071ABC5678';

      // Should throw FormatException
      expect(
        () => MsisdnFormatter.formatToMsisdn(invalidNumber),
        throwsA(isA<FormatException>()),
      );
    });

    test('Test 8: Validate Kenya number format', () {
      // Input: Kenya format (country code 254)
      const kenyaNumber = '254707161122';

      // Should recognize as valid different country code
      final formatted = MsisdnFormatter.formatToMsisdn(
        kenyaNumber,
        countryCode: '254',
      );

      expect(formatted, equals('254707161122'));
      expect(formatted.length, equals(12));
    });

    test('Test 9: Format for display', () {
      // Input: Valid MSISDN
      const msisdn = '255712345678';

      // Should format with spaces and +
      final displayFormat = MsisdnFormatter.formatForDisplay(msisdn);

      // Should contain appropriate formatting
      expect(displayFormat, contains('+255'));
      expect(displayFormat, contains(' '));
    });

    test('Test 10: Validate Tanzania-specific number', () {
      // Test various Tanzania formats
      final testCases = [
        '0712345678', // Local format
        '255712345678', // International
        '+255712345678', // With +
        '0747111222', // Vodacom
        '+255747111222', // Vodacom with +
      ];

      for (var number in testCases) {
        final isValid = MsisdnFormatter.isValidTanzanianNumber(number);
        expect(isValid, isTrue, reason: 'Should validate: $number');
      }
    });

    test('Test 11: Reject invalid Tanzania numbers', () {
      // Test invalid formats
      final invalidCases = [
        '071234', // Too short
        '25571234567890', // Too long
        '254712345678', // Wrong country code
        '0712ABC5678', // Contains letters
      ];

      for (var number in invalidCases) {
        final isValid = MsisdnFormatter.isValidTanzanianNumber(number);
        expect(isValid, isFalse, reason: 'Should reject: $number');
      }
    });

    test('Test 12: Get error message for invalid format', () {
      // Test error messages
      expect(
        MsisdnFormatter.getErrorMessage(''),
        contains('empty'),
      );

      expect(
        MsisdnFormatter.getErrorMessage('0712'),
        contains('too short'),
      );

      expect(
        MsisdnFormatter.getErrorMessage('25571234567890123456'),
        contains('too long'),
      );

      expect(
        MsisdnFormatter.getErrorMessage('071ABC5678'),
        contains('invalid characters'),
      );
    });

    test('Test 13: Operator-specific numbers - Vodacom', () {
      // Vodacom Tanzania prefixes: 0747, 0748, 0749
      final vodacomNumbers = [
        '0747111222',
        '0748333444',
        '0749555666',
      ];

      for (var number in vodacomNumbers) {
        final formatted = MsisdnFormatter.formatToMsisdn(number);
        expect(formatted.startsWith('2557'), isTrue,
            reason: 'Should have Tanzania country code');
        expect(formatted.length, equals(12));
      }
    });

    test('Test 14: Operator-specific numbers - Tigo', () {
      // Tigo Tanzania prefixes: 0655, 0656, 0657
      final tigoNumbers = [
        '0655111222',
        '0656333444',
        '0657555666',
      ];

      for (var number in tigoNumbers) {
        final formatted = MsisdnFormatter.formatToMsisdn(number);
        expect(formatted.startsWith('2556'), isTrue,
            reason: 'Should convert correctly');
        expect(formatted.length, equals(12));
      }
    });

    test('Test 15: Real-world edge cases', () {
      // Test realistic edge cases
      const testCases = {
        '+255 (747) 123-4567': '255747123456',
        '255-712-345-678': '255712345678',
        '( 0 ) 7 1 2 3 4 5 6 7 8': '255712345678',
      };

      for (var entry in testCases.entries) {
        try {
          final formatted = MsisdnFormatter.formatToMsisdn(entry.key);
          // Just verify it formats without throwing
          expect(formatted.startsWith('255'), isTrue);
          expect(formatted.length, greaterThanOrEqualTo(12));
          expect(formatted.length, lessThanOrEqualTo(14));
        } catch (e) {
          fail('Should handle: ${entry.key}, error: $e');
        }
      }
    });
  });

  group('MSISDN Validation', () {
    test('isValidMsisdn returns true for valid formats', () {
      const validFormats = [
        '255712345678',
        '254707161122',
        '25571234567890',
      ];

      for (var msisdn in validFormats) {
        expect(
          MsisdnFormatter.isValidMsisdn(msisdn),
          isTrue,
          reason: 'Should validate: $msisdn',
        );
      }
    });

    test('isValidMsisdn returns false for invalid formats', () {
      const invalidFormats = [
        '0712345678', // Has leading 0
        '+255712345678', // Has + prefix
        '255712', // Too short
        '25571234567890123456', // Too long
        '255ABC345678', // Contains letters
      ];

      for (var msisdn in invalidFormats) {
        expect(
          MsisdnFormatter.isValidMsisdn(msisdn),
          isFalse,
          reason: 'Should reject: $msisdn',
        );
      }
    });
  });
}

/// HOW TO RUN THESE TESTS:
///
/// 1. Update import in this file to match your app package name:
///    Change: import 'package:your_app/...'
///    To: import 'package:chaja_app/...' (or your actual package)
///
/// 2. Run all tests:
///    flutter test test/msisdn_formatter_test.dart
///
/// 3. Run specific test:
///    flutter test test/msisdn_formatter_test.dart -k "Test 1"
///
/// 4. Run with verbose output:
///    flutter test test/msisdn_formatter_test.dart -v
///
/// TEST COVERAGE:
/// ✓ Local format to MSISDN conversion
/// ✓ International format handling
/// ✓ Already-formatted MSISDN acceptance
/// ✓ Special character removal
/// ✓ Invalid length detection
/// ✓ Letter character detection
/// ✓ Alternative country codes
/// ✓ Display formatting
/// ✓ Tanzania-specific validation
/// ✓ Invalid Tanzania numbers rejection
/// ✓ Error message generation
/// ✓ Operator-specific prefixes (Vodacom, Tigo)
/// ✓ Real-world edge cases
///
/// EXPECTED RESULTS:
/// All 30+ assertions should PASS
/// No test should fail
/// Execution time < 1 second
