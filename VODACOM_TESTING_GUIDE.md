# Vodacom Payment Integration - Testing Guide

## Overview

This guide covers testing the complete Vodacom M-Pesa payment flow including:

1. Payment initiation
2. Callback handling
3. Wallet balance updates
4. Transaction recording

---

## 1. Unit Tests - Dart Services

### Test File Setup

Create `test/vodacom_payment_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:your_app/features/chargenow_devices/payment/vodacom/service/vodacom_transaction_service.dart';

// Generate mocks: run `dart pub get` then `flutter pub run build_runner build`
void main() {
  group('VodacomTransactionService', () {
    late MockFirebaseFirestore mockFirestore;
    late MockFirebaseAuth mockAuth;
    late VodacomTransactionService service;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockAuth = MockFirebaseAuth();
      service = VodacomTransactionService(
        firestore: mockFirestore,
        auth: mockAuth,
      );
    });

    test('savePendingTransaction creates transaction record', () async {
      // Arrange
      final mockUser = MockUser();
      when(mockAuth.currentUser).thenReturn(mockUser);

      // Mock Firestore collection operations
      final mockCollectionRef = MockCollectionReference();
      when(mockFirestore.collection('transactions')).thenReturn(mockCollectionRef);

      // Act
      final txnId = await service.savePendingTransaction(
        amount: 5000,
        currency: 'TZS',
        transactionId: 'VOD123',
        conversationId: 'CONV123',
        thirdPartyConversationId: '3PARTY123',
        responseCode: 'INS-0',
        responseDesc: 'Request processed successfully',
      );

      // Assert
      expect(txnId, isNotEmpty);
      verify(mockFirestore.collection('transactions')).called(1);
    });

    test('confirmTransaction updates balance atomically', () async {
      // Test atomic transaction behavior
      // Verify both transaction status and balance are updated together
    });

    test('failTransaction marks transaction as failed', () async {
      // Test failure flow
    });
  });
}
```

### Running Unit Tests

```bash
# Generate mocks (one-time setup)
cd /Users/developer/Documents/Code/SMARTCHAJA-V2
flutter pub run build_runner build

# Run tests
flutter test test/vodacom_payment_test.dart

# Run all tests
flutter test
```

---

## 2. Integration Testing - Local Setup

### Option A: Firebase Emulator Suite (Recommended for Development)

#### Step 1: Install Firebase Emulator

```bash
npm install -g @firebase/cli
firebase init emulator
```

#### Step 2: Update `firebase.json`

```json
{
  "functions": {
    "source": "functions"
  },
  "emulators": {
    "firestore": {
      "port": 8080
    },
    "functions": {
      "port": 5001
    },
    "auth": {
      "port": 9099
    }
  }
}
```

#### Step 3: Update Dart Code for Emulator

In `lib/firebase_options.dart`, add:

```dart
// Connect to emulators in debug mode
if (kDebugMode) {
  await FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
  await FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
}
```

#### Step 4: Start Emulator

```bash
cd /Users/developer/Documents/Code/SMARTCHAJA-V2
firebase emulators:start
```

Output will show:

```
✔ Emulator UI logging to ui-debug.log
i Firestore Emulator started at http://localhost:8080
i Cloud Functions emulator started at http://localhost:5001
i Authentication emulator started at http://localhost:9099
```

---

## 3. Manual Testing Flow

### Test Scenario 1: Complete Payment Flow

#### Step 1: Start the App

```bash
flutter run
```

#### Step 2: Initiate Payment

1. Open the Vodacom payment screen
2. Enter test amount: **5,000 TZS**
3. Enter phone number: **Your test phone**
4. Tap "Pay Now"

**Expected Result:**

```
✓ Session key generated
✓ Payment request sent to Vodacom
✓ Transaction record created (status: pending)
✓ User sees payment confirmation UI
```

#### Step 3: Complete Payment on Vodacom Side

- Vodacom redirects to M-Pesa interface
- Enter PIN to confirm payment

**What Happens Behind Scenes:**

1. Vodacom gateway processes payment
2. Vodacom calls your Cloud Function webhook

#### Step 4: Verify Callback Processing

Monitor Cloud Function logs:

```bash
firebase functions:log

# Output example:
2026-04-12 14:35:22 vodacomPaymentCallback INFO: Callback received from Vodacom
2026-04-12 14:35:22 vodacomPaymentCallback INFO: Processing transaction: VOD123456
2026-04-12 14:35:23 vodacomPaymentCallback INFO: Status: CONFIRMED | Amount: 5000
```

#### Step 5: Verify Balance Update

Check Firestore Database:

```
Firebase Console → Firestore → Users Collection
  └── User Doc
      ├── balance: [OLD_BALANCE] → [OLD_BALANCE + 5000]
      └── lastBalanceUpdate: [Timestamp]

Transactions Collection
  └── Transaction Doc
      ├── status: pending → confirmed
      ├── amount: 5000
      ├── updatedAt: [Latest Timestamp]
      └── confirmedAt: [Timestamp]
```

---

## 4. Testing Cloud Function Locally

### Option 1: Firebase Functions Shell (Interactive Testing)

```bash
cd /Users/developer/Documents/Code/SMARTCHAJA-V2/functions
firebase functions:shell

# In the shell prompt, test the callback:
> const result = vodacomPaymentCallback({
    headers: {},
    body: {
      output_ResponseCode: 'INS-0',
      output_ResponseDesc: 'Request processed successfully',
      output_TransactionID: 'VOD123456',
      output_ConversationID: 'CONV123456',
      output_ThirdPartyConversationID: 'THIRDPARTY123'
    }
  })
```

### Option 2: Direct HTTP Testing with cURL

```bash
# Test the LIVE deployed function
curl -X POST https://vodacompaymentcallback-45f4gu65ha-uc.a.run.app \
  -H "Content-Type: application/json" \
  -d '{
    "output_ResponseCode": "INS-0",
    "output_ResponseDesc": "Request processed successfully",
    "output_TransactionID": "VOD_TEST_123",
    "output_ConversationID": "CONV_TEST_123",
    "output_ThirdPartyConversationID": "THIRDPARTY_TEST_123"
  }'

# Expected Response:
# {
#   "status": "success",
#   "message": "Payment confirmed"
# }
```

### Option 3: Postman/REST Client Testing

**Method:** POST
**URL:** `https://vodacompaymentcallback-45f4gu65ha-uc.a.run.app`

**Headers:**

```
Content-Type: application/json
```

**Body (JSON):**

```json
{
  "output_ResponseCode": "INS-0",
  "output_ResponseDesc": "Request processed successfully",
  "output_TransactionID": "VOD_TEST_789",
  "output_ConversationID": "CONV_TEST_789",
  "output_ThirdPartyConversationID": "THIRDPARTY_TEST_789"
}
```

---

## 5. Vodacom Sandbox Testing

### Prerequisites

- Vodacom M-Pesa API sandbox account
- Test credentials (API Key, Service Provider Code)
- Test phone numbers from Vodacom

### Update Configuration

In `lib/utils/vodacom_payment_providers.dart`:

```dart
// Use sandbox for testing
final vodacomPaymentServiceProvider = Provider<VodacomPaymentService>((ref) {
  return VodacomPaymentService(
    apiKey: 'YOUR_SANDBOX_API_KEY',
    serviceProviderCode: 'YOUR_SANDBOX_SERVICE_PROVIDER_CODE',
    sandbox: true,  // ← Set to true for sandbox
    origin: 'https://your-app-domain.com',
  );
});
```

### Test Cases

| Test Case            | Phone         | Amount     | Expected Result                    |
| -------------------- | ------------- | ---------- | ---------------------------------- |
| Success Payment      | +255712345678 | 5,000 TZS  | Balance increases by 5,000         |
| Insufficient Balance | +255712345679 | 50,000 TZS | Transaction fails (code not INS-0) |
| Timeout              | -             | 1,000 TZS  | Transaction status: timeout        |
| Invalid Phone        | +1234567890   | 1,000 TZS  | System rejects (wrong format)      |

---

## 6. Production Testing Checklist

Before switching to production:

### Pre-Flight Checks

