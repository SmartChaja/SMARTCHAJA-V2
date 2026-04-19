/// Validator for Vodacom C2B Payment API parameters
/// Validates all request parameters against Vodacom M-Pesa API requirements
///
/// API Documentation Reference:
/// https://developer.vodacom.co.tz/mpesa-api-documentation
///
/// All parameters must match their regex patterns:
/// - input_Amount: ^\d*\.?\d+$ (numeric)
/// - input_ServiceProviderCode: ^([0-9A-Za-z]{4,12})$ (4-12 alphanumeric)
/// - input_TransactionReference: ^[0-9a-zA-Z \w+]{1,20}$ (1-20 chars)
/// - input_ThirdPartyConversationID: ^[0-0a-zA-Z \w+]{1,40}$ (1-40 chars)
/// - input_PurchasedItemsDesc: ^[0-9a-zA-Z \w+]{1,256}$ (1-256 chars)
/// - input_Country: Required (e.g., TZN)
/// - input_Currency: Required (e.g., TZS)

class VodacomParameterValidator {
  /// Validates amount parameter
  /// Pattern: ^\d*\.?\d+$ (numeric, decimal allowed)
  /// Examples that PASS: "10", "10.50", "5000", "0.01"
  /// Examples that FAIL: "abc", "10 TZS", "", "-10"
  static ValidationResult validateAmount(String amount) {
    if (amount.isEmpty) {
      return ValidationResult(
        isValid: false,
        error: 'Amount cannot be empty',
        example: '5000 or 5000.50',
      );
    }

    if (!RegExp(r'^\d*\.?\d+$').hasMatch(amount)) {
      return ValidationResult(
        isValid: false,
        error: 'Amount must be numeric (can have decimal point)',
        example: '5000 or 5000.50',
        invalid: amount,
      );
    }

    final amountValue = double.tryParse(amount) ?? 0;
    if (amountValue <= 0) {
      return ValidationResult(
        isValid: false,
        error: 'Amount must be greater than 0',
        example: '5000 or 5000.50',
        invalid: amount,
      );
    }

    return ValidationResult(isValid: true);
  }

  /// Validates service provider code parameter
  /// Pattern: ^([0-9A-Za-z]{4,12})$ (4-12 alphanumeric)
  /// Examples that PASS: "ORG001", "ABC1234", "12345", "SHOP"
  /// Examples that FAIL: "ORG", "ORG-123", "ORG 001", "TOO_LONG_CODE"
  static ValidationResult validateServiceProviderCode(String code) {
    if (code.isEmpty) {
      return ValidationResult(
        isValid: false,
        error: 'Service Provider Code cannot be empty',
        example: 'ORG001 (4-12 alphanumeric)',
      );
    }

    if (code.length < 4) {
      return ValidationResult(
        isValid: false,
        error: 'Service Provider Code too short (minimum 4 characters)',
        example: 'ORG001 (4-12 alphanumeric)',
        invalid: code,
      );
    }

    if (code.length > 12) {
      return ValidationResult(
        isValid: false,
        error: 'Service Provider Code too long (maximum 12 characters)',
        example: 'ORG001 (4-12 alphanumeric)',
        invalid: code,
      );
    }

    if (!RegExp(r'^([0-9A-Za-z]{4,12})$').hasMatch(code)) {
      return ValidationResult(
        isValid: false,
        error:
            'Service Provider Code must be alphanumeric only (no spaces, dashes, etc.)',
        example: 'ORG001 (4-12 alphanumeric)',
        invalid: code,
      );
    }

    return ValidationResult(isValid: true);
  }

  /// Validates transaction reference parameter
  /// Pattern: ^[0-9a-zA-Z \w+]{1,20}$ (1-20 chars, alphanumeric, space, underscore)
  /// Examples that PASS: "T12344C", "TXN_001", "REC 123", "TX001"
  /// Examples that FAIL: "T-123", "TX/001", "TX@123", ""
  static ValidationResult validateTransactionReference(String reference) {
    if (reference.isEmpty) {
      return ValidationResult(
        isValid: false,
        error: 'Transaction Reference cannot be empty',
        example: 'T12344C or TXN_001 (1-20 characters)',
      );
    }

    if (reference.length > 20) {
      return ValidationResult(
        isValid: false,
        error: 'Transaction Reference too long (maximum 20 characters)',
        example: 'T12344C or TXN_001 (1-20 characters)',
        invalid: reference,
      );
    }

    if (!RegExp(r'^[0-9a-zA-Z \w+]{1,20}$').hasMatch(reference)) {
      return ValidationResult(
        isValid: false,
        error:
            'Transaction Reference contains invalid characters (only alphanumeric, space, underscore allowed)',
        example: 'T12344C or TXN_001 (1-20 characters)',
        invalid: reference,
      );
    }

    return ValidationResult(isValid: true);
  }

