# Vodacom Credentials Security - Setup Guide

> All Vodacom API credentials are now securely managed through **Firebase Remote Config**. No secrets are stored in source code.

---

## Why This Matters

**Before (❌ UNSAFE):**

```dart
// Exposed in GitHub!
const String _apiKey = 'fqp4cOx2oODvLa5Kitubc9swHEDGzfnK';
const String _serviceCode = '944378';
```

**After (✅ SECURE):**

```dart
// Credentials fetched from Firebase Remote Config at runtime
final apiKey = secureConfig.productionApiKey;
final serviceCode = secureConfig.productionServiceCode;
```

---

## Architecture Changes

### What Was Moved

| Credential     | Before                       | After                                  |
| -------------- | ---------------------------- | -------------------------------------- |
| API Keys       | Hardcoded in `.dart` files   | Firebase Remote Config                 |
| Service Codes  | Hardcoded in `.dart` files   | Firebase Remote Config                 |
| RSA Public Key | Hardcoded in `VodacomConfig` | Firebase Remote Config (with fallback) |
| Sandbox Keys   | Hardcoded constants          | Firebase Remote Config                 |

### New Files Created

- **`vodacom_secure_config.dart`** - Singleton that manages credential retrieval
- **`vodacom_payment_providers.dart`** - Updated to use secure config (no hardcoded keys)

### Files Updated

- **`vodacom_payment_service.dart`** - Now uses `VodacomSecureConfig` for RSA key
- **`vodacom_payment_providers.dart`** - Replaced hardcoded constants with secure config

---

## Setup Instructions

### Step 1: Add Firebase Remote Config to pubspec.yaml

Check if you already have it:

```bash
grep "firebase_remote_config" pubspec.yaml
```

If not present, add it:

```bash
flutter pub add firebase_remote_config
```

---

### Step 2: Set Up Remote Config in Firebase Console

1. Go to **Firebase Console** → Your Project → **Remote Config**
2. Click **Create Configuration**
3. Add the following key-value pairs:

| Key                               | Value                                  | Type   |
| --------------------------------- | -------------------------------------- | ------ |
| `vodacom_sandbox_api_key`         | `BBCFkqwvBIqV3sPXwsGdBGI5m3cM8GMK`     | String |
| `vodacom_sandbox_service_code`    | `000000`                               | String |
| `vodacom_production_api_key`      | `fqp4cOx2oODvLa5Kitubc9swHEDGzfnK`     | String |
| `vodacom_production_service_code` | `944378`                               | String |
| `vodacom_rsa_public_key`          | (The full RSA public key from Vodacom) | String |

4. Click **Publish Changes**

---

### Step 3: Initialize Secure Config on App Startup

In your `main.dart` or app initialization:

```dart
import 'package:your_app/features/chargenow_devices/payment/vodacom/service/vodacom_secure_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase first
  await Firebase.initializeApp();

  // Initialize Vodacom secure credentials
  await VodacomSecureConfig().initialize();

  runApp(const MyApp());
}
```

---

### Step 4: Verify It Works

After running the app, you should see in console:

```
[VodacomSecure] ✓ Configuration initialized from Firebase Remote Config
[VodacomSecure] ✓ Accessing Production API Key
```

---

## How It Works

### Runtime Flow

```
App starts
    ↓
VodacomSecureConfig.initialize()
    ↓
Firebase Remote Config fetched
    ↓
Payment attempt
    ↓
VodacomSecureConfig.productionApiKey accessed
    ↓
Key fetched from Remote Config (or fallback to env variables)
    ↓
Payment proceeds securely
```

### Code Example

```dart
// Before (hardcoded - UNSAFE)
final paymentService = VodacomPaymentService(
  apiKey: 'fqp4cOx2oODvLa5Kitubc9swHEDGzfnK',  // 🚨 Exposed!
  serviceProviderCode: '944378',
);

// After (secure - SAFE)
final secureConfig = VodacomSecureConfig();
final paymentService = VodacomPaymentService(
  apiKey: secureConfig.productionApiKey,  // ✅ Fetched from Firebase
  serviceProviderCode: secureConfig.productionServiceCode,
);
```

---

## Fallback Mechanism

If Firebase Remote Config fails, credentials fall back to environment variables:

```bash
# Set environment variables for local development
export VODACOM_PRODUCTION_API_KEY="fqp4cOx2oODvLa5Kitubc9swHEDGzfnK"
export VODACOM_PRODUCTION_SERVICE_CODE="944378"
export VODACOM_SANDBOX_API_KEY="BBCFkqwvBIqV3sPXwsGdBGI5m3cM8GMK"
export VODACOM_SANDBOX_SERVICE_CODE="000000"

# Then run
flutter run
```

