/// Utility for validating and formatting MSISDN (mobile phone numbers)
/// for Vodacom M-Pesa API integration
///
/// MSISDN Format Requirements (per Vodacom API):
/// - Must be 12-14 digits
/// - Must start with country code (no + prefix, no leading 0)
/// - Pattern: ^[0-9]{12,14}$
///
/// Examples:
/// Input: "0712345678" → Output: "255712345678" (Tanzania)
/// Input: "+255712345678" → Output: "255712345678"
/// Input: "255712345678" → Output: "255712345678"
/// Input: "254707161122" → Output: "254707161122" (Kenya - already correct)

class MsisdnFormatter {
  /// Country code mapping for East Africa
  static const Map<String, String> countryCodes = {
    'TZN': '255', // Tanzania
    'KEN': '254', // Kenya
    'UGA': '256', // Uganda
    'RWA': '250', // Rwanda
    'BDI': '257', // Burundi
  };

  /// Tanzania-specific mapping for Vodacom
  static const String tanzaniaCountryCode = '255';
  static const String tanzaniaMobilePrefix = '0'; // Removed to form MSISDN

  /// Validates if a phone number is in valid MSISDN format
  ///
  /// Args:
  ///   msisdn: Phone number to validate (any format)
  ///   countryCode: Optional country code (if null, assumes Tanzania 255)
  ///
  /// Returns:
  ///   true if valid MSISDN format (12-14 digits), false otherwise
  static bool isValidMsisdn(String msisdn, {String? countryCode}) {
    if (msisdn.isEmpty) return false;

    // Remove common formatting characters
    final cleaned = msisdn.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');

    // Check if valid
    final isValid = RegExp(r'^[0-9]{12,14}$').hasMatch(cleaned);

    return isValid;
  }

  /// Formats any phone number format to valid MSISDN format
  ///
  /// Handles:
  /// - Local format: "0712345678" (Tanzania) → "255712345678"
  /// - International with +: "+255712345678" → "255712345678"
  /// - International without +: "255712345678" → "255712345678" (no-op)
  /// - Already valid: "254707161122" → "254707161122" (Kenya)
  ///
  /// Args:
  ///   phoneNumber: Any format phone number
  ///   countryCode: Optional country code (defaults to Tanzania 255)
  ///
  /// Returns:
  ///   Valid MSISDN format (12-14 digits) or null if invalid
  ///
  /// Throws:
  ///   FormatException if phone number cannot be formatted to valid MSISDN
  static String formatToMsisdn(
    String phoneNumber, {
    String countryCode = tanzaniaCountryCode,
  }) {
    if (phoneNumber.isEmpty) {
      throw FormatException('Phone number cannot be empty');
    }

    // Step 1: Remove all formatting characters
    String cleaned = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');

    print('[MSISDN] Input: "$phoneNumber" → Cleaned: "$cleaned"');

    // Step 2: Handle leading zero (local format)
    // If it starts with 0 and isn't already a valid international format
    if (cleaned.startsWith('0') &&
        !cleaned.startsWith('0$countryCode') &&
        cleaned.length == 10) {
      // Local format like "0712345678" → "712345678"
      cleaned = cleaned.substring(1);
      print('[MSISDN] Removed leading zero: "$cleaned"');
    }

    // Step 3: Add country code if not present
    if (!cleaned.startsWith(countryCode)) {
      // Check if it's already another valid country code
      bool isAnotherCountryCode = false;
      for (var code in countryCodes.values) {
        if (cleaned.startsWith(code) && code != countryCode) {
          isAnotherCountryCode = true;
          print('[MSISDN] Detected alternate country code: $code');
          break;
        }
      }

      // If not another country code, add the default one
      if (!isAnotherCountryCode) {
        cleaned = countryCode + cleaned;
        print('[MSISDN] Added country code: "$cleaned"');
      }
    }

    // Step 4: Validate final format
    if (!isValidMsisdn(cleaned)) {
      throw FormatException(
        'Invalid MSISDN format. Expected 12-14 digits, got: "$cleaned" (${cleaned.length} digits)',
      );
    }

    print('[MSISDN] Final MSISDN: "$cleaned"');
    return cleaned;
  }

  /// Formats MSISDN for display (e.g., in UI)
  ///
  /// Example: "255712345678" → "+255 712 345 678"
  static String formatForDisplay(String msisdn) {
    if (!isValidMsisdn(msisdn)) {
      return msisdn; // Return as-is if invalid
    }

    // Remove any existing formatting
    final cleaned = msisdn.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Format with country code
    if (cleaned.startsWith('255')) {
      // Tanzania format
      final withoutCountry = cleaned.substring(3);
      return '+255 ${withoutCountry.substring(0, 3)} ${withoutCountry.substring(3, 6)} ${withoutCountry.substring(6)}';
    } else if (cleaned.startsWith('254')) {
      // Kenya format
      final withoutCountry = cleaned.substring(3);
      return '+254 ${withoutCountry.substring(0, 3)} ${withoutCountry.substring(3, 6)} ${withoutCountry.substring(6)}';
    }

    // Generic format for other countries
    final leadingCode = cleaned.substring(0, 3);
    final remaining = cleaned.substring(3);
    return '+$leadingCode ${remaining.substring(0, remaining.length ~/ 2)} ${remaining.substring(remaining.length ~/ 2)}';
  }

  /// Validates Tanzania-specific phone numbers
  ///
  /// Accepts:
  /// - "0712345678" (local format)
  /// - "255712345678" (international format)
  /// - "+255712345678" (international with +)
  ///
  /// Tanzanian mobile operators: Vodacom (0747/0748/0749), Tigo (0655/0656/0657),
  /// Airtel (0789/0788), TTCL (0744/0745), Zantel (0774/0775)
  static bool isValidTanzanianNumber(String phoneNumber) {
    try {
      final msisdn =
          formatToMsisdn(phoneNumber, countryCode: tanzaniaCountryCode);

      // Check if it starts with Tanzania country code
      if (!msisdn.startsWith(tanzaniaCountryCode)) {
        return false;
      }

      // Check length
      if (msisdn.length < 12 || msisdn.length > 14) {
        return false;
      }

      return true;
    } catch (e) {
      print('[MSISDN] Validation error: $e');
      return false;
    }
  }

  /// Gets user-friendly error message for invalid phone numbers
  static String getErrorMessage(String phoneNumber) {
    if (phoneNumber.isEmpty) {
      return 'Phone number cannot be empty';
    }

    final cleaned = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');

    if (cleaned.length < 9) {
      return 'Phone number too short (minimum 9 digits)';
    }

    if (cleaned.length > 15) {
      return 'Phone number too long (maximum 15 digits)';
    }

    if (cleaned.contains(RegExp(r'[a-zA-Z]'))) {
      return 'Phone number contains invalid characters';
    }

    try {
      formatToMsisdn(phoneNumber);
      return 'Phone number format is invalid';
    } catch (e) {
      return e.toString();
    }
  }
}
