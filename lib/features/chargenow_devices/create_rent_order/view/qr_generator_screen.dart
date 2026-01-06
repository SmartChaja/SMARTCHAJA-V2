// File: lib/features/chargenow_rent/view/qr_generator_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_gallery_saver/flutter_image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart'; // <-- IMPORTED
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:smart_chaja/app_constants/app_constants.dart';
import 'package:smart_chaja/reusable_widgets/custom_text_field.dart';
import 'package:smart_chaja/reusable_widgets/snack_bar.dart';

class QRGeneratorScreen extends StatefulWidget {
  const QRGeneratorScreen({super.key});

  @override
  State<QRGeneratorScreen> createState() => _QRGeneratorScreenState();
}

class _QRGeneratorScreenState extends State<QRGeneratorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _deviceIdController = TextEditingController();

  bool _isSaving = false;
  String? _generatedDeviceId;
  QrImage? _qrImage;

  @override
  void dispose() {
    _deviceIdController.dispose();
    super.dispose();
  }

  void _generateQRCode() {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      TopSnackBar.show(
        context,
        "Please enter a valid device ID",
        iconData: Icons.warning_amber_rounded,
        color: AppColors.warningColor,
      );
      return;
    }

    final deviceId = _deviceIdController.text.trim();

    final qrCode = QrCode.fromData(
      data: deviceId,
      errorCorrectLevel: QrErrorCorrectLevel.H,
    );

    setState(() {
      _generatedDeviceId = deviceId;
      _qrImage = QrImage(qrCode);
    });

    TopSnackBar.show(
      context,
      "QR Code generated successfully!",
      iconData: Icons.qr_code_2_rounded,
      color: AppColors.successColor,
    );
  }

  void _clearQRCode() {
    setState(() {
      _generatedDeviceId = null;
      _qrImage = null;
      _deviceIdController.clear();
    });
  }

  Future<void> _copyDeviceId() async {
    if (_generatedDeviceId != null) {
      await Clipboard.setData(ClipboardData(text: _generatedDeviceId!));
      TopSnackBar.show(
        context,
        "Device ID copied to clipboard",
        iconData: Icons.copy_rounded,
        color: AppColors.primaryColor,
      );
    }
  }

  // THIS IS THE FINAL, ROBUST METHOD WITH PERMISSION HANDLING
  Future<void> _saveQRCode() async {
    if (_generatedDeviceId == null || _qrImage == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // 1. Request storage permission
      var status = await Permission.storage.request();

      // On Android 13+, storage permission is split. `Permission.photos` might be needed.
      if (status.isDenied) {
        status = await Permission.photos.request();
      }

      // 2. Check if the permission was granted
      if (status.isGranted) {
        // --- Permission granted, proceed to save ---
        final ByteData? byteData = await _qrImage!.toImageAsBytes(
          size: 512,
          format: ImageByteFormat.png,
          decoration: const PrettyQrDecoration(
            shape: PrettyQrSmoothSymbol(color: Colors.black),
            background: Colors.white,
          ),
        );

        if (byteData == null) {
          throw Exception("QR image generation failed.");
        }
        final Uint8List qrImageBytes = byteData.buffer.asUint8List();

        await FlutterImageGallerySaver.saveImage(qrImageBytes);

        TopSnackBar.show(
          context,
          "QR Code saved to Gallery!",
          iconData: Icons.save_rounded,
          color: AppColors.successColor,
        );
      } else {
        // --- Permission was denied ---
        TopSnackBar.show(
          context,
          "Storage permission is required to save the image.",
          iconData: Icons.warning_amber_rounded,
          color: AppColors.warningColor,
        );
        // You can optionally open app settings to let the user grant it manually.
        // await openAppSettings();
      }
    } catch (e) {
      TopSnackBar.show(
        context,
        "Failed to save QR code: $e",
        iconData: Icons.error_outline_rounded,
        color: AppColors.errorColor,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Device QR Code'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_generatedDeviceId != null)
            IconButton(
              icon: const Icon(Icons.clear_all_rounded),
              onPressed: _clearQRCode,
              tooltip: 'Clear QR Code',
            ),
        ],
      ),
      backgroundColor: AppColors.backgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.qr_code_2_rounded,
                size: 70,
                color: AppColors.primaryColor.withOpacity(0.8),
              ),
              const SizedBox(height: AppSpacing.medium),
              Text(
                "Generate QR codes for your devices that can be scanned to quickly input device IDs.",
                style: AppTextStyles.bodyText1.copyWith(color: AppColors.secondaryTextColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              EnhancedCustomTextField(
                controller: _deviceIdController,
                label: 'Device ID / SN*',
                hintText: 'e.g., BJD60151',
                prefixIcon: Icons.devices_rounded,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Device ID is required.';
                  }
                  if (value.trim().length < 3) {
                    return 'Device ID must be at least 3 characters.';
                  }
                  return null;
                },
                onChanged: (value) {
                  if (_generatedDeviceId != null && value != _generatedDeviceId) {
                    setState(() {
                      _generatedDeviceId = null;
                      _qrImage = null;
                    });
                  }
                },
              ),
              const SizedBox(height: AppSpacing.large),
              ElevatedButton.icon(
                onPressed: _generateQRCode,
                icon: const Icon(Icons.qr_code_2_rounded),
                label: const Text('Generate QR Code'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.medium + AppSpacing.xs),
                  textStyle: AppTextStyles.button.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (_generatedDeviceId != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.large),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppBorderRadius.large),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Device QR Code',
                        style: AppTextStyles.headline3.copyWith(
                          color: AppColors.primaryTextColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.medium),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.medium,
                          vertical: AppSpacing.small,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppBorderRadius.small),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.devices_rounded,
                              color: AppColors.primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.small),
                            Text(
                              _generatedDeviceId!,
                              style: AppTextStyles.bodyText1.copyWith(
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.small),
                            GestureDetector(
                              onTap: _copyDeviceId,
                              child: const Icon(
                                Icons.copy_rounded,
                                color: AppColors.primaryColor,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.large),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.medium),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                          border: Border.all(
                            color: AppColors.dividerColor,
                            width: 2,
                          ),
                        ),
                        child: PrettyQrView(
                          qrImage: _qrImage!,
                          decoration: const PrettyQrDecoration(),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.large),
                      ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveQRCode,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.download_rounded),
                        label: Text(_isSaving ? 'Downloading...' : 'Download QR Code'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.medium),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}