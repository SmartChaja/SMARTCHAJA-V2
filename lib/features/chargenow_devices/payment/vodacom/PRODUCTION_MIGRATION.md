# Vodacom Payment System - Sandbox to Production Migration Guide

## Overview

This guide explains how to migrate your Vodacom C2B payment integration from sandbox testing to production.

## Current Status ✓

- ✓ API integration structure complete
- ✓ Encryption service implemented
- ✓ Session key generation working
- ✓ Sandbox testing completed
- ⏳ **Ready for production migration**

## Migration Checklist

### 1. ✓ Obtain Production Credentials from Vodacom

**Status**: You have provided:

- Organization Code (Service Provider Code): **944378**
- Shirt Code: **944378**

**Still needed**:

- [ ] Production API Key from Vodacom Dashboard

**How to get it**:

1. Login to Vodacom M-Pesa OpenAPI portal
2. Navigate to Applications → Your Production App
3. Copy the Production API Key (NOT the sandbox key)
4. Store securely (do not commit to git)

---

### 2. Update Configuration File

**File**: `lib/features/chargenow_devices/payment/vodacom/provider/vodacom_payment_providers.dart`

#### Step 1: Add Production API Key

```dart
// Production Configuration
const String _vodacomProductionApiKey = 'YOUR_PRODUCTION_API_KEY_HERE'; // TODO: Add your production API key from Vodacom
const String _vodacomProductionServiceCode = '944378'; // ✓ Already set
```

Replace `YOUR_PRODUCTION_API_KEY_HERE` with your actual production API key.

#### Step 2: Enable Production Mode

```dart
/// Toggle PRODUCTION_MODE to switch between sandbox and production
const bool PRODUCTION_MODE = true; // Change from false to true
```

#### Step 3: (Optional) Update Origin Header

If you have a production domain, update:

```dart
origin: '*', // Change to your domain, e.g., 'yourdomain.com'
```

---

### 3. Environment Variables (Recommended for Security)

Instead of hardcoding API keys, use environment variables:

**Option A: Using dotenv package** (Recommended)

```dart
// In pubspec.yaml
dependencies:
  flutter_dotenv: ^5.0.0

// Create .env file (add to .gitignore)
VODACOM_PROD_API_KEY=your_actual_production_key
VODACOM_PROD_SERVICE_CODE=944378

// In code
import 'package:flutter_dotenv/flutter_dotenv.dart';

const String _vodacomProductionApiKey = String.fromEnvironment('VODACOM_PROD_API_KEY', defaultValue: '');
```

---

## API Endpoint Changes

### Sandbox (Current)

```
https://openapi.m-pesa.com/sandbox/ipg/v2/vodacomTZN/c2bPayment/singleStage/
```

### Production (New)

```
https://openapi.m-pesa.com/openapi/ipg/v2/vodacomTZN/c2bPayment/singleStage/
```

**Automatic Handling**: This is automatically handled by the service based on the `sandbox` flag.

---

## Production Request Format

### Customer MSISDN

- **Sandbox**: May accept stripped formats (e.g., "0717161122" or "707161122")
- **Production**: Must be full 12-14 digit format (e.g., "255707161122" for Tanzania)

**API Regex Validation**: `^[0-9]{12,14}$`

**Example**:

```dart
// Production - Use full MSISDN
String msisdn = "255707161122"; // 12 digits ✓
```

### Service Provider Code

- **Sandbox**: `000000` (test value)
- **Production**: `944378` (your organization code)

**API Regex Validation**: `^([0-9A-Za-z]{4,12})$`

**Status**: ✓ Already configured in updated code

---

## Key Behavior Differences

| Aspect                      | Sandbox                            | Production                  |
| --------------------------- | ---------------------------------- | --------------------------- |
| Endpoint Path               | `/sandbox/ipg/v2/...`              | `/openapi/ipg/v2/...`       |
| API Key                     | `BBCFkqwvBIqV3sPXwsGdBGI5m3cM8GMK` | Your Production Key         |
| Service Code                | `000000`                           | `944378`                    |
| MSISDN Format               | Flexible (can strip prefix)        | Full 12-14 digits required  |
| Third Party Conversation ID | `test1234567891`                   | Unique UUID per transaction |
| Session Duration            | 30 seconds to become live          | 30 seconds to become live   |

---

## Testing Production Integration

### Pre-Production Checklist

- [ ] Production API key obtained from Vodacom
- [ ] `PRODUCTION_MODE = true` set in your code
- [ ] `_vodacomProductionApiKey` configured
- [ ] MSISDN format verified (12-14 digits with country code)
- [ ] Service provider code set to `944378`
- [ ] Origin header correct for your domain
- [ ] Test transaction initiated with small amount

### Test Transaction

```dart
// Example production test
await vodacomPaymentService.performC2BPayment(
  sessionKey: sessionKey,
  amount: '10.00', // Small test amount
  customerMsisdn: '255707161122', // Full MSISDN format
  transactionReference: 'TEST_PROD_001',
  purchasedItemsDesc: 'Test Device Charge',
);
```

### Expected Response Codes

- **201 / INS-0**: Request processed successfully ✓
- **400 / INS-1**: Internal Error
- **401 / INS-6**: Transaction Failed
- **400 / INS-2051**: MSISDN invalid (check format is 12-14 digits)
- **400 / INS-13**: Invalid Shortcode (check service code = 944378)

---

## Troubleshooting

### Issue: "INS-13 - Invalid Shortcode Used"

**Solution**: Verify `serviceProviderCode` is set to `944378` in production

### Issue: "INS-2051 - MSISDN invalid"

**Solution**: Ensure customer MSISDN is 12-14 digits with country code (e.g., `255707161122`)

### Issue: "400 - Bad API Key"

**Solution**:

1. Verify production API key is correct
2. Check Origin header matches Vodacom dashboard settings
3. Ensure application status is "Production" in Vodacom dashboard

### Issue: "Session Key invalid after 30 seconds"

**Solution**: This is expected - always generate a fresh session key before each payment

---

## Security Best Practices

1. **Never commit API keys** to version control
2. **Use environment variables** for secrets
3. **Use secure storage** (FlutterSecureStorage) for sensitive data
4. **Validate MSISDN format** before sending to API
5. **Log transactions** for audit trail
6. **Monitor response codes** for pattern anomalies

---

## Monitoring & Logging

Your code already includes detailed logging. Production logs from your service:

```
[VodacomAPI] Generating Session Key
[VodacomAPI] Response Status: 200
[VodacomAPI] ✓ Session ID obtained: xyz123...
[VodacomAPI] C2B Payment Response Status: 201
[VodacomAPI] ✓ C2B Payment Success: {...}
```

---

## Next Steps

1. **Obtain production API key** from Vodacom
2. **Add to configuration file**
3. **Set `PRODUCTION_MODE = true`**
4. **Test with small transaction**
5. **Monitor logs and responses**
6. **Deploy to production**

---

## API Documentation Reference

- **C2B Single Stage**: Customer-to-Business transaction
- **Public Key**: Used for RSA encryption of API credentials
- **Session Key**: Generated per session, takes up to 30 seconds to become active
- **Synchronous Flow**: Response received immediately
- **Asynchronous Flow**: Response via webhook (requires listener implementation)

---

## Support

For issues with:

- **Your integration code**: Check logs in `[VodacomAPI]` output
- **Vodacom API errors**: Refer to Response Codes table above
- **Production credentials**: Contact Vodacom support

---

**Last Updated**: April 2026
**Status**: Ready for Production
