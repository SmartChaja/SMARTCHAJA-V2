## Vodacom C2B Payment Integration - Quick Start Guide

### Files Created

Your Vodacom payment integration has been created in:
```
lib/features/chargenow_devices/payment/vodacom/
├── model/
│   └── vodacom_payment_model.dart
├── service/
│   ├── encryption_service.dart
│   └── vodacom_payment_service.dart
├── response/
│   └── vodacom_payment_result.dart
├── provider/
│   └── vodacom_payment_providers.dart
├── view_model/
│   └── vodacom_payment_view_model.dart
├── example_usage.dart
└── VODACOM_INTEGRATION_GUIDE.md
```

### Step 1: Install Dependencies

```bash
cd /Users/beginnertech/Documents/Code/Project/SMARTCHAJA/SMARTCHAJA-V2
flutter pub get
```

### Step 2: Update Your pubspec.yaml

The following dependencies have been added:
```yaml
dependencies:
  pointycastle: ^3.8.0
  crypto: ^3.0.3
```

### Step 3: Basic Implementation

#### In Your Payment Selection Screen:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_chaja/features/chargenow_devices/payment/vodacom/provider/vodacom_payment_providers.dart';

class PaymentMethodSelector extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () => navigateToVodacomPayment(context, ref),
          child: const Text('Pay with Vodacom'),
        ),
        // Add other payment methods...
      ],
    );
  }

  void navigateToVodacomPayment(BuildContext context, WidgetRef ref) {
    // Navigate to payment screen or show payment dialog
    showPaymentDialog(context, ref);
  }
}
```

#### Payment Dialog/Screen:

```dart
void showPaymentDialog(BuildContext context, WidgetRef ref) {
  final amountController = TextEditingController();
  final phoneController = TextEditingController();
  final refController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Vodacom Payment'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Amount (GHS)'),
          ),
          TextField(
            controller: phoneController,
            decoration: const InputDecoration(labelText: 'Phone Number'),
          ),
          TextField(
            controller: refController,
            decoration: const InputDecoration(labelText: 'Reference'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            ref
                .read(vodacomPaymentViewModelProvider.notifier)
                .performC2BPayment(
                  amount: amountController.text,
                  customerMsisdn: phoneController.text,
                  serviceProviderCode: 'ORG001',
                  transactionReference: refController.text,
                  purchasedItemsDesc: 'Wallet Top-up',
                );
            Navigator.pop(context);
          },
          child: const Text('Pay'),
        ),
      ],
    ),
  );
}
```

#### Listen to Payment State:

```dart
class VodacomPaymentListener extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentState = ref.watch(vodacomPaymentViewModelProvider);

    paymentState.whenData((result) {
      if (result != null) {
        if (result.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Payment successful: ${result.message}')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Payment failed: ${result.message}')),
          );
        }
      }
    });

    return paymentState.when(
      data: (result) => result != null
          ? PaymentResultScreen(result: result)
          : const SizedBox(),
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
    );
  }
}
```

### Step 4: Configuration

#### Sandbox Testing (Current Setup)

- API Key: `PnUOd2XmPPD7zVWMyPx3SZuOMmAYAMrX`
- Market: Vodafone Ghana (`vodafoneGHA`)
- Environment: Sandbox (sandbox: true)

#### Production Deployment

Update `vodacom_payment_providers.dart`:
```dart
final vodacomPaymentServiceProvider = Provider<VodacomPaymentService>((ref) {
  return VodacomPaymentService(
    apiKey: productionApiKey, // Get from secure storage
    sandbox: false,            // Set to false
    origin: 'your-domain.com',
  );
});
```

### Step 5: Payment Parameters

When calling `performC2BPayment()`, provide:

| Parameter | Example | Notes |
|-----------|---------|-------|
| amount | "10.00" | Must be numeric string |
| customerMsisdn | "254707161122" | 12-14 digit phone number |
| serviceProviderCode | "ORG001" | 4-12 character code |
| transactionReference | "T12344C" | 1-20 characters, alphanumeric |
| purchasedItemsDesc | "Mobile Wallet Top-up" | 1-256 characters |

### Step 6: Response Handling

#### Success Response
```dart
result.isSuccess  // true
result.transactionId  // "hv9ahxcg4ccv"
result.conversationId  // "fd1e9143d22544459f7c66e1860ef276"
result.message  // "Request processed successfully"
```

#### Error Response
```dart
result.isSuccess  // false
result.message  // Error description
result.responseCode  // "INS-6", "INS-15", etc.
```

### Common Error Codes

| Code | Meaning | Solution |
|------|---------|----------|
| INS-0 | Success | ✓ Payment completed |
| INS-6 | Transaction Failed | Check customer account |
| INS-15 | Invalid Amount | Verify amount format |
| INS-2051 | Invalid Phone | Validate phone number |
| INS-2006 | Insufficient Balance | Customer needs to top-up |

### Security Checklist

- [ ] Remove hardcoded API key (move to Firebase Remote Config or secure storage)
- [ ] Implement request signing for production
- [ ] Add transaction logging to Firebase
- [ ] Implement webhook handler for async payments
- [ ] Test with mock transactions first
- [ ] Add user confirmation before payment
- [ ] Implement transaction reconciliation
- [ ] Monitor for duplicate transactions
- [ ] Set up alerts for failed payments
- [ ] Test error scenarios (network timeout, invalid phone, etc.)

### Testing in Sandbox

1. Use test phone numbers provided by M-Pesa
2. Start with small amounts (e.g., 1 GHS)
3. Check transaction status using conversation ID
4. Monitor for response codes and error messages
5. Test timeout scenarios by delaying responses

### Next Steps

1. **Copy example_usage.dart** to create your actual payment screen
2. **Update payment UI** to use `vodacomPaymentViewModelProvider`
3. **Integrate with wallet** to store transaction records
4. **Add error dialogs** for better UX
5. **Implement transaction history** to track Vodacom payments
6. **Set up backend** to receive async payment notifications

### File Structure for Integration

```
lib/
├── features/
│   └── chargenow_devices/
│       ├── payment/
│       │   ├── azam/              (existing)
│       │   ├── vodacom/           (NEW - integrated above)
│       │   └── screen/
│       │       └── payment_screen.dart  (update to include Vodacom)
│       └── view/                  (add Vodacom payment UI)
```

### Support Resources

- Full documentation: `VODACOM_INTEGRATION_GUIDE.md`
- Example implementation: `example_usage.dart`
- M-Pesa API Docs: https://developer.mpesa.vm.co.tz/
- Flutter Riverpod: https://riverpod.dev/

### Important Notes

1. **Session Key Expiry**: Session keys expire after ~30 seconds. The ViewModel caches them for 25 seconds and auto-regenerates as needed.

2. **Rate Limiting**: M-Pesa may have rate limits. Implement exponential backoff for retries.

3. **Duplicate Transactions**: Always use unique `transactionReference` values. The UUID is generated automatically for `thirdPartyConversationID`.

4. **Network Handling**: Implement proper timeout and retry logic. Default timeout is 30 seconds.

5. **Testing**: Always test with sandbox first before going live.

---

**Integration Date**: March 18, 2026
**Version**: 1.0.0
**Status**: Ready for implementation
