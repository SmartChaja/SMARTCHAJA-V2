import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_chaja/app_constants/app_constants.dart';
import 'package:smart_chaja/features/chargenow_devices/create_rent_order/provider/create_rent_order_provider.dart';
import 'package:smart_chaja/features/chargenow_devices/create_rent_order/view_model/create_rent_order_view_model.dart';

class OrderFeedbackDialog extends ConsumerWidget {
  const OrderFeedbackDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the provider to get the current state of the API call
    final state = ref.watch(createRentOrderViewModelProvider);

    // This widget will rebuild whenever the state changes (e.g., from loading to success/error)
    return PopScope(
      // Prevent closing the dialog by swiping back while loading
      canPop: state.opStatus != CreateRentOrderStatus.loading,
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.large),
        ),
        content: _buildContent(context, state),
      ),
    );
  }

  Widget _buildContent(BuildContext context, CreateRentOrderState state) {
    switch (state.opStatus) {
      case CreateRentOrderStatus.loading:
        return _buildLoadingView();
      case CreateRentOrderStatus.success:
        return _buildSuccessView(context, state);
      case CreateRentOrderStatus.error:
        return _buildErrorView(context, state);
      default: // initial or other states
        // This case should ideally not be seen if the dialog is shown after submission
        return _buildLoadingView();
    }
  }

  Widget _buildLoadingView() {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(color: AppColors.primaryColor),
        SizedBox(height: AppSpacing.large),
        Text(
          'Creating Rent Order...',
          textAlign: TextAlign.center,
          style: AppTextStyles.subtitle1,
        ),
      ],
    );
  }

  Widget _buildSuccessView(BuildContext context, CreateRentOrderState state) {
    final orderResponse = state.orderResponse!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle_rounded,
            color: AppColors.successColor, size: 50),
        const SizedBox(height: AppSpacing.medium),
        Text(
          "Order Created!",
          textAlign: TextAlign.center,
          style: AppTextStyles.headline3.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.small),
        Text(
          orderResponse.msg,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyText2
              .copyWith(color: AppColors.secondaryTextColor),
        ),
        const Divider(height: AppSpacing.large, thickness: 0.5),
        _buildDetailRow("Trade No:", orderResponse.data!.tradeNo),
        _buildDetailRow("API Code:", orderResponse.code.toString()),
        const SizedBox(height: AppSpacing.large),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildErrorView(BuildContext context, CreateRentOrderState state) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_rounded, color: AppColors.errorColor, size: 50),
        const SizedBox(height: AppSpacing.medium),
        const Text(
          'Order Failed',
          textAlign: TextAlign.center,
          style: AppTextStyles.headline3,
        ),
        const SizedBox(height: AppSpacing.small),
        Text(
          state.errorMsg ?? 'An unknown error occurred.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyText2
              .copyWith(color: AppColors.secondaryTextColor),
        ),
        const SizedBox(height: AppSpacing.large),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.errorColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('Try Again'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTextStyles.bodyText2
                  .copyWith(color: AppColors.secondaryTextColor)),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              value,
              textAlign: TextAlign.end,
              style:
                  AppTextStyles.bodyText1.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
