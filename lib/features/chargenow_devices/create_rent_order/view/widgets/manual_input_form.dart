import 'package:flutter/material.dart';
import 'package:smart_chaja/app_constants/app_constants.dart';
import 'package:smart_chaja/reusable_widgets/custom_text_field.dart';

class ManualInputForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController deviceIdController;
  final TextEditingController callbackURLController;
  final VoidCallback onSubmit;

  const ManualInputForm({
    super.key,
    required this.formKey,
    required this.deviceIdController,
    required this.callbackURLController,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Form(
        key: formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Icon(
              Icons.power_settings_new_rounded,
              size: 70,
              color: AppColors.primaryColor,
            ),
            const SizedBox(height: AppSpacing.medium),
            Text(
              "Manually enter the Device ID/SN to start a rent session.",
              style: AppTextStyles.bodyText1.copyWith(
                color: AppColors.secondaryTextColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            EnhancedCustomTextField(
              controller: deviceIdController,
              label: 'Device ID / SN*',
              hintText: 'e.g., BJD60151',
              prefixIcon: Icons.devices_rounded,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Device ID is required.';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.medium),
            EnhancedCustomTextField(
              controller: callbackURLController,
              label: 'Callback URL (Auto-filled)',
              prefixIcon: Icons.http_rounded,
              readOnly: true,
              enabled: false,
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton.icon(
              icon: const Icon(Icons.send_to_mobile_rounded),
              label: const Text('Create Rent Order'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.medium + AppSpacing.xs,
                ),
                textStyle: AppTextStyles.button.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.xl),
                ),
              ),
              onPressed: onSubmit,
            ),
          ],
        ),
      ),
    );
  }
}