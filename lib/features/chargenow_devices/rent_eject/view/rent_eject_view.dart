import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_chaja/features/chargenow_devices/rent_eject/provider/rent_eject_provider.dart';
import 'package:smart_chaja/features/chargenow_devices/rent_eject/view_models/rent_eject_state.dart';

class RentEjectView extends ConsumerStatefulWidget {
  const RentEjectView({super.key});

  @override
  ConsumerState<RentEjectView> createState() => _RentEjectViewState();
}

class _RentEjectViewState extends ConsumerState<RentEjectView> {
  final TextEditingController _cabinetIdController = TextEditingController();
  final TextEditingController _rentOrderIdController = TextEditingController();
  final TextEditingController _slotNumController = TextEditingController();

  final _formKey = GlobalKey<FormState>(); // Added for form validation

  @override
  void dispose() {
    _cabinetIdController.dispose();
    _rentOrderIdController.dispose();
    _slotNumController.dispose();
    super.dispose();
  }

  // Helper function to show SnackBar
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar(); // Hide previous snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: isError ? Colors.red[700] : Colors.green[700],
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating, // Makes it float above content
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to state changes for SnackBar feedback
    ref.listen<RentEjectState>(
      rentEjectViewModelProvider,
      (previous, current) {
        if (current.status == RentEjectStatus.success) {
          _showSnackBar("Success: Battery rented and ejected!", isError: false);
          // Optionally clear fields on success
          _cabinetIdController.clear();
          _rentOrderIdController.clear();
          _slotNumController.clear();
        } else if (current.status == RentEjectStatus.error) {
          _showSnackBar(
              "Error: ${current.errorMsg ?? 'An unknown error occurred'}",
              isError: true);
        }
      },
    );

    final rentEjectState = ref.watch(rentEjectViewModelProvider);
    final isLoading = rentEjectState.status == RentEjectStatus.loading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rent and Eject Battery'),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        // Added for scrollability
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch, // Stretch children to fill width
            children: [
              // Loading Indicator
              if (isLoading) const LinearProgressIndicator(),
              if (isLoading) const SizedBox(height: 16),

              TextFormField(
                controller: _cabinetIdController,
                decoration: const InputDecoration(
                  labelText: 'Cabinet ID',
                  hintText: 'e.g., DTA28688',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.cabin),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Cabinet ID cannot be empty';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _rentOrderIdController,
                decoration: const InputDecoration(
                  labelText: 'Rent Order ID',
                  hintText: 'e.g., 25080117554664305402',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.receipt),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Rent Order ID cannot be empty';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _slotNumController,
                decoration: const InputDecoration(
                  labelText: 'Slot Number',
                  hintText: 'e.g., 5',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.numbers),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Slot Number cannot be empty';
                  }
                  if (int.tryParse(value.trim()) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              ElevatedButton.icon(
                onPressed: isLoading
                    ? null // Disable button when loading
                    : () {
                        if (_formKey.currentState!.validate()) {
                          ref
                              .read(rentEjectViewModelProvider.notifier)
                              .rentEjectBattery(
                                cabinetId: _cabinetIdController.text,
                                rentOrderId: _rentOrderIdController.text,
                                slotNum: _slotNumController.text,
                              );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Theme.of(context)
                      .primaryColor
                      .withOpacity(0.5), // Lighter disabled color
                ),
                icon: const Icon(Icons.battery_charging_full),
                label: const Text(
                  'Rent and Eject Battery',
                  style: TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 20),

              // Persistent status message display
              if (rentEjectState.status == RentEjectStatus.success)
                Card(
                  color: Colors.green.shade50,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: Colors.green, width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle,
                            color: Colors.green[700], size: 28),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Battery rented and ejected successfully. Data: ${rentEjectState.rentEjectResponse!.data?.toString() ?? 'N/A'}',
                            style: TextStyle(
                                color: Colors.green[900], fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (rentEjectState.status == RentEjectStatus.error &&
                  rentEjectState.errorMsg != null)
                Card(
                  color: Colors.red.shade50,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: Colors.red, width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.error, color: Colors.red[700], size: 28),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Error: ${rentEjectState.errorMsg}',
                            style:
                                TextStyle(color: Colors.red[900], fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              OutlinedButton.icon(
                onPressed: () {
                  ref.read(rentEjectViewModelProvider.notifier).resetState();
                  _cabinetIdController.clear();
                  _rentOrderIdController.clear();
                  _slotNumController.clear();
                  _formKey.currentState?.reset(); // Clear validation errors
                  ScaffoldMessenger.of(context)
                      .hideCurrentSnackBar(); // Hide any active snackbar
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  side: BorderSide(color: Theme.of(context).primaryColor),
                  foregroundColor: Theme.of(context).primaryColor,
                ),
                icon: const Icon(Icons.refresh),
                label: const Text(
                  'Reset / Clear Fields',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
