# Vodacom C2B Payment Integration Guide

## Overview

This document provides comprehensive instructions for integrating Vodacom C2B (Customer-to-Business) single-stage payment method into your SmarChaja mobile wallet application.

## Project Structure

```
lib/features/chargenow_devices/payment/vodacom/
├── model/
│   └── vodacom_payment_model.dart          # Data models for API responses
├── service/
│   ├── encryption_service.dart             # RSA encryption utility
│   └── vodacom_payment_service.dart        # Main API service
├── response/
│   └── vodacom_payment_result.dart         # Response/Result models
├── provider/
│   └── vodacom_payment_providers.dart      # Riverpod dependency providers
├── view_model/
│   └── vodacom_payment_view_model.dart     # State management with Riverpod
└── example_usage.dart                       # Example widget implementation
```

## Setup Instructions

### 1. Update Dependencies

The following packages have been added to `pubspec.yaml`:
- `pointycastle: ^3.8.0` - For RSA encryption
- `crypto: ^3.0.3` - For cryptographic operations

Run the following command to fetch the new dependencies:
```bash
flutter pub get
```

### 2. API Configuration

The API key and configuration are stored in:
- **File**: `lib/features/chargenow_devices/payment/vodacom/provider/vodacom_payment_providers.dart`
- **API Key**: `PnUOd2XmPPD7zVWMyPx3SZuOMmAYAMrX` (Sandbox)
- **Environment**: Currently set to sandbox (`sandbox: true`)

To switch to production, update the `vodacomPaymentServiceProvider`:
```dart
final vodacomPaymentServiceProvider = Provider<VodacomPaymentService>((ref) {
  return VodacomPaymentService(
    apiKey: _vodacomApiKey,
    sandbox: false,  // Set to false for production
    origin: '*',
  );
});
```

## How It Works

### Architecture Overview

1. **Encryption Service** (`encryption_service.dart`)
   - Handles RSA encryption of API key and session key
   - Parses PEM-formatted public keys
   - Converts encrypted data to Base64 format

2. **Payment Service** (`vodacom_payment_service.dart`)
   - Manages API communication with M-Pesa OpenAPI
   - Generates session keys (required before payments)
   - Executes C2B single-stage payments
   - Queries transaction status

3. **View Model** (`vodacom_payment_view_model.dart`)
   - Handles payment state management using Riverpod
   - Caches session keys to avoid regenerating them frequently
   - Manages Firebase authentication checks
   - Provides clean API for UI components

### Payment Flow

```
1. Generate Session Key
   └─> Encrypt API Key with RSA
   └─> Call getSession endpoint
   └─> Receive and cache Session ID

2. Perform C2B Payment
   └─> Encrypt Session Key with RSA
   └─> Call c2bPayment/singleStage endpoint
   └─> Receive transaction response

3. [Optional] Query Transaction Status
   └─> Use Conversation ID
   └─> Get updated transaction status
```

## Usage Examples

### Basic Payment Implementation

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_chaja/features/chargenow_devices/payment/vodacom/provider/vodacom_payment_providers.dart';

class MyPaymentWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () {
        ref.read(vodacomPaymentViewModelProvider.notifier).performC2BPayment(
          amount: '10.00',
          customerMsisdn: '254707161122',
          serviceProviderCode: 'ORG001',
          transactionReference: 'T12344C',
          purchasedItemsDesc: 'Mobile Wallet Top-up',
        );
      },
      child: const Text('Pay with Vodacom'),
    );
  }
}
```

### Listening to Payment State

```dart
final paymentState = ref.watch(vodacomPaymentViewModelProvider);

paymentState.when(
  data: (result) {
    if (result == null) {
      // Initial state - show form
      return PaymentForm();
    } else if (result.isSuccess) {
      // Payment successful
      return SuccessScreen(result: result);
    } else {
      // Payment failed
      return ErrorScreen(message: result.message);
    }
  },
  loading: () => const CircularProgressIndicator(),
  error: (error, stack) => Text('Error: $error'),
);
```

### Query Transaction Status

```dart
ref.read(vodacomPaymentViewModelProvider.notifier).queryTransactionStatus(
  conversationId: 'fd1e9143d22544459f7c66e1860ef276',
);
```

## API Parameters

### C2B Payment Parameters

| Parameter | Type | Required | Description | Example |
|-----------|------|----------|-------------|---------|
| `amount` | String | Yes | Transaction amount | "10.00" |
| `customerMsisdn` | String | Yes | Customer phone number (12-14 digits) | "254707161122" |
| `serviceProviderCode` | String | Yes | Service provider shortcode | "ORG001" |
| `transactionReference` | String | Yes | Customer transaction reference (1-20 chars) | "T12344C" |
| `purchasedItemsDesc` | String | Yes | Description of items purchased | "Mobile Wallet Top-up" |

### Response Formats

#### Success Response
```json
{
  "output_ResponseCode": "INS-0",
  "output_ResponseDesc": "Request processed successfully",
  "output_TransactionID": "hv9ahxcg4ccv",
  "output_ConversationID": "fd1e9143d22544459f7c66e1860ef276",
  "output_ThirdPartyConversationID": "1e9b774d1da34af78412a498cbc28f5e"
}
```

#### Error Response
```json
{
  "output_ResponseCode": "INS-6",
  "output_ResponseDesc": "Transaction Failed"
}
```

## Error Codes

| Code | Description | Action |
|------|-------------|--------|
| INS-0 | Request processed successfully | Payment successful |
| INS-1 | Internal Error | Retry or contact support |
| INS-6 | Transaction Failed | Check payment details |
| INS-9 | Request timeout | Retry the transaction |
| INS-10 | Duplicate Transaction | Check if already processed |
| INS-13 | Invalid Shortcode | Verify service provider code |
| INS-15 | Invalid Amount | Check amount format |
| INS-2006 | Insufficient balance | Inform user to top-up |
| INS-2051 | MSISDN invalid | Validate phone number |

## Security Considerations

1. **API Key Storage**
   - Keep API key in secure storage (Firebase Remote Config, encrypted preferences)
   - Never commit API keys to version control
   - Use environment variables for CI/CD

2. **Session Key Caching**
   - Session keys are cached for 25 seconds (before expiry)
   - Automatically regenerated when expired
   - Cleared when user logs out

3. **RSA Encryption**
   - Uses M-Pesa's provided public key
   - RSA-2048 bit encryption
   - Base64 encoding for transmission

4. **HTTPS/SSL**
   - All API calls use HTTPS
   - SSL certificate validation enabled
   - Port 443 for secure communication

## Testing

### Sandbox Testing

For testing in sandbox environment:
1. Use sandbox API key: `PnUOd2XmPPD7zVWMyPx3SZuOMmAYAMrX`
2. API endpoint: `https://openapi.m-pesa.com/sandbox/ipg/v2/vodafoneGHA/...`
3. Test phone numbers provided by M-Pesa documentation

