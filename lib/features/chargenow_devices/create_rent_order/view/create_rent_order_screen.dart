import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_chaja/app_constants/app_constants.dart';
import 'package:smart_chaja/app_constants/charge_now_api_config.dart';
import 'package:smart_chaja/features/chargenow_devices/create_rent_order/provider/create_rent_order_provider.dart';
import 'package:smart_chaja/features/chargenow_devices/create_rent_order/view/order_feedback_dialog.dart';
import 'package:smart_chaja/features/chargenow_devices/create_rent_order/view/widgets/qr_scanner_view.dart';
import 'package:smart_chaja/features/chargenow_devices/create_rent_order/view/widgets/manual_input_form.dart';
import 'package:smart_chaja/features/chargenow_devices/create_rent_order/view/widgets/plan_selection_dialog.dart';
import 'package:smart_chaja/features/chargenow_devices/create_rent_order/view/widgets/loading_overlay.dart';
import 'package:smart_chaja/features/chargenow_devices/create_rent_order/view_model/create_rent_order_view_model.dart';
import 'package:smart_chaja/features/chargenow_devices/plan/provider/plan_provider.dart';
import 'package:smart_chaja/reusable_widgets/snack_bar.dart';
import 'package:smart_chaja/features/chargenow_devices/plan/model/plan.dart';
import 'package:smart_chaja/authentication/register/viewmodels/auth_viewmodel.dart';
import 'package:smart_chaja/features/wallet/provider/wallet_providers.dart';
import 'package:smart_chaja/authentication/register/repositories/auth_repository.dart';

class CreateRentOrderScreen extends ConsumerStatefulWidget {
  final String? initialDeviceId;

  const CreateRentOrderScreen({super.key, this.initialDeviceId});

  @override
  ConsumerState<CreateRentOrderScreen> createState() =>
      _CreateRentOrderScreenState();
}