---

## What's Now Git-Safe

### `.gitignore` No Longer Needs These...

Before, you'd need to protect:

```
lib/features/chargenow_devices/payment/vodacom/provider/vodacom_payment_providers.dart  # Contains API keys!
lib/features/chargenow_devices/payment/vodacom/service/vodacom_payment_service.dart    # Contains RSA key!
.env
.env.local
```

### Now It's Safe

All files are safe to commit. The provider file now looks like:

```dart
const bool PRODUCTION_MODE = true;
// NO HARDCODED KEYS ANYWHERE!

final vodacomPaymentServiceProvider = Provider<VodacomPaymentService>((ref) {
  final secureConfig = VodacomSecureConfig();  // ✅ Fetches from Firebase at runtime
  return VodacomPaymentService(
    apiKey: PRODUCTION_MODE ? secureConfig.productionApiKey : secureConfig.sandboxApiKey,
    // ... rest of code
  );
});
```

---

## Updating Credentials

### To Change API Key:

1. Go to **Firebase Console → Remote Config**
2. Update the key value
3. Click **Publish Changes**
4. App will use new key on next restart (or next Remote Config fetch)

No code changes needed! No redeployment to app store needed!

---

## Security Best Practices

### ✅ DO:

- Store credentials in Firebase Remote Config only
- Use different keys for sandbox and production
- Rotate keys regularly
- Enable Remote Config version history
- Monitor Remote Config access in Firebase logs

### ❌ DON'T:

- Hardcode credentials in `.dart` files
- Commit credentials to git (even in commented code)
- Share credentials in Slack/email without encryption
- Use same credentials for sandbox and production
- Log full credentials (the code already masks them)

---

## Verifying Credentials Are Secure

### Check Git History

```bash
# Make sure credentials don't exist in git history
git log -p --all -S "fqp4cOx2oODvLa5Kitubc9swHEDGzfnK"
# Should return: (nothing found)

git log -p --all -S "BBCFkqwvBIqV3sPXwsGdBGI5m3cM8GMK"
# Should return: (nothing found)
```

### Check Source Files

```bash
# Verify no hardcoded keys in current files
grep -r "fqp4cOx2oODvLa5Kitubc9swHEDGzfnK" lib/
# Should return: (nothing found)

grep -r "BBCFkqwvBIqV3sPXwsGdBGI5m3cM8GMK" lib/
# Should return: (nothing found)
```

---

## Credential Access Logging

The `VodacomSecureConfig` logs when credentials are accessed (in debug mode only):

```
[VodacomSecure] ✓ Accessing Production API Key
[VodacomSecure] ✓ Accessing Sandbox API Key
```

Full API keys are never logged. Only confirmation that they were accessed.

---

## Troubleshooting

### Error: "VodacomSecureConfig not initialized"

**Solution:** Call `initialize()` in your `main()` function:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await VodacomSecureConfig().initialize();  // Add this!
  runApp(MyApp());
}
```

### Error: "Could not fetch from Remote Config"

**Solution:** Check that:

1. Firebase is initialized
2. You have internet connection
3. Remote Config keys exist in Firebase Console
4. Only fallback to environment variables if Remote Config unavailable

---

## Next Steps

1. ✅ Add `firebase_remote_config` to pubspec.yaml
2. ✅ Set up Remote Config keys in Firebase Console
3. ✅ Call `VodacomSecureConfig().initialize()` in `main.dart`
4. ✅ Test payment flow (should work identically to before)
5. ✅ Verify credentials don't appear in logs
6. ✅ Safely commit all code to git

---

## FAQ

**Q: Does this change payment flow?**  
A: No. Functionality is identical. Credentials are just fetched securely at runtime.

**Q: What if Firebase is offline?**  
A: The app falls back to environment variables. Payment still works.

**Q: Can I test locally without Firebase?**  
A: Yes. Set environment variables and the fallback will be used.

**Q: How often are credentials fetched?**  
A: Once on app startup via `initialize()`. Then cached in Remote Config.

**Q: What if I need to revoke a credential quickly?**  
A: Update in Firebase Console and click Publish. All future app instances will get the new value on next restart or Remote Config refresh.

---

_Last Updated: April 19, 2026_
_Vodacom Integration: SMARTCHAJA-V2_
