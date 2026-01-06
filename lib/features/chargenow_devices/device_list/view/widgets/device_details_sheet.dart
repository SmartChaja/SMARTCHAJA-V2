import 'package:flutter/material.dart';
import 'package:smart_chaja/app_constants/app_constants.dart';
import 'package:smart_chaja/features/chargenow_devices/device_list/model/charge_now_device_list_response.dart';
import 'navigation_helper.dart';

// --- Helper Widgets for consistent styling ---

Widget _buildDragHandle() {
  return Center(
    child: Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.medium),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
}

Widget _buildStatusCard({
  required String label,
  required String value,
  required Color bgColor,
  required Color textColor,
  IconData? icon,
}) {
  return Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.medium, horizontal: AppSpacing.small),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        border: Border.all(color: textColor.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 24, color: textColor),
            const SizedBox(height: AppSpacing.xs),
          ],
          Text(
            value,
            style: AppTextStyles.subtitle1.copyWith(
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.bodyText2.copyWith(
              color: textColor.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

Widget _buildPriceRow(IconData icon, String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: Row(
      children: [
        Icon(icon, size: 20, color: AppColors.secondaryTextColor),
        const SizedBox(width: AppSpacing.medium),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyText1.copyWith(color: AppColors.secondaryTextColor),
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodyText1.copyWith(
            fontWeight: FontWeight.w600, 
            color: AppColors.primaryTextColor
          ),
        ),
      ],
    ),
  );
}

void showDeviceDetailsSheet(BuildContext context, DeviceListItem device) {
  final shop = device.shop;
  final cabinet = device.cabinet;
  final price = device.price;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    enableDrag: true,
    isDismissible: true,
    builder: (ctx) {
      return DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.25,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(ctx).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppBorderRadius.large)
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildDragHandle(),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.large,
                      AppSpacing.xs,
                      AppSpacing.large,
                      MediaQuery.of(ctx).padding.bottom + AppSpacing.large,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- Shop Information ---
                        if (shop != null) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: device.cabinet?.infoStatus == "1"
                                      ? AppColors.successColor
                                      : AppColors.warningColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.medium),
                              Expanded(
                                child: Text(
                                  shop.shopName,
                                  style: AppTextStyles.headline2.copyWith(
                                    fontWeight: FontWeight.bold, 
                                    color: AppColors.primaryTextColor
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.small),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.location_on, size: 20, color: AppColors.secondaryTextColor),
                              const SizedBox(width: AppSpacing.small),
                              Expanded(
                                child: Text(
                                  shop.shopAddress,
                                  style: AppTextStyles.bodyText1.copyWith(
                                    color: AppColors.secondaryTextColor
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.small),
                          Row(
                            children: [
                              const Icon(Icons.directions_walk, size: 20, color: AppColors.secondaryTextColor),
                              const SizedBox(width: AppSpacing.small),
                              Text(
                                "Distance: ${shop.distance ?? 'N/A'} (${shop.distanceNumber.toStringAsFixed(1)}m)",
                                style: AppTextStyles.bodyText2.copyWith(
                                  color: AppColors.secondaryTextColor
                                ),
                              ),
                            ],
                          ),
                          if (shop.mobile != null && shop.mobile!.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.small),
                            Row(
                              children: [
                                const Icon(Icons.phone, size: 20, color: AppColors.secondaryTextColor),
                                const SizedBox(width: AppSpacing.small),
                                Text(
                                  "Contact: ${shop.mobile}",
                                  style: AppTextStyles.bodyText2.copyWith(
                                    color: AppColors.secondaryTextColor
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: AppSpacing.large),
                          const Divider(height: 1, color: AppColors.dividerColor),
                          const SizedBox(height: AppSpacing.large),
                        ],

                        // --- Station Status ---
                        if (cabinet != null) ...[
                          Text(
                            "Station Status",
                            style: AppTextStyles.headline3.copyWith(
                              fontWeight: FontWeight.bold, 
                              color: AppColors.primaryTextColor
                            ),
                          ),
                          const SizedBox(height: AppSpacing.medium),
                          Row(
                            children: [
                              _buildStatusCard(
                                label: "Total Slots",
                                value: cabinet.batteryNum,
                                bgColor: Theme.of(ctx).colorScheme.primaryContainer.withOpacity(0.1),
                                textColor: Theme.of(ctx).colorScheme.primary,
                                icon: Icons.battery_charging_full,
                              ),
                              const SizedBox(width: AppSpacing.medium),
                              _buildStatusCard(
                                label: "Available",
                                value: cabinet.freeNum,
                                bgColor: (int.tryParse(cabinet.freeNum) ?? 0) > 0
                                    ? AppColors.successColor.withOpacity(0.1)
                                    : AppColors.errorColor.withOpacity(0.1),
                                textColor: (int.tryParse(cabinet.freeNum) ?? 0) > 0
                                    ? AppColors.successColor
                                    : AppColors.errorColor,
                                icon: Icons.battery_std,
                              ),
                              const SizedBox(width: AppSpacing.medium),
                              _buildStatusCard(
                                label: "Status",
                                value: cabinet.infoStatus == "1" ? "Online" : "Offline",
                                bgColor: cabinet.infoStatus == "1"
                                    ? AppColors.successColor.withOpacity(0.1)
                                    : AppColors.errorColor.withOpacity(0.1),
                                textColor: cabinet.infoStatus == "1"
                                    ? AppColors.successColor
                                    : AppColors.errorColor,
                                icon: cabinet.infoStatus == "1" ? Icons.wifi : Icons.wifi_off,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.large),
                          const Divider(height: 1, color: AppColors.dividerColor),
                          const SizedBox(height: AppSpacing.large),
                        ],

                        // --- Pricing ---
                        if (price != null) ...[
                          Text(
                            "Pricing",
                            style: AppTextStyles.headline3.copyWith(
                              fontWeight: FontWeight.bold, 
                              color: AppColors.primaryTextColor
                            ),
                          ),
                          const SizedBox(height: AppSpacing.medium),
                          if (price.price != null && price.price!.isNotEmpty)
                            _buildPriceRow(
                              Icons.money,
                              "Rate",
                              "${price.price} / ${price.chargeUnit ?? 'unit'}",
                            ),
                          if (price.freeDuration != null &&
                              price.freeDuration!.isNotEmpty &&
                              price.freeDuration != "0")
                            _buildPriceRow(
                              Icons.hourglass_empty,
                              "Free Usage",
                              "${price.freeDuration} minutes",
                            ),
                          if (price.dailyCapAmount != null && price.dailyCapAmount!.isNotEmpty)
                            _buildPriceRow(
                              Icons.savings,
                              "Daily Cap",
                              price.dailyCapAmount!,
                            ),
                          if (price.deposit != null &&
                              price.deposit!.isNotEmpty &&
                              price.deposit != "0")
                            _buildPriceRow(
                              Icons.wallet,
                              "Deposit",
                              price.deposit!,
                            ),
                          const SizedBox(height: AppSpacing.large),
                        ],

                        // --- Action Buttons ---
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () async {
                                  Navigator.pop(ctx);
                                  await NavigationHelper.showNavigationOptions(
                                      context, device);
                                },
                                icon: const Icon(Icons.directions_run),
                                label: const Text("Navigate"),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.medium),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppBorderRadius.medium)
                                  ),
                                  textStyle: AppTextStyles.bodyText1.copyWith(fontWeight: FontWeight.bold),
                                  minimumSize: const Size.fromHeight(48),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.medium),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                icon: const Icon(Icons.close),
                                label: const Text("Close"),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primaryColor,
                                  side: const BorderSide(color: AppColors.primaryColor, width: 1.5),
                                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.medium),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppBorderRadius.medium)
                                  ),
                                  textStyle: AppTextStyles.bodyText1,
                                  minimumSize: const Size.fromHeight(48),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}