  /// Validates third party conversation ID parameter
  /// Pattern: ^[0-0a-zA-Z \w+]{1,40}$ (1-40 chars, alphanumeric, space, underscore)
  /// Examples that PASS: UUID format or any 1-40 char alphanumeric
  /// Examples that FAIL: Too long, invalid characters
  static ValidationResult validateThirdPartyConversationID(String id) {
    if (id.isEmpty) {
      return ValidationResult(
        isValid: false,
        error: 'Third Party Conversation ID cannot be empty',
        example: 'UUID or alphanumeric string (1-40 characters)',
      );
    }

    if (id.length > 40) {
      return ValidationResult(
        isValid: false,
        error: 'Third Party Conversation ID too long (maximum 40 characters)',
        example: 'UUID or alphanumeric string (1-40 characters)',
        invalid: id,
      );
    }

    if (!RegExp(r'^[0-9a-zA-Z \w+]{1,40}$').hasMatch(id)) {
      return ValidationResult(
        isValid: false,
        error:
            'Third Party Conversation ID contains invalid characters (only alphanumeric, space, underscore allowed)',
        example: 'UUID or alphanumeric string (1-40 characters)',
        invalid: id,
      );
    }

    return ValidationResult(isValid: true);
  }

  /// Validates purchased items description parameter
  /// Pattern: ^[0-9a-zA-Z \w+]{1,256}$ (1-256 chars)
  /// Examples that PASS: "Test Payment", "Item 1, Item 2", "DESC_123"
  /// Examples that FAIL: Too long, invalid characters (special chars)
  static ValidationResult validatePurchasedItemsDesc(String desc) {
    if (desc.isEmpty) {
      return ValidationResult(
        isValid: false,
        error: 'Purchased Items Description cannot be empty',
        example: 'Test Payment or Item 1, Item 2 (1-256 characters)',
      );
    }

    if (desc.length > 256) {
      return ValidationResult(
        isValid: false,
        error: 'Purchased Items Description too long (maximum 256 characters)',
        example: 'Test Payment or Item 1, Item 2 (1-256 characters)',
        invalid: desc,
      );
    }

    if (!RegExp(r'^[0-9a-zA-Z \w+]{1,256}$').hasMatch(desc)) {
      return ValidationResult(
        isValid: false,
        error:
            'Purchased Items Description contains invalid characters (only alphanumeric, space, underscore allowed)',
        example: 'Test Payment or Item 1, Item 2 (1-256 characters)',
        invalid: desc,
      );
    }

    return ValidationResult(isValid: true);
  }

  /// Validates all payment parameters
  /// Returns true if all parameters are valid, false otherwise
  static bool validateAllParameters({
    required String amount,
    required String serviceProviderCode,
    required String transactionReference,
    required String thirdPartyConversationId,
    required String purchasedItemsDesc,
    String country = 'TZN',
    String currency = 'TZS',
  }) {
    return validateAmount(amount).isValid &&
        validateServiceProviderCode(serviceProviderCode).isValid &&
        validateTransactionReference(transactionReference).isValid &&
        validateThirdPartyConversationID(thirdPartyConversationId).isValid &&
        validatePurchasedItemsDesc(purchasedItemsDesc).isValid &&
        country.isNotEmpty &&
        currency.isNotEmpty;
  }

  /// Get all validation errors for debugging
  static List<String> getAllValidationErrors({
    required String amount,
    required String serviceProviderCode,
    required String transactionReference,
    required String thirdPartyConversationId,
    required String purchasedItemsDesc,
  }) {
    final errors = <String>[];

    final amountResult = validateAmount(amount);
    if (!amountResult.isValid) errors.add('Amount: ${amountResult.error}');

    final codeResult = validateServiceProviderCode(serviceProviderCode);
    if (!codeResult.isValid)
      errors.add('Service Provider Code: ${codeResult.error}');

    final refResult = validateTransactionReference(transactionReference);
    if (!refResult.isValid)
      errors.add('Transaction Reference: ${refResult.error}');

    final idResult = validateThirdPartyConversationID(thirdPartyConversationId);
    if (!idResult.isValid)
      errors.add('Third Party Conversation ID: ${idResult.error}');

    final descResult = validatePurchasedItemsDesc(purchasedItemsDesc);
    if (!descResult.isValid)
      errors.add('Purchased Items Description: ${descResult.error}');

    return errors;
  }
}

/// Result of parameter validation
class ValidationResult {
  final bool isValid;
  final String? error;
  final String? example;
  final String? invalid;

  ValidationResult({
    required this.isValid,
    this.error,
    this.example,
    this.invalid,
  });

  @override
  String toString() {
    if (isValid) return '✓ Valid';

    var message = '✗ $error';
    if (invalid != null) message += '\n  Invalid value: "$invalid"';
    if (example != null) message += '\n  Expected format: $example';
    return message;
  }
}
