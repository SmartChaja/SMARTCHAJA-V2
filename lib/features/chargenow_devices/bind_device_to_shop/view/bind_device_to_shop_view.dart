import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_chaja/features/chargenow_devices/bind_device_to_shop/provider/bind_device_to_shop_provider.dart';
import 'package:smart_chaja/features/chargenow_devices/bind_device_to_shop/view_models/bind_device_to_shop_state.dart';

class BindDeviceToShopView extends ConsumerStatefulWidget {
  const BindDeviceToShopView({super.key});

  @override
  ConsumerState<BindDeviceToShopView> createState() => _BindDeviceToShopViewState();
}

class _BindDeviceToShopViewState extends ConsumerState<BindDeviceToShopView> {
  final TextEditingController _qrCodeController = TextEditingController();
  final TextEditingController _shopIdController = TextEditingController();

  @override
  void dispose() {
    _qrCodeController.dispose();
    _shopIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bindDeviceToShopState = ref.watch(bindDeviceToShopViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Bind Device to Shop')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _qrCodeController,
              decoration: const InputDecoration(labelText: 'Device ID or QR Code'),
            ),
            TextField(
              controller: _shopIdController,
              decoration: const InputDecoration(labelText: 'Shop ID'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: bindDeviceToShopState.status == BindDeviceToShopStatus.loading
                  ? null
                  : () {
                      ref
                          .read(bindDeviceToShopViewModelProvider.notifier)
                          .bindDeviceToShop(_qrCodeController.text, _shopIdController.text);
                    },
              child: bindDeviceToShopState.status == BindDeviceToShopStatus.loading
                  ? const CircularProgressIndicator()
                  : const Text('Bind Device'),
            ),
            const SizedBox(height: 16),
            if (bindDeviceToShopState.status == BindDeviceToShopStatus.success &&
                bindDeviceToShopState.bindDeviceToShopResponse != null)
              Text(
                  'Success: Device bound to shop successfully. ${bindDeviceToShopState.bindDeviceToShopResponse!.data?.toString() ?? ''}'),
            if (bindDeviceToShopState.status == BindDeviceToShopStatus.error &&
                bindDeviceToShopState.errorMsg != null)
              Text('Error: ${bindDeviceToShopState.errorMsg}', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(bindDeviceToShopViewModelProvider.notifier).resetState();
                _qrCodeController.clear();
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