class _CreateRentOrderScreenState extends ConsumerState<CreateRentOrderScreen>
    with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _deviceIdController = TextEditingController();
  final _callbackURLController = TextEditingController();

  final MobileScannerController _scannerController = MobileScannerController(
    autoStart: false,
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool _showScanner = true;
  bool _isLoadingPlans = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Check authentication - redirect to OTP if not logged in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check Firebase Auth directly first for reliable auth status
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        // User not authenticated, redirect to OTP registration
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/send-otp');
        }
        return;
      }

      // User is authenticated, refresh profile in Riverpod
      ref.read(authViewModelProvider.notifier).refreshUserProfile();
    });

    if (widget.initialDeviceId != null) {
      _deviceIdController.text = widget.initialDeviceId!;
      _showScanner = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _proceedToPlanSelection(_deviceIdController.text.trim());
      });
    } else {
      _scannerController.start();
    }

    _callbackURLController.text = ChargeNowApiConfig.rentOrderCallbackUrl;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_showScanner) return;

    if (!(_scannerController.value.isInitialized) ||
        !(_scannerController.value.hasCameraPermission)) {
      return;
    }

    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        _scannerController.stop();
        break;
      case AppLifecycleState.resumed:
        _scannerController.start();
        ref.read(authViewModelProvider.notifier).refreshUserProfile();
        break;
      case AppLifecycleState.inactive:
        _scannerController.stop();
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    try {
      _scannerController.dispose();
    } catch (e) {
      log('Error disposing scanner controller: $e');
    }
    _deviceIdController.dispose();
    _callbackURLController.dispose();
    super.dispose();
  }

  /// Extracts device ID from QR code URL or returns raw value if it's a number
  String? _extractDeviceIdFromQrCode(String scannedValue) {
    // Handle URL format: https//app.chargenow.top/=//qrcode=1741758950
    // or variations like: https://app.chargenow.top/qrcode=1741758950

    final qrCodePattern = RegExp(r'qrcode[=:](\d+)', caseSensitive: false);
    final match = qrCodePattern.firstMatch(scannedValue);

    if (match != null && match.group(1) != null) {
      return match.group(1);
    }

    // If no pattern match, check if the scanned value is just a number (direct device ID)
    if (RegExp(r'^\d+$').hasMatch(scannedValue.trim())) {
      return scannedValue.trim();
    }

    return null;
  }

  void _toggleViewMode() async {
    const transitionDelay = Duration(milliseconds: 100);

    if (_showScanner) {
      await _scannerController.stop();
      await Future.delayed(transitionDelay);
      if (mounted) {
        setState(() {
          _showScanner = false;
        });
      }
    } else {
      setState(() {
        _showScanner = true;
      });
      await Future.delayed(transitionDelay);
      if (mounted) {
        await _scannerController.start();
      }
    }
  }

  void _onDetect(BarcodeCapture capture) async {
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;
      if (code != null && code.trim().isNotEmpty) {
        try {
          await _scannerController.stop();
        } catch (e) {
          log('Error stopping scanner: $e');
        }

        final String scannedValue = code.trim();
        log('Raw scanned QR code: $scannedValue');

        // Extract device ID from URL or use raw value
        final String? deviceId = _extractDeviceIdFromQrCode(scannedValue);

        if (deviceId == null || deviceId.isEmpty) {
          log('Failed to extract device ID from QR code: $scannedValue');
          if (mounted) {
            TopSnackBar.show(
              context,
              "Invalid QR code format. Please scan a valid device QR code.",
              iconData: Icons.qr_code,
              color: AppColors.errorColor,
            );
            try {
              if (_showScanner) {
                _scannerController.start();
              }
            } catch (e) {
              log('Error restarting scanner: $e');
            }
          }
          return;
        }

        _deviceIdController.text = deviceId;
        log('Extracted Device ID: $deviceId, proceeding to plan selection...');

        if (!mounted) return;
        await _proceedToPlanSelection(deviceId);
      }
    }
  }

  Future<void> _proceedToPlanSelection(String deviceId) async {
    setState(() {
      _isLoadingPlans = true;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final currentFirebaseUser = authRepo.currentUser;

      if (currentFirebaseUser == null) {
        if (mounted) {
          TopSnackBar.show(
            context,
            "Authentication session expired. Please log in again.",
            iconData: Icons.lock_outline_rounded,
            color: AppColors.errorColor,
          );
        }
        if (_showScanner && mounted) {
          try {
            await _scannerController.start();
          } catch (e) {
            log('Error restarting scanner: $e');
          }
        }
        return;
      }

      await ref.read(authViewModelProvider.notifier).refreshUserProfile();

      final authState = ref.read(authViewModelProvider);
      final currentUser = authState.user;

      if (currentUser == null) {
        if (mounted) {
          TopSnackBar.show(
            context,
            "User profile not found. Please complete your registration.",
            iconData: Icons.person_off_rounded,
            color: AppColors.errorColor,
          );
        }
        if (_showScanner && mounted) {
          try {
            await _scannerController.start();
          } catch (e) {
            log('Error restarting scanner: $e');
          }
        }
        return;
      }

      if (currentFirebaseUser.uid != currentUser.uid) {
        log('UID mismatch: Firebase=${currentFirebaseUser.uid}, Profile=${currentUser.uid}');
        if (mounted) {
          TopSnackBar.show(
            context,
            "Authentication mismatch. Please log in again.",
            iconData: Icons.error_outline_rounded,
            color: AppColors.errorColor,
          );
        }
        if (_showScanner && mounted) {
          try {
            await _scannerController.start();
          } catch (e) {
            log('Error restarting scanner: $e');
          }
        }
        return;
      }

      final planViewModel = ref.read(planViewModelProvider.notifier);
      await planViewModel.fetchPlans();

      if (!mounted) return;

      setState(() {
        _isLoadingPlans = false;
      });

      final Plan? selectedPlan = await showDialog<Plan>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return PlanSelectionDialog(
            deviceId: deviceId,
            onCancel: () {
              Navigator.of(context).pop(null);
              ref.read(planViewModelProvider.notifier).selectPlan(null);
            },
            onConfirm: (plan) {
              Navigator.of(context).pop(plan);
              ref.read(planViewModelProvider.notifier).selectPlan(null);
            },
          );
        },
      ).catchError((e) {
        log('Error in plan selection dialog: $e');
        return null;
      });

      if (!mounted) return;

      if (selectedPlan != null) {
        log('User selected plan: ${selectedPlan.name} for device: $deviceId');
        await _deductBalanceAndCreateOrder(deviceId, selectedPlan);
      } else {
        log('User canceled plan selection.');
        if (_showScanner && mounted) {
          try {
            await _scannerController.start();
          } catch (e) {
            log('Error restarting scanner: $e');
          }
        }
      }
    } catch (e) {
      log('Error in plan selection flow: $e');
      if (mounted) {
        TopSnackBar.show(
          context,
          "An error occurred. Please try again.",
          iconData: Icons.error_outline_rounded,
          color: AppColors.errorColor,
        );
      }
      if (_showScanner && mounted) {
        try {
          await _scannerController.start();
        } catch (scannerError) {
          log('Error restarting scanner: $scannerError');
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPlans = false;
        });
      }
    }
  }

  Future<void> _deductBalanceAndCreateOrder(
      String deviceId, Plan selectedPlan) async {
    final authRepo = ref.read(authRepositoryProvider);
    final currentFirebaseUser = authRepo.currentUser;

    if (currentFirebaseUser == null) {
      TopSnackBar.show(
        context,
        "Authentication expired. Please log in again.",
        iconData: Icons.lock_outline_rounded,
        color: AppColors.errorColor,
      );
      if (_showScanner && mounted) {
        try {
          await _scannerController.start();
        } catch (e) {
          log('Error restarting scanner: $e');
        }
      }
      return;
    }

    final authState = ref.read(authViewModelProvider);
    final currentUser = authState.user;

    if (currentUser == null || currentUser.uid != currentFirebaseUser.uid) {
      TopSnackBar.show(
        context,
        "User profile mismatch. Please log in again.",
        iconData: Icons.person_off_rounded,
        color: AppColors.errorColor,
      );
      if (_showScanner && mounted) {
        try {
          await _scannerController.start();
        } catch (e) {
          log('Error restarting scanner: $e');
        }
      }
      return;
    }

    final walletService = ref.read(walletServiceProvider);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: AppSpacing.medium),
              Text("Processing payment..."),
            ],
          ),
        );
      },
    );

    try {
      final success = await walletService.deductBalance(
        userId: currentUser.uid,
        amount: selectedPlan.price,
        currency: selectedPlan.currency,
        description: 'Power bank rent: ${selectedPlan.name}',
        deviceId: deviceId,
      );

      if (!mounted) return;
      Navigator.of(context).pop();

      if (success) {
        await ref.read(authViewModelProvider.notifier).refreshUserProfile();
        await Future.delayed(const Duration(milliseconds: 500));

        TopSnackBar.show(
          context,
          "Payment successful! ${selectedPlan.price.toStringAsFixed(2)} ${selectedPlan.currency} deducted.",
          iconData: Icons.check_circle_rounded,
          color: AppColors.successColor,
        );

        final verifyUser = authRepo.currentUser;
        if (verifyUser == null) {
          log('ERROR: User became unauthenticated after payment!');
          TopSnackBar.show(
            context,
            "Authentication lost. Please contact support.",
            iconData: Icons.error_outline_rounded,
            color: AppColors.errorColor,
          );
          if (_showScanner && mounted) {
            try {
              await _scannerController.start();
            } catch (e) {
              log('Error restarting scanner: $e');
            }
          }
          return;
        }

        log('Proceeding to create rent order with authenticated user: ${verifyUser.uid}');
        _submitAndShowFeedback(selectedPlan);
      } else {
        TopSnackBar.show(
          context,
          "Failed to deduct payment. Please try again.",
          iconData: Icons.error,
          color: AppColors.errorColor,
        );
        if (_showScanner && mounted) {
          try {
            await _scannerController.start();
          } catch (e) {
            log('Error restarting scanner: $e');
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      String errorMessage = "Error deducting payment.";
      if (e.toString().contains("Insufficient balance")) {
        errorMessage = "Insufficient balance. Please top up your wallet.";
      } else if (e.toString().contains("User profile not found")) {
        errorMessage = "User data not found. Please re-login.";
      } else {
        log('Error during balance deduction: ${e.toString()}');
      }

      TopSnackBar.show(
        context,
        errorMessage,
        iconData: Icons.error,
        color: AppColors.errorColor,
      );
      if (_showScanner && mounted) {
        try {
          await _scannerController.start();
        } catch (scannerError) {
          log('Error restarting scanner: $scannerError');
        }
      }
    }
  }

  void _submitAndShowFeedback(Plan selectedPlan) {
    try {
      final notifier = ref.read(createRentOrderViewModelProvider.notifier);
      notifier.resetState();

      notifier.submitCreateRentOrder(
        deviceId: _deviceIdController.text.trim(),
        callbackURL: _callbackURLController.text.trim(),
        selectedPlan: selectedPlan,
      );

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => OrderFeedbackDialog(
          onOrderSuccess: _onOrderSuccess,
        ),
      ).then((_) {
        // Only restart scanner if order failed or user retried
        final state = ref.read(createRentOrderViewModelProvider);
        if (state.opStatus != CreateRentOrderStatus.success && _showScanner && mounted) {
          _scannerController.start();
        }
      }).catchError((error) {
        log('Dialog error: $error');
        if (_showScanner && mounted) {
          _scannerController.start();
        }
      });
    } catch (e) {
      log('Error in _submitAndShowFeedback: $e');
      if (_showScanner && mounted) {
        _scannerController.start();
      }
    }
  }

  void _onOrderSuccess() {
    // Stop the scanner
    if (_showScanner) {
      _scannerController.stop();
    }
    
    // Navigate to map page
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/map');
    }
  }

  void _handleSubmit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      TopSnackBar.show(
        context,
        "Please fill all required fields correctly.",
        iconData: Icons.warning_amber_rounded,
        color: AppColors.warningColor,
      );
      return;
    }
    final String deviceId = _deviceIdController.text.trim();
    await _proceedToPlanSelection(deviceId);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createRentOrderViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title:
            Text(_showScanner ? 'Scan Device QR Code' : 'Initiate Device Rent'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (state.opStatus != CreateRentOrderStatus.loading)
            IconButton(
              onPressed: _toggleViewMode,
              icon: Icon(_showScanner
                  ? Icons.keyboard_rounded
                  : Icons.qr_code_scanner_rounded),
              tooltip: _showScanner ? 'Enter ID Manually' : 'Scan QR Code',
            )
        ],
      ),
      backgroundColor: _showScanner ? Colors.black : AppColors.backgroundColor,
      body: Stack(
        children: [
          _showScanner
              ? QrScannerView(
                  controller: _scannerController,
                  onDetect: _onDetect,
                )
              : ManualInputForm(
                  formKey: _formKey,
                  deviceIdController: _deviceIdController,
                  callbackURLController: _callbackURLController,
                  onSubmit: _handleSubmit,
                ),
          if (_isLoadingPlans)
            const LoadingOverlay(
              message: "Loading rental plans...",
            ),
        ],
      ),
    );
  }
}