### Common Test Scenarios

```dart
// Successful payment
performC2BPayment(
  amount: '10.00',
  customerMsisdn: '254707161122',
  serviceProviderCode: 'ORG001',
  transactionReference: 'T12344C',
  purchasedItemsDesc: 'Test Payment',
)

// Insufficient balance
// Use a test number with low balance

// Invalid phone number
performC2BPayment(
  customerMsisdn: '123',  // Too short - will fail with INS-2051
  ...
)
```

## Integration with Existing Payment Methods

This Vodacom integration follows the same architecture as the existing Azam payment method:

1. **Service Layer**: API communication and business logic
2. **Models**: Data classes for type safety
3. **ViewModels**: State management with Riverpod
4. **Providers**: Dependency injection

You can extend the payment selector in your UI to include Vodacom:

```dart
// In your payment method selection screen
ElevatedButton(
  onPressed: () => navigateToVodacomPayment(),
  child: const Text('Pay with Vodacom'),
)
```

## Troubleshooting

### Issue: Session key generation fails

**Cause**: Invalid API key or network timeout

**Solution**:
- Verify API key in the provider
- Check internet connection
- Ensure firewall allows HTTPS on port 443

### Issue: RSA encryption error

**Cause**: Invalid public key format or malformed input

**Solution**:
- Verify public key hasn't been modified
- Check plaintext encoding (UTF-8)
- Ensure plaintext isn't empty

### Issue: Transaction times out

**Cause**: Network latency or server overload

**Solution**:
- Implement exponential backoff retry logic
- Check M-Pesa service status
- Use query transaction status to verify

### Issue: Duplicate transaction error (INS-10)

**Cause**: Same reference used multiple times

**Solution**:
- Generate unique transaction references using UUID
- Implement transaction deduplication on backend

## Production Deployment

### Checklist

- [ ] Update API key to production key
- [ ] Set `sandbox: false` in provider
- [ ] Implement secure storage for API key (don't hardcode)
- [ ] Add Firebase crash reporting
- [ ] Implement transaction logging
- [ ] Add user consent for payment
- [ ] Test with real payments (minimum amount)
- [ ] Set up transaction reconciliation
- [ ] Add webhook handler for async responses
- [ ] Implement proper error handling UI
- [ ] Test on real devices (iOS & Android)

### Backend Integration

For async payment notifications, implement a webhook endpoint:

```dart
// Example endpoint
POST /api/vodacom/webhook
{
  "input_OriginalConversationID": "fd1e9143d22544459f7c66e1860ef276",
  "input_TransactionID": "hv9ahxcg4ccv",
  "input_ResultCode": "INS-0",
  "input_ResultDesc": "Request processed successfully",
  "input_ThirdPartyConversationID": "1e9b774d1da34af78412a498cbc28f5e"
}
```

Your server should:
1. Validate the request signature
2. Update transaction status in database
3. Send notification to user
4. Return confirmation response

## Support & References

- **M-Pesa OpenAPI Documentation**: https://developer.mpesa.vm.co.tz/
- **Vodacom Tanzania**: https://www.vodacom.tz/
- **Flutter Riverpod Docs**: https://riverpod.dev/
- **PointyCastle Docs**: https://github.com/bcgit/pc-dart

## Version History

### v1.0.0 (Current)
- Initial Vodacom C2B integration
- Session key generation and caching
- C2B single-stage payment
- Transaction status query
- RSA encryption utility
- Riverpod state management
- Error handling and validation

## Contributing

When making changes to Vodacom integration:
1. Follow existing code structure
2. Update both encryption and API service as needed
3. Add unit tests for encryption logic
4. Test with sandbox first
5. Document API changes
