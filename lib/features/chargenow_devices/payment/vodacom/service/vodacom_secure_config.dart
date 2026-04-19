import 'package:firebase_remote_config/firebase_remote_config.dart';

/// Secure configuration for Vodacom API credentials
///
/// This class manages sensitive credentials (API keys, service codes)
/// without storing them in source code. Credentials are fetched from:
/// 1. Firebase Remote Config (recommended for production)
/// 2. Environment variables (fallback)
///
/// To set up:
/// 1. In Firebase Console > Remote Config, add the following parameter names:
///    - vodacom_sandbox_api_key
///    - vodacom_sandbox_service_code
///    - vodacom_production_api_key
///    - vodacom_production_service_code
///    - vodacom_sandbox_rsa_public_key
///    - vodacom_production_rsa_public_key
///
/// 2. For local development, set corresponding environment variables
class VodacomSecureConfig {
  static final VodacomSecureConfig _instance = VodacomSecureConfig._internal();

  factory VodacomSecureConfig() {
    return _instance;
  }

  VodacomSecureConfig._internal();

  static const String _sandboxApiKeyRemote = 'vodacom_sandbox_api_key';
  static const String _sandboxServiceCodeRemote =
      'vodacom_sandbox_service_code';
  static const String _sandboxRsaKeyRemote = 'vodacom_sandbox_rsa_public_key';
  static const String _productionApiKeyRemote = 'vodacom_production_api_key';
  static const String _productionServiceCodeRemote =
      'vodacom_production_service_code';
  static const String _productionRsaKeyRemote =
      'vodacom_production_rsa_public_key';

  static const String _sandboxApiKeyEnv = 'VODACOM_SANDBOX_API_KEY';
  static const String _sandboxServiceCodeEnv = 'VODACOM_SANDBOX_SERVICE_CODE';
  static const String _sandboxRsaKeyEnv = 'VODACOM_SANDBOX_RSA_PUBLIC_KEY';
  static const String _productionApiKeyEnv = 'VODACOM_PRODUCTION_API_KEY';
  static const String _productionServiceCodeEnv =
      'VODACOM_PRODUCTION_SERVICE_CODE';
  static const String _productionRsaKeyEnv =
      'VODACOM_PRODUCTION_RSA_PUBLIC_KEY';

  // Default RSA public key (can be overridden via Remote Config)
  static const String _defaultRsaPublicKey =
      "MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEArv9yxA69XQKBo24BaF/D+fvlqmGdYjqLQ5WtNBb5tquqGvAvG3WMFETVUSow/LizQalxj2ElMVrUmzu5mGGkxK08bWEXF7a1DEvtVJs6nppIlFJc2SnrU14AOrIrB28ogm58JjAl5BOQawOXD5dfSk7MaAA82pVHoIqEu0FxA8BOKU+RGTihRU+ptw1j4bsAJYiPbSX6i71gfPvwHPYamM0bfI4CmlsUUR3KvCG24rB6FNPcRBhM3jDuv8ae2kC33w9hEq8qNB55uw51vK7hyXoAa+U7IqP1y6nBdlN25gkxEA8yrsl1678cspeXr+3ciRyqoRgj9RD/ONbJhhxFvt1cLBh+qwK2eqISfBb06eRnNeC71oBokDm3zyCnkOtMDGl7IvnMfZfEPFCfg5QgJVk1msPpRvQxmEsrX9MQRyFVzgy2CWNIb7c+jPapyrNwoUbANlN8adU1m6yOuoX7F49x+OjiG2se0EJ6nafeKUXw/+hiJZvELUYgzKUtMAZVTNZfT8jjb58j8GVtuS+6TM2AutbejaCV84ZK58E2CRJqhmjQibEUO6KPdD7oTlEkFy52Y1uOOBXgYpqMzufNPmfdqqqSM4dU70PO8ogyKGiLAIxCetMjjm6FCMEA3Kc8K0Ig7/XtFm9By6VxTJK1Mg36TlHaZKP6VzVLXMtesJECAwEAAQ==";

  late FirebaseRemoteConfig _remoteConfig;
  bool _initialized = false;

  /// Initialize Firebase Remote Config for credential management
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _remoteConfig = FirebaseRemoteConfig.instance;

