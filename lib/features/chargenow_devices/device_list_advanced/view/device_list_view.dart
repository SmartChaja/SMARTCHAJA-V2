import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_chaja/features/chargenow_devices/device_list_advanced/provider/device_list_provider.dart';
import 'package:smart_chaja/features/chargenow_devices/device_list_advanced/view_models/device_list_state.dart';

class DeviceListView extends ConsumerWidget {
  const DeviceListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceListState = ref.watch(deviceListViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Device List')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: deviceListState.status == DeviceListStatus.loading
                  ? null
                  : () {
                      ref.read(deviceListViewModelProvider.notifier).fetchAllDevices();
                    },
              child: deviceListState.status == DeviceListStatus.loading
                  ? const CircularProgressIndicator()
                  : const Text('Fetch Device List'),
            ),
            const SizedBox(height: 16),
            if (deviceListState.status == DeviceListStatus.success &&
                deviceListState.deviceListResponse?.data != null)
              Expanded(
                child: ListView.builder(
                  itemCount: deviceListState.deviceListResponse!.data!.length,
                  itemBuilder: (context, index) {
                    final device = deviceListState.deviceListResponse!.data![index];
                    return Card(
                      child: ListTile(
                        title: Text('Cabinet ID: ${device.pCabinetid ?? 'Unknown'}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Type: ${device.pType ?? 'Unknown'}'),
                            Text('Total Slots: ${device.pTotal ?? 0}'),
                            Text('Available to Borrow: ${device.pBorrow ?? 0}'),
                            Text('Available to Return: ${device.pAlso ?? 0}'),
                            Text('Status: ${device.pInfostatus ?? 'Unknown'}'),
                            Text('Signal: ${device.pSignal ?? 'Unknown'}'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            if (deviceListState.status == DeviceListStatus.error && deviceListState.errorMsg != null)
              Text('Error: ${deviceListState.errorMsg}', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(deviceListViewModelProvider.notifier).resetState();
              },
              child: const Text('Reset'),
            ),
          ],
        ),
      ),
    );
  }
}