import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:smart_chaja/app_constants/app_constants.dart';
import 'package:smart_chaja/features/chargenow_devices/create_rent_order/view/widgets/qr_code_scanner_shape.dart';

class QrScannerView extends StatelessWidget {
  final MobileScannerController controller;
  final Function(BarcodeCapture) onDetect;

  const QrScannerView({
    super.key,
    required this.controller,
    required this.onDetect,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MobileScanner(
          controller: controller,
          onDetect: onDetect,
        ),
        Container(
          decoration: const ShapeDecoration(
            shape: QrScannerOverlayShape(
              borderColor: AppColors.primaryColor,
              borderRadius: 12,
              borderLength: 30,
              borderWidth: 8,
              cutOutSize: 300,
            ),
          ),
        ),
        Positioned(
          top: 16,
          right: 16,
          child: Column(
            children: [
              IconButton(
                color: Colors.white,
                icon: ValueListenableBuilder<MobileScannerState>(
                  valueListenable: controller,
                  builder: (context, state, child) {
                    switch (state.torchState) {
                      case TorchState.on:
                        return const Icon(Icons.flash_on, color: Colors.yellow);
                      case TorchState.off:
                        return const Icon(Icons.flash_off, color: Colors.white);
                      default:
                        return const Icon(Icons.no_flash, color: Colors.grey);
                    }
                  },
                ),
                tooltip: 'Toggle Flash',
                onPressed: () => controller.toggleTorch(),
              ),
              const SizedBox(height: 16),
              IconButton(
                color: Colors.white,
                icon: const Icon(Icons.flip_camera_ios),
                onPressed: () => controller.switchCamera(),
                tooltip: 'Switch Camera',
              ),
            ],
          ),
        ),
        const Positioned(
          bottom: 100,
          left: 0,
          right: 0,
          child: Text(
            "Position the QR code inside the frame",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              backgroundColor: Colors.black54,
            ),
          ),
        ),
      ],
    );
  }
}