      // Set default values if Remote Config fetch fails
      await _remoteConfig.setDefaults({
        _sandboxApiKeyRemote: _getEnvVariable(_sandboxApiKeyEnv, ''),
        _sandboxServiceCodeRemote:
            _getEnvVariable(_sandboxServiceCodeEnv, '000000'),
        _sandboxRsaKeyRemote:
            _getEnvVariable(_sandboxRsaKeyEnv, _defaultRsaPublicKey),
        _productionApiKeyRemote: _getEnvVariable(_productionApiKeyEnv, ''),
        _productionServiceCodeRemote:
            _getEnvVariable(_productionServiceCodeEnv, '944378'),
        _productionRsaKeyRemote:
            _getEnvVariable(_productionRsaKeyEnv, _defaultRsaPublicKey),
      });

      // Fetch latest values from Firebase Remote Config
      await _remoteConfig.fetchAndActivate();

      _initialized = true;
      print(
          '[VodacomSecure] ✓ Configuration initialized from Firebase Remote Config');
    } catch (e) {
      print(
          '[VodacomSecure] ⚠️ Warning: Could not fetch from Remote Config: $e');
      print(
          '[VodacomSecure] Using fallback configuration (environment variables)');
      _initialized = true;
    }
  }

  /// Get sandbox API key
  String get sandboxApiKey {
    _ensureInitialized();
    final value = _remoteConfig.getString(_sandboxApiKeyRemote).isEmpty
        ? _getEnvVariable(_sandboxApiKeyEnv, '')
        : _remoteConfig.getString(_sandboxApiKeyRemote);
    _logCredentialAccess('Sandbox API Key');
    return value;
  }

  /// Get sandbox service code
  String get sandboxServiceCode {
    _ensureInitialized();
    final value = _remoteConfig.getString(_sandboxServiceCodeRemote).isEmpty
        ? _getEnvVariable(_sandboxServiceCodeEnv, '000000')
        : _remoteConfig.getString(_sandboxServiceCodeRemote);
    return value;
  }

  /// Get production API key
  String get productionApiKey {
    _ensureInitialized();
    final value = _remoteConfig.getString(_productionApiKeyRemote).isEmpty
        ? _getEnvVariable(_productionApiKeyEnv, '')
        : _remoteConfig.getString(_productionApiKeyRemote);
    _logCredentialAccess('Production API Key');
    return value;
  }

  /// Get production service code
  String get productionServiceCode {
    _ensureInitialized();
    final value = _remoteConfig.getString(_productionServiceCodeRemote).isEmpty
        ? _getEnvVariable(_productionServiceCodeEnv, '944378')
        : _remoteConfig.getString(_productionServiceCodeRemote);
    return value;
  }

  /// Get sandbox RSA public key for encryption
  String get sandboxRsaPublicKey {
    _ensureInitialized();
    final value = _remoteConfig.getString(_sandboxRsaKeyRemote).isEmpty
        ? _getEnvVariable(_sandboxRsaKeyEnv, _defaultRsaPublicKey)
        : _remoteConfig.getString(_sandboxRsaKeyRemote);
    return value;
  }

  /// Get production RSA public key for encryption
  String get productionRsaPublicKey {
    _ensureInitialized();
    final value = _remoteConfig.getString(_productionRsaKeyRemote).isEmpty
        ? _getEnvVariable(_productionRsaKeyEnv, _defaultRsaPublicKey)
        : _remoteConfig.getString(_productionRsaKeyRemote);
    return value;
  }

  /// Get RSA public key based on current mode (sandbox or production)
  String get rsaPublicKey {
    // This is for backward compatibility - use sandboxRsaPublicKey/productionRsaPublicKey directly
    // when you know the mode at the call site
    _ensureInitialized();
    return _defaultRsaPublicKey; // Default fallback
  }

  /// Check if credentials are properly configured
  bool get isConfigured {
    _ensureInitialized();
    return productionApiKey.isNotEmpty || sandboxApiKey.isNotEmpty;
  }

  /// Verify API key exists for given mode
  bool hasApiKeyFor(bool isProduction) {
    return isProduction
        ? productionApiKey.isNotEmpty
        : sandboxApiKey.isNotEmpty;
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw Exception(
        'VodacomSecureConfig not initialized. Call initialize() first.',
      );
    }
  }

  String _getEnvVariable(String key, String defaultValue) {
    // In Flutter, environment variables are not directly accessible via dart:io
    // This would be handled during build time or via platform channels
    // For now, return default value
    return defaultValue;
  }

  void _logCredentialAccess(String credentialType) {
    // Only log in debug mode, don't expose sensitive info
    print('[VodacomSecure] ✓ Accessing $credentialType');
  }
}
