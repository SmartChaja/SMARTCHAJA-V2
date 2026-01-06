import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_chaja/features/chargenow_devices/delete_shop/provider/delete_shop_provider.dart';
import 'package:smart_chaja/features/chargenow_devices/delete_shop/view_models/delete_shop_state.dart';

class DeleteShopView extends ConsumerStatefulWidget {
  const DeleteShopView({super.key});

  @override
  ConsumerState<DeleteShopView> createState() => _DeleteShopViewState();
}

class _DeleteShopViewState extends ConsumerState<DeleteShopView> {
  final TextEditingController _shopIdController = TextEditingController();

  @override
  void dispose() {
    _shopIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deleteShopState = ref.watch(deleteShopViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Delete Shop')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _shopIdController,
              decoration: const InputDecoration(labelText: 'Shop ID'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: deleteShopState.status == DeleteShopStatus.loading
                  ? null
                  : () {
                      ref.read(deleteShopViewModelProvider.notifier).deleteShop(_shopIdController.text);
                    },
              child: deleteShopState.status == DeleteShopStatus.loading
                  ? const CircularProgressIndicator()
                  : const Text('Delete Shop'),
            ),
            const SizedBox(height: 16),
            if (deleteShopState.status == DeleteShopStatus.success && deleteShopState.deleteShopResponse != null)
              Text('Success: Shop deleted successfully. ${deleteShopState.deleteShopResponse!.data?.toString() ?? ''}'),
            if (deleteShopState.status == DeleteShopStatus.error && deleteShopState.errorMsg != null)
              Text('Error: ${deleteShopState.errorMsg}', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(deleteShopViewModelProvider.notifier).resetState();
                _shopIdController.clear();
              },
              child: const Text('Reset'),
            ),
          ],
        ),
      ),
    );
  }
}