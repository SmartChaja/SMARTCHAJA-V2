/// A utility class for validating Tanzanian mobile numbers against specific carriers.
///
/// It includes special validation logic for Azampesa and robust normalization
/// for all standard carriers to handle various user input formats.
class MobileNumberValidator {
  /// A map of mobile carriers and their corresponding prefixes.
  static final Map<String, List<String>> _carriers = {
    'Airtel': ['078', '068', '069'],
    'Tigo': ['071', '065', '067'],
    'Halopesa': ['061', '062'],
    'Mpesa': ['075', '076', '074'],
    'TTCL': ['073'],
    'Zantel': ['077'],
    // Azampesa uses special, non-standard prefixes.
    'Azampesa': [
      '178', '168', '169', '171', '165', '167',
      '161', '162', '175', '176', '174'
    ],
  };

  /// Normalizes a mobile number to the standard format for API submission.
  ///
  /// This is a public method that can be used to get the normalized number
  /// before sending it to the API.
  ///
  /// [mobileNumber] The phone number string to normalize.
  /// [selectedProvider] The carrier name (needed for Azampesa special handling).
  ///
  /// Returns the normalized phone number string.
  static String normalizeForApi(String mobileNumber, String selectedProvider) {
    if (selectedProvider == 'Azampesa') {
      // Azampesa just needs digits
      return mobileNumber.replaceAll(RegExp(r'[^\d]'), '');
    }
    return _normalizeNumber(mobileNumber);
  }

  /// Validates a mobile number for a specific provider.
  ///
  /// This method correctly handles formats like:
  /// - `0786112616`
  /// - `+255786112616`
  /// - `255786112616`
  /// - `+2550786112616` (handles redundant '0')
  /// - `786112616`
  /// - `+255 78 611 2616` (with spaces)
  /// - `+255-786-112-616` (with dashes)
  ///
  /// [mobileNumber] The phone number string to validate.
  /// [selectedProvider] The carrier name (e.g., 'Airtel', 'Azampesa').
  ///
  /// Returns `true` if the number is valid for the given provider, otherwise `false`.
  static bool validateMobileNumber(
      String mobileNumber, String selectedProvider) {
    final List<String> prefixes = _carriers[selectedProvider] ?? [];

    if (prefixes.isEmpty) {
      return false; // Provider not found or has no prefixes.
    }

    // --- Special Validation Logic for Azampesa ---
    if (selectedProvider == 'Azampesa') {
      final String sanitizedNumber = mobileNumber.replaceAll(RegExp(r'[^\d]'), '');
      return prefixes.any((prefix) => sanitizedNumber.startsWith(prefix));
    }

    // --- Standard Validation Logic for all other carriers ---
    final String normalizedNumber = _normalizeNumber(mobileNumber);

    // Check if the number is a valid 10-digit format AND
    // starts with one of the provider's prefixes.
    return RegExp(r'^0\d{9}$').hasMatch(normalizedNumber) &&
        prefixes.any((prefix) => normalizedNumber.startsWith(prefix));
  }

  /// Normalizes a phone number to the standard local Tanzanian format `0XXXXXXXXX`.
  ///
  /// This function is designed to handle multiple common input formats robustly.
  ///
  /// [mobileNumber] The raw phone number string.
  /// Returns a normalized number string.
  static String _normalizeNumber(String mobileNumber) {
    // Step 1: Remove ALL non-digit characters (including +, spaces, dashes, etc.)
    String sanitized = mobileNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    // Step 2: Handle numbers with country code '255'
    if (sanitized.startsWith('255')) {
      sanitized = sanitized.substring(3);
      
      // Step 3: Remove redundant leading zeros after country code
      // Handles: 2550786112616 -> 0786112616 -> 786112616
      while (sanitized.length > 9 && sanitized.startsWith('0')) {
        sanitized = sanitized.substring(1);
      }
    }

    // Step 4: Ensure we have exactly 9 or 10 digits at this point
    // If 9 digits starting with 6 or 7, add leading 0
    if (sanitized.length == 9) {
      if (sanitized.startsWith('7') || sanitized.startsWith('6')) {
        return '0$sanitized';
      }
    }
    
    // If already 10 digits starting with 0, return as-is
    if (sanitized.length == 10 && sanitized.startsWith('0')) {
      return sanitized;
    }

    // Return sanitized (let validator regex catch invalid formats)
    return sanitized;
  }
}
