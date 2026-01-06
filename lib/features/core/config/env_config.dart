import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  
  // Toggle between sandbox and production
  static bool get useSandbox => dotenv.env['USE_SANDBOX']?.toLowerCase() == 'true';

  // Sandbox Credentials
  static String get sandboxAppName => dotenv.env['SANDBOX_APP_NAME'] ?? '';
  static String get sandboxClientId => dotenv.env['SANDBOX_CLIENT_ID'] ?? '';
  static String get sandboxClientSecret => dotenv.env['SANDBOX_CLIENT_SECRET'] ?? '';

  // Production Credentials
  static String get productionAppName => dotenv.env['PRODUCTION_APP_NAME'] ?? '';
  static String get productionClientId => dotenv.env['PRODUCTION_CLIENT_ID'] ?? '';
  static String get productionClientSecret => dotenv.env['PRODUCTION_CLIENT_SECRET'] ?? '';
  static String? get productionXApiKey => dotenv.env['PRODUCTION_X_API_KEY'];

  // Firebase Configuration
  static String get projectId => dotenv.env['PROJECT_ID'] ?? '';
  static String get callbackUrl => dotenv.env['CALLBACK_URL'] ?? '';

  // OPENAPI AUTH
  static String get chargeNowUsername => dotenv.env['CHARGENOW_USERNAME'] ?? '';
  static String get chargeNowPassword => dotenv.env['CHARGENOW_PASSWORD'] ?? '';

  // Google Maps SDK API Keys
  static String get googleMapsApiKeyAndroid => dotenv.env['GOOGLE_MAPS_API_KEY_ANDROID'] ?? '';
  static String get googleMapsApiKeyIos => dotenv.env['GOOGLE_MAPS_API_KEY_IOS'] ?? '';

  // reCAPTCHA Site Keys
  static String get androidRecaptchaSiteKey => dotenv.env['ANDROID_RECAPTCHA_SITE_KEY'] ?? '';
  static String get iosRecaptchaSiteKey => dotenv.env['IOS_RECAPTCHA_SITE_KEY'] ?? '';

  // Beem Africa SMS Configuration
  static String get beemApiKey => dotenv.env['BEEM_API_KEY'] ?? '';
  static String get beemSecretKey => dotenv.env['BEEM_SECRET_KEY'] ?? '';
  static String get beemSenderId => dotenv.env['BEEM_SENDER_ID'] ?? '';

  // Derived getters based on useSandbox toggle
  static String get appName => useSandbox ? sandboxAppName : productionAppName;
  static String get clientId => useSandbox ? sandboxClientId : productionClientId;
  static String get clientSecret => useSandbox ? sandboxClientSecret : productionClientSecret;
  static String? get xApiKey => useSandbox ? null : productionXApiKey;

  static Future<void> load() async {
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      print("Error loading .env file: $e (This is normal in tests or if file is missing)");
      // You might want to provide default/fallback values or throw an error if critical variables are missing.
    }
  }
}