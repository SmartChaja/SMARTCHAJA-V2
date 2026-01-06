import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_chaja/features/chargenow_devices/eject_battery_slot/provider/eject_battery_provider.dart';
import 'package:smart_chaja/features/chargenow_devices/eject_battery_slot/view_models/eject_battery_state.dart';

class EjectBatteryView extends ConsumerWidget {
  final TextEditingController _cabinetIdController = TextEditingController();
  final TextEditingController _slotNumController = TextEditingController();

  EjectBatteryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ejectState = ref.watch(ejectBatteryViewModelProvider);
    final theme = Theme.of(context);

    // Listen for state changes to show SnackBar messages for success/error
    ref.listen<EjectBatteryState>(ejectBatteryViewModelProvider,
        (previous, current) {
      // Show success SnackBar only when status changes from non-success to success
      if (previous?.status != EjectBatteryStatus.success &&
          current.status == EjectBatteryStatus.success &&
          current.ejectResponse != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Battery ejected successfully. ${current.ejectResponse!.data is bool ? 'Operation completed' : current.ejectResponse!.data?.toString() ?? ''}',
            ),
            backgroundColor: Colors.green, // A distinct color for success
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating, // Makes it float above content
          ),
        );
      }
      // Show error SnackBar only when status changes from non-error to error
      else if (previous?.status != EjectBatteryStatus.error &&
          current.status == EjectBatteryStatus.error &&
          current.errorMsg != null) {
        // Only show SnackBar for general errors, not for specific input validation
        // (e.g., "Cabinet ID is required" is handled by the TextField's errorText)
        if (!current.errorMsg!.contains('Cabinet ID is required')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(current.errorMsg!),
              backgroundColor: theme.colorScheme.error, // Theme's error color
              duration: const Duration(seconds: 5),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Eject Battery'),
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
                  'Enter details to eject a battery from the charging cabinet.',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Card containing the battery details input fields
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
                          'Battery Slot Information',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700, // Bolder title
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const Divider(
                            height: 32, thickness: 1), // Visual separator
                        const SizedBox(height: 8),

                        // Cabinet ID TextField
                        TextField(
                          controller: _cabinetIdController,
                          decoration: InputDecoration(
                            labelText: 'Cabinet ID',
                            hintText: 'e.g., DTA28688',
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
                            prefixIcon: Icon(Icons.charging_station_outlined,
                                color:
                                    theme.colorScheme.primary), // Themed icon
                            helperText:
                                'Required to identify the charging station.',
                            errorText:
                                ejectState.status == EjectBatteryStatus.error &&
                                        ejectState.errorMsg?.contains(
                                                'Cabinet ID is required') ==
                                            true
                                    ? 'Cabinet ID is required'
                                    : null,
                          ),
                          keyboardType: TextInputType.text,
                          textCapitalization: TextCapitalization
                              .characters, // Suggests uppercase input
                          onChanged: (_) {
                            // Clear the Cabinet ID error when the user starts typing
                            if (ejectState.status == EjectBatteryStatus.error &&
                                ejectState.errorMsg
                                        ?.contains('Cabinet ID is required') ==
                                    true) {
                              // Reset state to clear the error message associated with the provider
                              ref
                                  .read(ejectBatteryViewModelProvider.notifier)
                                  .resetState();
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        // Slot Number TextField
                        TextField(
                          controller: _slotNumController,
                          decoration: InputDecoration(
                            labelText: 'Slot Number',
                            hintText: 'Optional (leave empty for all slots)',
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
                            prefixIcon: Icon(Icons.battery_full_outlined,
                                color: theme.colorScheme.primary),
                            helperText:
                                'Specify a slot, or leave empty to eject all batteries (if supported).',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Eject Battery Button
                ElevatedButton.icon(
                  // Using an icon button for better clarity
                  onPressed: ejectState.status == EjectBatteryStatus.loading
                      ? null // Disable button when loading
                      : () {
                          ref
                              .read(ejectBatteryViewModelProvider.notifier)
                              .ejectBattery(
                                cabinetId: _cabinetIdController.text.trim(),
                                slotNum: _slotNumController.text.isEmpty
                                    ? null
                                    : _slotNumController.text.trim(),
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
                  icon: const Icon(Icons
                      .power_settings_new), // More relevant icon for ejecting
                  label: const Text('Eject Battery'),
                ),
                const SizedBox(height: 16),

                // Reset Button
                OutlinedButton.icon(
                  // Using an icon button
                  onPressed: () {
                    ref
                        .read(ejectBatteryViewModelProvider.notifier)
                        .resetState(); // Reset provider state
                    _cabinetIdController.clear(); // Clear text fields
                    _slotNumController.clear();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Form has been reset.'),
                        duration: Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
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
              ],
            ),
          ),

          // Loading Indicator Overlay
          // Uses AnimatedOpacity for a smooth fade-in/out effect
          AnimatedOpacity(
            opacity:
                ejectState.status == EjectBatteryStatus.loading ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300), // Animation duration
            curve: Curves.easeInOut, // Smooth animation curve
            child: IgnorePointer(
              // Prevents interaction with UI below when loading
              ignoring: ejectState.status != EjectBatteryStatus.loading,
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
                            'Ejecting Battery...',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              // Larger, more prominent text
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please wait while the command is processed.',
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
