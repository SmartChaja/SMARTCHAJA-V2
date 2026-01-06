import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_chaja/features/chargenow_devices/order_list/provider/order_list_provider.dart';
import 'package:smart_chaja/features/chargenow_devices/order_list/view_models/order_list_state.dart';

class OrderListView extends ConsumerStatefulWidget {
  const OrderListView({super.key});

  @override
  ConsumerState<OrderListView> createState() => _OrderListViewState();
}

class _OrderListViewState extends ConsumerState<OrderListView> {
  final TextEditingController _dataLevelController = TextEditingController();
  final TextEditingController _sTimeController = TextEditingController();
  final TextEditingController _eTimeController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9) {
        ref.read(orderListViewModelProvider.notifier).fetchOrderList(
              dataLevel: int.tryParse(_dataLevelController.text),
              sTime: _sTimeController.text.isEmpty ? null : _sTimeController.text,
              eTime: _eTimeController.text.isEmpty ? null : _eTimeController.text,
              isLoadMore: true,
            );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _dataLevelController.dispose();
    _sTimeController.dispose();
    _eTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderListState = ref.watch(orderListViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Order List')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _dataLevelController,
              decoration: const InputDecoration(labelText: 'Data Level (optional, 1-3)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _sTimeController,
              decoration: const InputDecoration(labelText: 'Start Time (optional)'),
            ),
            TextField(
              controller: _eTimeController,
              decoration: const InputDecoration(labelText: 'End Time (optional)'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: orderListState.status == OrderListStatus.loading
                  ? null
                  : () {
                      ref.read(orderListViewModelProvider.notifier).fetchOrderList(
                            dataLevel: int.tryParse(_dataLevelController.text),
                            sTime: _sTimeController.text.isEmpty ? null : _sTimeController.text,
                            eTime: _eTimeController.text.isEmpty ? null : _eTimeController.text,
                          );
                    },
              child: orderListState.status == OrderListStatus.loading
                  ? const CircularProgressIndicator()
                  : const Text('Fetch Order List'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: orderListState.records.isEmpty && orderListState.status != OrderListStatus.error
                  ? const Center(child: Text('No orders found'))
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: orderListState.records.length + (orderListState.status == OrderListStatus.loadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == orderListState.records.length) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final order = orderListState.records[index];
                        return Card(
                          child: ListTile(
                            title: Text('Order: ${order['orderId'] ?? 'Unknown'}'),
                            subtitle: Text('Details: ${order.toString()}'),
                          ),
                        );
                      },
                    ),
            ),
            if (orderListState.status == OrderListStatus.error && orderListState.errorMsg != null)
              Text('Error: ${orderListState.errorMsg}', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(orderListViewModelProvider.notifier).resetState();
                _dataLevelController.clear();
                _sTimeController.clear();
                _eTimeController.clear();
              },
              child: const Text('Reset'),
            ),
          ],
        ),
      ),
    );
  }
}