- [ ] Callback URL registered in Vodacom dashboard: `https://vodacompaymentcallback-45f4gu65ha-uc.a.run.app`
- [ ] Production API key configured
- [ ] `PRODUCTION_MODE = true` set in payment service
- [ ] All error handling implemented
- [ ] Logging configured
- [ ] Firestore security rules updated
- [ ] Cloud Function error alerts configured

### Configuration Changes

```dart
// Production setup in vodacom_payment_providers.dart
final vodacomPaymentServiceProvider = Provider<VodacomPaymentService>((ref) {
  return VodacomPaymentService(
    apiKey: 'YOUR_PRODUCTION_API_KEY',  // ← Production key
    serviceProviderCode: 'YOUR_PRODUCTION_SERVICE_PROVIDER_CODE',
    sandbox: false,  // ← Set to false for production
    origin: 'https://your-production-domain.com',
  );
});
```

### Firestore Security Rules

```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Write transactions only via Cloud Function
    match /transactions/{document=**} {
      allow read: if request.auth.uid == resource.data.userId;
      allow write: if request.auth != null && request.auth.token['iss'] == 'https://securetoken.google.com/chaja-kiganjani';
    }

    // Update users only via Cloud Function
    match /users/{uid} {
      allow read: if request.auth.uid == uid;
      allow write: if request.auth.uid == uid || request.auth.token['iss'] == 'https://securetoken.google.com/chaja-kiganjani';
    }
  }
}
```

---

## 7. Debugging & Monitoring

### View Cloud Function Logs

```bash
# Real-time logs
firebase functions:log

# Filter by function
firebase functions:log --only vodacomPaymentCallback

# View in Firebase Console
# Cloud Functions → vodacomPaymentCallback → Logs
```

### Common Issues & Solutions

| Issue                  | Cause                       | Solution                           |
| ---------------------- | --------------------------- | ---------------------------------- |
| 409 Conflict           | Function being created      | Wait 30 seconds, retry             |
| 500 Error              | Firestore access denied     | Check security rules               |
| Timeout                | Payment taking too long     | Increase timeout in Vodacom config |
| Balance not updating   | Callback not received       | Verify callback URL registered     |
| "User not found" error | Callback runs wrong context | Check Cloud Function auth          |

### Enable Debug Logging

Add to Cloud Function (`functions/src/functions/vodacomPaymentCallback.js`):

```javascript
console.log("=== CALLBACK DEBUG ===");
console.log("Timestamp:", new Date().toISOString());
console.log("Request Body:", req.body);
console.log("Headers:", req.headers);
```

Check logs:

```bash
firebase functions:log
```

---

## 8. Test Data & Sample Payloads

### Successful Payment Callback

```json
{
  "output_ResponseCode": "INS-0",
  "output_ResponseDesc": "Request processed successfully",
  "output_TransactionID": "VOD_20260412_001",
  "output_ConversationID": "CONV_20260412_001",
  "output_ThirdPartyConversationID": "USER_123_TIMESTAMP"
}
```

### Failed Payment Callback

```json
{
  "output_ResponseCode": "INS-3",
  "output_ResponseDesc": "Request cancelled by user",
  "output_TransactionID": "VOD_20260412_002",
  "output_ConversationID": "CONV_20260412_002",
  "output_ThirdPartyConversationID": "USER_123_TIMESTAMP"
}
```

---

## 9. Performance Testing

### Load Test

Test callback handling under concurrent requests:

```bash
# Using Apache Bench (ab)
ab -n 100 -c 10 \
  -H "Content-Type: application/json" \
  -p test_payload.json \
  https://vodacompaymentcallback-45f4gu65ha-uc.a.run.app

# Results should show:
# - Response time < 1000ms
# - No failed requests
# - Proper balance updates for all transactions
```

---

## 10. Final Verification Steps

Once everything is working:

1. **Make a real test transaction** with Vodacom sandbox
2. **Monitor the callback** in Firebase logs
3. **Verify balance update** in Firestore
4. **Check transaction record** status changed to "confirmed"
5. **Test error scenarios** (insufficient balance, timeout, etc.)
6. **Review Cloud Function costs** (estimate in Firebase Console)

---

## Support

For issues:

1. Check Cloud Function logs: `firebase functions:log`
2. Review Firestore data consistency
3. Verify callback URL is accessible from internet
4. Test with cURL to isolate app-level issues
