import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_chaja/features/chargenow_devices/get_order_detail/model/get_order_detail_response.dart';
import 'package:smart_chaja/features/chargenow_devices/get_order_detail/provider/get_order_detail_provider.dart';
import 'package:smart_chaja/features/chargenow_devices/get_order_detail/view_models/get_order_detail_state.dart';
import 'package:intl/intl.dart'; // For date formatting (ensure intl is in pubspec.yaml)

class GetOrderDetailView extends ConsumerWidget {
  final TextEditingController _tradeNoController = TextEditingController();

  GetOrderDetailView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = ref.watch(getOrderDetailViewModelProvider);
    final theme = Theme.of(context);

    // Listen for state changes to show SnackBar messages for success/error
    ref.listen<GetOrderDetailState>(getOrderDetailViewModelProvider,
        (previous, current) {
      // Show success SnackBar only when status changes from non-success to success
      if (previous?.status != GetOrderDetailStatus.success &&
          current.status == GetOrderDetailStatus.success &&
          current.detailResponse?.data != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Order details fetched successfully!',
              style: TextStyle(color: theme.colorScheme.onPrimary),
            ),
            backgroundColor: Colors.green, // A distinct color for success
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
      // Show error SnackBar only when status changes from non-error to error
      else if (previous?.status != GetOrderDetailStatus.error &&
          current.status == GetOrderDetailStatus.error &&
          current.errorMsg != null) {
        // Only show SnackBar for general errors, not for specific input validation (like empty Trade No)
        if (!current.errorMsg!.contains('Trade No cannot be empty.')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error: ${current.errorMsg!}',
                style: TextStyle(color: theme.colorScheme.onError),
              ),
              backgroundColor: theme.colorScheme.error, // Theme's error color
              duration: const Duration(seconds: 5),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 2,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Retrieve detailed information about a specific rent order.',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Card for Trade No Input
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Enter Trade Number',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const Divider(height: 32, thickness: 1),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _tradeNoController,
                          decoration: InputDecoration(
                            labelText: 'Trade No',
                            hintText: 'e.g., 25080117554664305402',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: theme.colorScheme.outline),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: theme.colorScheme.primary, width: 2),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: theme.colorScheme.error, width: 2),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: theme.colorScheme.error, width: 2),
                            ),
                            prefixIcon: Icon(Icons.confirmation_number_outlined,
                                color: theme.colorScheme.primary),
                            helperText:
                                'Required to fetch specific order details.',
                            errorText: detailState.status ==
                                        GetOrderDetailStatus.error &&
                                    detailState.errorMsg?.contains(
                                            'Trade No cannot be empty.') ==
                                        true
                                ? 'Trade No is required.'
                                : null,
                          ),
                          keyboardType: TextInputType.text,
                          onChanged: (_) {
                            // Clear the error message when user starts typing if it was related to empty Trade No
                            if (detailState.status ==
                                    GetOrderDetailStatus.error &&
                                detailState.errorMsg?.contains(
                                        'Trade No cannot be empty.') ==
                                    true) {
                              ref
                                  .read(
                                      getOrderDetailViewModelProvider.notifier)
                                  .resetState();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Fetch Order Details Button
                ElevatedButton.icon(
                  onPressed: detailState.status == GetOrderDetailStatus.loading
                      ? null
                      : () {
                          ref
                              .read(getOrderDetailViewModelProvider.notifier)
                              .getOrderDetail(
                                tradeNo: _tradeNoController.text.trim(),
                              );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                    textStyle: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: const Text('Fetch Order Details'),
                ),
                const SizedBox(height: 16),

                // Reset Button
                OutlinedButton.icon(
                  onPressed: () {
                    ref
                        .read(getOrderDetailViewModelProvider.notifier)
                        .resetState();
                    _tradeNoController.clear();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Form has been reset.'),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        margin: const EdgeInsets.all(16),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    side:
                        BorderSide(color: theme.colorScheme.primary, width: 2),
                    foregroundColor: theme.colorScheme.primary,
                    textStyle: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset Form'),
                ),
                const SizedBox(height: 32),

                // Display Order Details
                if (detailState.status == GetOrderDetailStatus.success &&
                    detailState.detailResponse?.data != null)
                  _buildOrderDetailCard(
                      context, detailState.detailResponse!.data!, theme),
              ],
            ),
          ),

          // Loading Indicator Overlay
          AnimatedOpacity(
            opacity:
                detailState.status == GetOrderDetailStatus.loading ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: IgnorePointer(
              ignoring: detailState.status != GetOrderDetailStatus.loading,
              child: Container(
                color: Colors.black.withOpacity(0.4),
                child: Center(
                  child: Card(
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 60,
                            height: 60,
                            child: CircularProgressIndicator(
                              strokeWidth: 5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.colorScheme.primary),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Fetching Order Details...',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please wait while the order information is retrieved.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget to build the order details display card
  Widget _buildOrderDetailCard(
      BuildContext context, OrderDetailData data, ThemeData theme) {
    // Helper to format date/time strings
    String formatDateTime(String? dateTimeString) {
      if (dateTimeString == null || dateTimeString.isEmpty) return 'N/A';
      try {
        final dateTime = DateTime.parse(dateTimeString);
        return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
      } catch (e) {
        return dateTimeString; // Return as-is if parsing fails
      }
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Details',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
            const Divider(height: 32, thickness: 1),
            _buildDetailRow(context, 'Order ID', data.orderId, theme),
            _buildDetailRow(context, 'Order Type', data.orderType,
                theme), // New field for display
            _buildDetailRow(context, 'Cabinet ID', data.cabinetId, theme),
            _buildDetailRow(context, 'Battery ID', data.batteryId, theme),
            _buildDetailRow(context, 'Device Type', data.deviceType, theme),
            _buildDetailRow(
                context, 'Borrow Slot', data.borrowSlot.toString(), theme),
            _buildDetailRow(context, 'Borrow Status',
                _getBorrowStatusText(data.borrowStatus), theme),
            _buildDetailRow(
                context, 'Borrow Time', formatDateTime(data.borrowTime), theme),
            _buildDetailRow(
                context, 'Return Time', formatDateTime(data.returnTime), theme),
            _buildDetailRow(
                context, 'Price Per Minute', data.priceMinute, theme),
            _buildDetailRow(
                context, 'Price', '${data.price} ${data.currency}', theme),
            _buildDetailRow(context, 'Daily Max Price',
                '${data.dailyMaxPrice} ${data.currency}', theme),
            _buildDetailRow(
                context, 'Free Minutes', '${data.freeMinutes} mins', theme),
            _buildDetailRow(context, 'Order Amount',
                '${data.orderAmount} ${data.currency}', theme),
            _buildDetailRow(
                context, 'Deposit', '${data.deposit} ${data.currency}', theme),
          ],
        ),
      ),
    );
  }

  // Helper widget for a single detail row
  Widget _buildDetailRow(
      BuildContext context, String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value.isNotEmpty
                  ? value
                  : 'N/A', // Display 'N/A' for empty values
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper to interpret borrow status
  String _getBorrowStatusText(int status) {
    // These mappings are based on common API patterns and your provided comment "0. Not leased, 1. Under lease, 2. Revoked, 3. Returned, 4. In doubt, 5. Timeout is returned. 6. Charging is suspended"
    switch (status) {
      case 0:
        return 'Not Leased';
      case 1:
        return 'Under Lease';
      case 2:
        return 'Revoked';
      case 3:
        return 'Returned';
      case 4:
        return 'In Doubt';
      case 5:
        return 'Timeout Returned';
      case 6:
        return 'Charging Suspended';
      default:
        return 'Unknown ($status)';
    }
  }
}
