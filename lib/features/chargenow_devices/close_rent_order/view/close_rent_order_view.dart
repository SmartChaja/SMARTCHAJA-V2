import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_chaja/features/chargenow_devices/close_rent_order/provider/close_rent_order_provider.dart';
import 'package:smart_chaja/features/chargenow_devices/close_rent_order/view_models/close_rent_order_state.dart';

class CloseRentOrderView extends ConsumerWidget {
  final TextEditingController _tradeNoController = TextEditingController();

  CloseRentOrderView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final closeState = ref.watch(closeRentOrderViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Close Rent Order')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _tradeNoController,
              decoration: const InputDecoration(labelText: 'Trade No'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: closeState.status == CloseRentOrderStatus.loading
                  ? null
                  : () {
                      ref.read(closeRentOrderViewModelProvider.notifier).closeRentOrder(
                            tradeNo: _tradeNoController.text,
                          );
                    },
              child: closeState.status == CloseRentOrderStatus.loading
                  ? const CircularProgressIndicator()
                  : const Text('Close Order'),
            ),
            const SizedBox(height: 16),
            if (closeState.status == CloseRentOrderStatus.success && closeState.closeResponse != null)
              Text('Success: Order closed successfully. ${closeState.closeResponse!.data?.toString() ?? ''}'),
            if (closeState.status == CloseRentOrderStatus.error && closeState.errorMsg != null)
              Text('Error: ${closeState.errorMsg}', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(closeRentOrderViewModelProvider.notifier).resetState();
                _tradeNoController.clear();
              },
              child: const Text('Reset'),
            ),
          ],
        ),
      ),
    );
  }
}