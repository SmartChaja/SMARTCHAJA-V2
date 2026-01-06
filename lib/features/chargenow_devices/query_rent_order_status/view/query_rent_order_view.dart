import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Ensure these imports are correct based on your project structure
import 'package:smart_chaja/features/chargenow_devices/query_rent_order_status/provider/query_rent_order_provider.dart';
import 'package:smart_chaja/features/chargenow_devices/query_rent_order_status/view_models/query_rent_order_state.dart';

class QueryRentOrderView extends ConsumerWidget {
  final TextEditingController _tradeNoController = TextEditingController();

  QueryRentOrderView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queryState = ref.watch(queryRentOrderViewModelProvider);
    final theme = Theme.of(context);

    // Listen for state changes to show SnackBar messages for success/error
    ref.listen<QueryRentOrderState>(queryRentOrderViewModelProvider,
        (previous, current) {
      // Show success SnackBar only when status changes from non-success to success
      if (previous?.status != QueryRentOrderStatus.success &&
          current.status == QueryRentOrderStatus.success) {
        // Construct a more descriptive success message if 'data' is available
        String successMessage = 'Order queried successfully.';
        if (current.queryResponse?.data != null) {
          // If queryResponse.data is a complex object (e.g., Map),
          // you might want to format it more nicely here.
          // For simplicity, using toString() for now.
          successMessage +=
              '\nDetails: ${current.queryResponse!.data.toString()}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: Colors.green, // A distinct color for success
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating, // Makes it float above content
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
      // Show error SnackBar only when status changes from non-error to error
      else if (previous?.status != QueryRentOrderStatus.error &&
          current.status == QueryRentOrderStatus.error &&
          current.errorMsg != null) {
        // Only show SnackBar for general errors, not for specific input validation
        // (e.g., "Trade No is required" is already handled by the TextField's errorText)
        if (!current.errorMsg!.contains('Trade No is required')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(current.errorMsg!),
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
        title: const Text('Query Rent Order'),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primary, // Primary color for app bar
        foregroundColor:
            theme.colorScheme.onPrimary, // Text color on primary background
        elevation: 2, // Slight elevation for better visual separation
      ),
      body: Stack(
        children: [
          // Main content of the page, wrapped in SingleChildScrollView
          SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Introductory text for the form
                Text(
                  'Enter the Trade No to query the status of a specific rent order.',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Card containing the order details input field
                Card(
                  elevation: 4, // More pronounced elevation for the card
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          16)), // Softer, more modern corners
                  clipBehavior: Clip
                      .antiAlias, // Ensures content respects the border radius
                  child: Padding(
                    padding: const EdgeInsets.all(
                        20.0), // Increased internal padding
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rent Order Information',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700, // Bolder title
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const Divider(
                            height: 32, thickness: 1), // Visual separator
                        const SizedBox(height: 8),

                        // Trade No TextField
                        TextField(
                          controller: _tradeNoController,
                          decoration: InputDecoration(
                            labelText: 'Trade No',
                            hintText: 'e.g., 25080117554664305402',
                            border: OutlineInputBorder(
                              // Standard outlined border
                              borderRadius: BorderRadius.circular(
                                  12), // Consistent border radius
                            ),
                            enabledBorder: OutlineInputBorder(
                              // Default border style
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: theme.colorScheme.outline),
                            ),
                            focusedBorder: OutlineInputBorder(
                              // Focused border style
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: theme.colorScheme.primary,
                                  width: 2), // Thicker primary color border
                            ),
                            errorBorder: OutlineInputBorder(
                              // Error border style
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: theme.colorScheme.error,
                                  width: 2), // Thicker error color border
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              // Focused error border style
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: theme.colorScheme.error, width: 2),
                            ),
                            prefixIcon: Icon(Icons.receipt_long_outlined,
                                color:
                                    theme.colorScheme.primary), // Themed icon
                            helperText:
                                'Enter the unique transaction number for the rent order.',
                            errorText: queryState.status ==
                                        QueryRentOrderStatus.error &&
                                    queryState.errorMsg?.contains(
                                            'Trade No is required') ==
                                        true
                                ? 'Trade No is required'
                                : null,
                          ),
                          keyboardType: TextInputType.text,
                          onChanged: (_) {
                            // Clear the "Trade No is required" error when the user starts typing
                            if (queryState.status ==
                                    QueryRentOrderStatus.error &&
                                queryState.errorMsg
                                        ?.contains('Trade No is required') ==
                                    true) {
                              // Reset state to clear the error message associated with the provider
                              ref
                                  .read(
                                      queryRentOrderViewModelProvider.notifier)
                                  .resetState();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Query Order Button
                ElevatedButton.icon(
                  // Using an icon button for better clarity
                  onPressed: queryState.status == QueryRentOrderStatus.loading
                      ? null // Disable button when loading
                      : () {
                          ref
                              .read(queryRentOrderViewModelProvider.notifier)
                              .queryRentOrder(
                                tradeNo: _tradeNoController.text.trim(),
                              );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                        vertical: 18), // Increased padding
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12)), // Consistent radius
                    elevation: 4, // Adds more shadow
                    textStyle: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  icon: const Icon(Icons.search), // Search icon
                  label: const Text('Query Order'),
                ),
                const SizedBox(height: 16),

                // Reset Button
                OutlinedButton.icon(
                  // Using an icon button
                  onPressed: () {
                    ref
                        .read(queryRentOrderViewModelProvider.notifier)
                        .resetState(); // Reset provider state
                    _tradeNoController.clear(); // Clear text fields
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
                    side: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 2), // Thicker border
                    foregroundColor: theme.colorScheme.primary,
                    textStyle: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  icon: const Icon(Icons.refresh), // Reset icon
                  label: const Text('Reset Form'),
                ),
                // Note: The original _buildStatusMessage widget and its calls are removed
                // because SnackBar is now used for status feedback.
                // If a detailed display of the order status (beyond a simple message)
                // is needed, you would add a new widget here, conditionally rendered
                // when queryState.status == QueryRentOrderStatus.success and
                // queryState.queryResponse?.data is not null.
              ],
            ),
          ),

          // Loading Indicator Overlay
          // Uses AnimatedOpacity for a smooth fade-in/out effect
          AnimatedOpacity(
            opacity:
                queryState.status == QueryRentOrderStatus.loading ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300), // Animation duration
            curve: Curves.easeInOut, // Smooth animation curve
            child: IgnorePointer(
              // Prevents interaction with UI below when loading
              ignoring: queryState.status != QueryRentOrderStatus.loading,
              child: Container(
                color: Colors.black
                    .withOpacity(0.4), // Semi-transparent dark overlay
                child: Center(
                  child: Card(
                    elevation: 10, // High elevation for the loading card
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(20)), // Very rounded
                    child: Padding(
                      padding: const EdgeInsets.all(32.0), // Generous padding
                      child: Column(
                        mainAxisSize: MainAxisSize.min, // Wrap content tightly
                        children: [
                          SizedBox(
                            width: 60, // Larger progress indicator
                            height: 60,
                            child: CircularProgressIndicator(
                              strokeWidth: 5, // Thicker stroke for visibility
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.colorScheme.primary), // Themed color
                            ),
                          ),
                          const SizedBox(height: 24), // Spacing
                          Text(
                            'Querying Order...',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              // Larger, more prominent text
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please wait while the order status is fetched.',
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
}
