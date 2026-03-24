import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_chaja/features/chargenow_devices/payment/vodacom/provider/vodacom_payment_providers.dart';

/// Example implementation of Vodacom C2B payment in a Flutter widget
class VodacomPaymentExample extends ConsumerWidget {
  const VodacomPaymentExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentState = ref.watch(vodacomPaymentViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vodacom C2B Payment'),
      ),
      body: paymentState.when(
        data: (result) {
          if (result == null) {
            return _buildPaymentForm(context, ref);
          } else {
            return _buildPaymentResult(context, result, ref);
          }
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $error'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  ref.read(vodacomPaymentViewModelProvider.notifier).reset();
                },
                child: const Text('Reset'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentForm(BuildContext context, WidgetRef ref) {
    final amountController = TextEditingController();
    final phoneController = TextEditingController();
    final referenceController = TextEditingController();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Amount (GHS)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.money),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Customer Phone Number',
              hintText: '254707161122',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: referenceController,
            decoration: InputDecoration(
              labelText: 'Transaction Reference',
              hintText: 'T12344C',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.receipt),
            ),
            maxLength: 20,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                final amount = amountController.text;
                final phone = phoneController.text;
                final reference = referenceController.text;

                if (amount.isEmpty || phone.isEmpty || reference.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all fields')),
                  );
                  return;
                }

                ref
                    .read(vodacomPaymentViewModelProvider.notifier)
                    .performC2BPayment(
                      amount: amount,
                      customerMsisdn: phone,
                      serviceProviderCode: 'ORG001',
                      transactionReference: reference,
                      purchasedItemsDesc: 'Mobile Wallet Top-up',
                    );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Pay Now',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentResult(
    BuildContext context,
    result,
    WidgetRef ref,
  ) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              result.isSuccess ? Icons.check_circle : Icons.error,
              size: 80,
              color: result.isSuccess ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              result.isSuccess ? 'Payment Successful' : 'Payment Failed',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: result.isSuccess ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              result.message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            if (result.transactionId != null) ...[
              const SizedBox(height: 16),
              _buildInfoRow('Transaction ID', result.transactionId!),
            ],
            if (result.conversationId != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow('Conversation ID', result.conversationId!),
            ],
            if (result.amount != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow('Amount', '${result.amount} ${result.currency}'),
            ],
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                ref.read(vodacomPaymentViewModelProvider.notifier).reset();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Make Another Payment',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }
}
