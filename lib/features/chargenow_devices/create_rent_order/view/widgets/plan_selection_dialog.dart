import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_chaja/app_constants/app_constants.dart';
import 'package:smart_chaja/features/chargenow_devices/plan/model/plan.dart';
import 'package:smart_chaja/features/chargenow_devices/plan/model/plan_state.dart';
import 'package:smart_chaja/features/chargenow_devices/plan/provider/plan_provider.dart';
import 'package:smart_chaja/authentication/register/viewmodels/auth_viewmodel.dart';
import 'package:smart_chaja/features/chargenow_devices/create_rent_order/view/widgets/balance_card.dart';
import 'package:smart_chaja/features/chargenow_devices/create_rent_order/view/widgets/device_info_card.dart';
import 'package:smart_chaja/features/chargenow_devices/create_rent_order/view/widgets/plan_card.dart';

class PlanSelectionDialog extends ConsumerWidget {
  final String deviceId;
  final VoidCallback onCancel;
  final Function(Plan) onConfirm;

  const PlanSelectionDialog({
    super.key,
    required this.deviceId,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planState = ref.watch(planViewModelProvider);
    final authState = ref.watch(authViewModelProvider);
    final currentUser = authState.user;

    if (currentUser == null) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        ),
        title: const Text("Authentication Required"),
        content: const Text("Please log in to continue."),
        actions: [
          TextButton(
            onPressed: onCancel,
            child: const Text("OK"),
          ),
        ],
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth > 600 ? 550.0 : screenWidth * 0.9;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
      ),
      backgroundColor: Colors.white,
      child: Container(
        width: dialogWidth,
        constraints: const BoxConstraints(maxHeight: 650),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppSpacing.medium),
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppBorderRadius.medium),
                  topRight: Radius.circular(AppBorderRadius.medium),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.power_settings_new_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: AppSpacing.small),
                  Text(
                    'Select Rental Plan',
                    style: AppTextStyles.bodyText1.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.medium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Balance Card
                    BalanceCard(balance: currentUser.balance),
                    const SizedBox(height: AppSpacing.medium),

                    // Device Info Card
                    DeviceInfoCard(deviceId: deviceId),
                    const SizedBox(height: AppSpacing.large),

                    // Section Header
                    Text(
                      'Rental Duration',
                      style: AppTextStyles.bodyText1.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.medium),

                    // Loading State
                    if (planState.status == PlanStatus.loading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppSpacing.medium),
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primaryColor,
                            ),
                          ),
                        ),
                      ),

                    // Error State
                    if (planState.status == PlanStatus.error)
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.medium),
                        child: Text(
                          'Unable to load plans. Please try again.',
                          style: AppTextStyles.bodyText2.copyWith(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ),

                    // Empty State
                    if (planState.status == PlanStatus.success &&
                        (planState.plans == null || planState.plans!.isEmpty))
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.medium),
                        child: Text(
                          'No rental plans available.',
                          style: AppTextStyles.bodyText2.copyWith(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ),

                    // Plan List
                    if (planState.status == PlanStatus.success &&
                        planState.plans != null)
                      ...planState.plans!.map((plan) {
                        final isSelected = plan == planState.selectedPlan;
                        final canAfford = currentUser.balance >= plan.price;

                        return PlanCard(
                          plan: plan,
                          isSelected: isSelected,
                          canAfford: canAfford,
                          onTap: canAfford
                              ? () {
                                  ref
                                      .read(planViewModelProvider.notifier)
                                      .selectPlan(plan);
                                }
                              : null,
                          onRadioChanged: canAfford
                              ? (Plan? value) {
                                  ref
                                      .read(planViewModelProvider.notifier)
                                      .selectPlan(value);
                                }
                              : null,
                          selectedPlan: planState.selectedPlan,
                        );
                      }).toList(),

                    // Selected Plan Summary
                    if (planState.selectedPlan != null)
                      Container(
                        margin: const EdgeInsets.only(top: AppSpacing.medium),
                        padding: const EdgeInsets.all(AppSpacing.medium),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius:
                              BorderRadius.circular(AppBorderRadius.small),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Selected Plan',
                                    style: AppTextStyles.bodyText2.copyWith(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '${planState.selectedPlan!.price.toStringAsFixed(2)} ${planState.selectedPlan!.currency}',
                                    style: AppTextStyles.bodyText1.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 18,
                                    ),
                                  ),
                                  Text(
                                    '${planState.selectedPlan!.durationDays} ${planState.selectedPlan!.durationDays == 1 ? 'Day' : 'Days'}',
                                    style: AppTextStyles.bodyText2.copyWith(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Insufficient Balance Message
                    if (planState.selectedPlan != null &&
                        currentUser.balance < planState.selectedPlan!.price)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.medium),
                        child: Text(
                          'Insufficient balance. Please top up your wallet.',
                          style: AppTextStyles.bodyText2.copyWith(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Footer Actions
            Container(
              padding: const EdgeInsets.all(AppSpacing.medium),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(AppBorderRadius.medium),
                  bottomRight: Radius.circular(AppBorderRadius.medium),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: onCancel,
                    child: Text(
                      'Cancel',
                      style: AppTextStyles.bodyText2.copyWith(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.small),
                  Flexible(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade200,
                        disabledForegroundColor: Colors.grey.shade500,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.large,
                          vertical: AppSpacing.medium,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppBorderRadius.small),
                        ),
                        elevation: 0,
                      ),
                      onPressed: (planState.selectedPlan != null &&
                              currentUser.balance >=
                                  planState.selectedPlan!.price)
                          ? () => onConfirm(planState.selectedPlan!)
                          : null,
                      child: Text(
                        'Confirm Rental',
                        style: AppTextStyles.bodyText2.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
