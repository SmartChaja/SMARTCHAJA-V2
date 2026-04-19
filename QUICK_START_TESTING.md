# VODACOM PAYMENT TESTING - QUICK START

## The Problem You're Seeing

Error: **"MSISDN invalid"** when trying to pay

## The Solution (Already Implemented)

✅ Phone number auto-formatter - converts any format to API format

---

## 🚀 QUICK START - Test in 3 Steps

### Step 1: Run Unit Tests (30 seconds)

```bash
flutter test test/msisdn_formatter_test.dart
```

**Expected:** All tests PASS ✓

### Step 2: Run Your App (60 seconds)

```bash
flutter run
```

### Step 3: Make Test Payment

Enter these values:

- **Phone:** `0712345678` (or `+255712345678` - auto-converts!)
- **Amount:** `5000` TZS
- **Tap:** "Pay Now"

Check console for:

```
✓ MSISDN formatted: 0712345678 → 255712345678
```

---

## 📊 Phone Number Conversion Table

| You Enter     | We Send to API |
| ------------- | -------------- |
| 0712345678    | 255712345678   |
| +255712345678 | 255712345678   |
| 255712345678  | 255712345678   |
| 0747 111 222  | 255747111222   |

**App automatically fixes all formats!**

---

## 🧪 Run All Tests at Once

```bash
bash vodacom-complete-test.sh
```

This runs:

- ✓ MSISDN format tests (15 groups)
- ✓ Payment callback tests (10 groups)
- ✓ Cloud Function health check
- ✓ Callback payload tests
- ✓ Shows test data examples
- ✓ Displays checklist

---

## 🔍 Debug Your Payment

### See MSISDN Conversion

Check your IDE console during payment:

```
[VodacomAPI] ✓ MSISDN formatted: 0712345678 → 255712345678
```

### If You See Error

```
[VodacomAPI] ✗ MSISDN format error: ...
[VodacomAPI] - Error: Phone number too short
```

Then check phone number validity.

---

## 📱 Valid Test Numbers by Provider

### Vodacom Tanzania

```
0747 111 111  →  255747111111
0748 222 222  →  255748222222
0749 333 333  →  255749333333
```

### Tigo Tanzania

```
0655 111 111  →  255655111111
0656 222 222  →  255656222222
0657 333 333  →  255657333333
```

### Airtel Tanzania

```
0789 111 111  →  255789111111
0788 222 222  →  255788222222
```

---

## ✅ Payment Success Flow

```
User enters: 0712345678
    ↓
App converts: → 255712345678
    ↓
API receives: input_CustomerMSISDN: "255712345678"
    ↓
✓ No "MSISDN invalid" error
    ↓
✓ Payment processes normally
    ↓
✓ Cloud Function callback confirms
    ↓
✓ Balance updates in Firebase
```

---

## 🔧 Configuration Files

**MSISDN Formatter:**

- Location: `lib/features/chargenow_devices/payment/vodacom/utils/msisdn_formatter.dart`
- Handles all phone format conversions
- Tanzania-specific validation
- Full operator support

**Payment Service:**

- Location: `lib/features/chargenow_devices/payment/vodacom/service/vodacom_payment_service.dart`
- Updated to use MSISDN formatter
- Better error messages
- Debug logging

---

## 📚 Full Test Guides

- **MSISDN_VALIDATION_GUIDE.md** - Phone format reference
- **VODACOM_TESTING_GUIDE.md** - Complete testing procedures
- **test/vodacom_callback_test.dart** - Callback tests
- **test/msisdn_formatter_test.dart** - Phone format tests

---

## 🚨 Common Issues & Fixes

| Error            | Cause                           | Fix                                        |
| ---------------- | ------------------------------- | ------------------------------------------ |
| "MSISDN invalid" | Wrong phone format              | Use any format, app converts automatically |
| "Invalid Amount" | Amount is empty                 | Enter a number like 5000                   |
| "User not found" | Payment initiated wrong context | Check user is logged in                    |
| Timeout          | Payment taking too long         | Wait and retry                             |

---

## 🎯 Next Steps

1. **Test Today:**
   - Run: `flutter test test/msisdn_formatter_test.dart`
   - Then: `flutter run`
   - Enter: 0712345678 as phone number
   - Watch for: ✓ MSISDN formatted message

2. **Monitor Callback:**
   - Command: `firebase functions:log`
   - Look for: New transaction callback entries

3. **Verify Balance:**
   - Go to: Firebase Console → Firestore
   - Check: User balance increased

4. **Production Setup:**
   - Get production API key from Vodacom
   - Update configuration file
   - Set PRODUCTION_MODE = true
   - Deploy

---

## 📞 Support

**Stuck?** Use these commands:

```bash
# Run all tests
bash vodacom-complete-test.sh

# See MSISDN tests
flutter test test/msisdn_formatter_test.dart -v

# Check payment callback tests
flutter test test/vodacom_callback_test.dart -v

# View cloud logs
firebase functions:log --only vodacomPaymentCallback

# Validate your app setup
flutter doctor
```

---

## ✨ TL;DR

**Old way:**

- User enters phone number
- ❌ Fails with "MSISDN invalid"
- Confusing error message

**New way:**

- User enters phone number (any format)
- ✅ Automatically converts to API format
- ✓ Payment works
- ✓ Clear debug messages

**Get started:** `flutter test test/msisdn_formatter_test.dart`

---

_Last Updated: April 12, 2026_
_Cloud Function Deployed: https://vodacompaymentcallback-45f4gu65ha-uc.a.run.app_
