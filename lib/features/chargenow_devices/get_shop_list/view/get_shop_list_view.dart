import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_chaja/features/chargenow_devices/get_shop_list/provider/get_shop_list_provider.dart';
import 'package:smart_chaja/features/chargenow_devices/get_shop_list/view_models/get_shop_list_state.dart';

class GetShopListView extends ConsumerWidget {
  const GetShopListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopListState = ref.watch(getShopListViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Shop List')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: shopListState.status == GetShopListStatus.loading
                  ? null
                  : () {
                      ref.read(getShopListViewModelProvider.notifier).fetchShopList();
                    },
              child: shopListState.status == GetShopListStatus.loading
                  ? const CircularProgressIndicator()
                  : const Text('Fetch Shop List'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: shopListState.status == GetShopListStatus.success && shopListState.shops != null
                  ? shopListState.shops!.isEmpty
                      ? const Center(child: Text('No shops found'))
                      : ListView.builder(
                          itemCount: shopListState.shops!.length,
                          itemBuilder: (context, index) {
                            final shop = shopListState.shops![index];
                            return Card(
                              child: ListTile(
                                title: Text('Shop: ${shop['pName'] ?? 'Unknown'}'),
                                subtitle: Text('Details: ${shop.toString()}'),
                              ),
                            );
                          },
                        )
                  : shopListState.status == GetShopListStatus.error && shopListState.errorMsg != null
                      ? Text('Error: ${shopListState.errorMsg}', style: const TextStyle(color: Colors.red))
                      : const Center(child: Text('Press the button to fetch shops')),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(getShopListViewModelProvider.notifier).resetState();
              },
              child: const Text('Reset'),
            ),
          ],
        ),
      ),
    );
  }
}