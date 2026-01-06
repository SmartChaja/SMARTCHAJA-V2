// main_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smart_chaja/app_constants/app_constants.dart';
import 'package:smart_chaja/features/chargenow_devices/device_info/model/charge_now_device_info_response.dart';
import 'package:smart_chaja/features/chargenow_devices/device_info/provider/charge_now_devices_provider.dart';
import 'package:smart_chaja/features/chargenow_devices/device_info/view_model/charge_now_device_info_view_model.dart';
import 'package:smart_chaja/reusable_widgets/shimmer.dart';
import 'package:smart_chaja/reusable_widgets/snack_bar.dart';

class ChargeNowDeviceDetailScreen extends ConsumerStatefulWidget {
  final String? initialDeviceId;
  final String? deviceNameToDisplay;

  const ChargeNowDeviceDetailScreen({
    super.key,
    this.initialDeviceId,
    this.deviceNameToDisplay,
  });

  @override
  ConsumerState<ChargeNowDeviceDetailScreen> createState() =>
      _ChargeNowDeviceDetailScreenState();
}

class _ChargeNowDeviceDetailScreenState
    extends ConsumerState<ChargeNowDeviceDetailScreen> {
  final TextEditingController _deviceIdController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _activeDeviceId;

  @override
  void initState() {
    super.initState();
    if (widget.initialDeviceId != null && widget.initialDeviceId!.isNotEmpty) {
      _deviceIdController.text = widget.initialDeviceId!;
      _activeDeviceId = widget.initialDeviceId;
      // Fetch details after the first frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _activeDeviceId != null) {
          ref
              .read(chargeNowDeviceInfoViewModelProvider(_activeDeviceId!)
                  .notifier)
              .fetchDeviceInfo();
        }
      });
    }
  }

  @override
  void dispose() {
    _deviceIdController.dispose();
    super.dispose();
  }

  void _fetchDeviceDetails() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final deviceIdToFetch = _deviceIdController.text.trim();
    if (deviceIdToFetch.isNotEmpty) {
      setState(() => _activeDeviceId = deviceIdToFetch);
      // Let Riverpod handle the fetch when the new provider is read.
      // The `ref.watch` will trigger the fetch automatically if needed.
      // We force a refresh to ensure new data is fetched.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(
                chargeNowDeviceInfoViewModelProvider(deviceIdToFetch).notifier)
            .fetchDeviceInfo(forceRefresh: true);
      });
    } else {
      TopSnackBar.show(context, "Please enter a Device ID.",
          iconData: Icons.error_outline, color: AppColors.warningColor);
    }
  }

  Future<void> _refreshData() async {
    if (_activeDeviceId != null) {
      await ref
          .read(chargeNowDeviceInfoViewModelProvider(_activeDeviceId!).notifier)
          .fetchDeviceInfo(forceRefresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the state for the active device ID
    final state = _activeDeviceId != null
        ? ref.watch(chargeNowDeviceInfoViewModelProvider(_activeDeviceId!))
        : DeviceInfoState(status: DeviceInfoStatus.initial);

    // Listen for errors to show snackbars
    if (_activeDeviceId != null) {
      ref.listen<DeviceInfoState>(
          chargeNowDeviceInfoViewModelProvider(_activeDeviceId!), (prev, next) {
        if ((next.status == DeviceInfoStatus.error ||
                next.status == DeviceInfoStatus.notFound) &&
            next.errorMsg != null &&
            (prev?.errorMsg != next.errorMsg || prev?.status != next.status)) {
          TopSnackBar.show(
            context,
            next.errorMsg!,
            iconData: next.status == DeviceInfoStatus.notFound
                ? Icons.search_off_rounded
                : Icons.error_outline_rounded,
            color: next.status == DeviceInfoStatus.notFound
                ? AppColors.warningColor
                : AppColors.errorColor,
          );
        }
      });
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(widget.deviceNameToDisplay ?? 'Device Hub'),
        centerTitle: true,
        backgroundColor: AppColors.backgroundColor,
        foregroundColor: AppColors.primaryTextColor,
        elevation: 0,
        actions: [
          if (state.status == DeviceInfoStatus.success)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: "Refresh",
              onPressed: _refreshData,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildContent(state),
            ),
          ),
          _buildSearchInputArea(),
        ],
      ),
    );
  }

  // A cleaner, more modern search input area
  Widget _buildSearchInputArea() {
    return Material(
      elevation: 8.0,
      color: Colors.white,
      child: Container(
        padding: EdgeInsets.fromLTRB(
            AppSpacing.medium,
            AppSpacing.small,
            AppSpacing.medium,
            MediaQuery.of(context).padding.bottom + AppSpacing.small),
        child: Form(
          key: _formKey,
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  // Using a standard TextFormField for easy customization
                  controller: _deviceIdController,
                  decoration: InputDecoration(
                    hintText: "Enter Device ID (e.g., BJD60151)",
                    prefixIcon: const Icon(Icons.qr_code_scanner_rounded,
                        color: AppColors.secondaryTextColor),
                    filled: true,
                    fillColor: AppColors.backgroundColor,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppBorderRadius.large),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.medium),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Device ID is required';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              SizedBox(
                height: 50,
                width: 50,
                child: IconButton(
                  onPressed: _fetchDeviceDetails,
                  style: IconButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppBorderRadius.medium),
                      )),
                  icon: const Icon(Icons.search_rounded, color: Colors.white),
                  tooltip: "Search",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Central content router
  Widget _buildContent(DeviceInfoState state) {
    if (_activeDeviceId == null) {
      return _buildStatusScreen(
        icon: Icons.search_rounded,
        title: "Find a Device",
        message: "Enter a Device ID below to get started.",
      );
    }

    switch (state.status) {
      case DeviceInfoStatus.loading:
        return _buildLoadingSkeleton();
      case DeviceInfoStatus.success:
        return _buildSuccessLayout(state.deviceInfo!);
      case DeviceInfoStatus.notFound:
        return _buildStatusScreen(
          icon: Icons.search_off_rounded,
          title: "Device Not Found",
          message:
              "No device found with the ID '$_activeDeviceId'. Please check the ID and try again.",
          iconColor: AppColors.warningColor,
        );
      case DeviceInfoStatus.error:
        return _buildStatusScreen(
            icon: Icons.error_outline_rounded,
            title: "An Error Occurred",
            message: state.errorMsg ??
                "Could not load device details. Please try again.",
            iconColor: AppColors.errorColor,
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.large),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.refresh_rounded),
                label: const Text("Retry"),
                onPressed: _refreshData,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor),
              ),
            ));
      default: // Initial
        return _buildStatusScreen(
          icon: Icons.info_outline_rounded,
          title: "Ready to Search",
          message:
              "Press the search button to fetch details for '$_activeDeviceId'.",
        );
    }
  }

  // A generic widget for initial, not found, and error states
  Widget _buildStatusScreen({
    required IconData icon,
    required String title,
    required String message,
    Color? iconColor,
    Widget? child,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.large * 1.5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: iconColor ?? AppColors.primaryColor.withOpacity(0.7),
            ),
            const SizedBox(height: AppSpacing.large),
            Text(
              title,
              style:
                  AppTextStyles.headline2.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.small),
            Text(
              message,
              style: AppTextStyles.bodyText1
                  .copyWith(color: AppColors.secondaryTextColor),
              textAlign: TextAlign.center,
            ),
            if (child != null) child,
          ],
        ),
      ),
    );
  }

  // The main success UI layout
  Widget _buildSuccessLayout(DeviceInfoData data) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: AppColors.primaryColor,
      child: DefaultTabController(
        length: 4,
        child: Column(
          children: [
            _buildDeviceHeader(data.cabinet),
            const TabBar(
              labelColor: AppColors.primaryColor,
              unselectedLabelColor: AppColors.secondaryTextColor,
              indicatorColor: AppColors.primaryColor,
              indicatorWeight: 3.0,
              tabs: [
                Tab(
                    icon: Icon(Icons.power_settings_new_rounded),
                    text: "Cabinet"),
                Tab(
                    icon: Icon(Icons.store_mall_directory_outlined),
                    text: "Shop"),
                Tab(icon: Icon(Icons.price_change_outlined), text: "Pricing"),
                Tab(
                    icon: Icon(Icons.battery_charging_full_rounded),
                    text: "Batteries"),
              ],
            ),
            const Divider(height: 1, thickness: 1),
            Expanded(
              child: TabBarView(
                children: [
                  _buildCabinetInfo(data.cabinet),
                  _buildShopInfo(data.shop),
                  _buildPriceStrategyInfo(data.priceStrategy),
                  _buildBatteriesList(data.batteries),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // A prominent header for key device info
  Widget _buildDeviceHeader(CabinetInfo? cabinet) {
    bool isOnline = cabinet?.online == true;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Device ID",
                      style: AppTextStyles.bodyText2
                          .copyWith(color: AppColors.secondaryTextColor),
                    ),
                    Text(
                      cabinet?.id ?? _activeDeviceId ?? 'N/A',
                      style: AppTextStyles.headline2
                          .copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Chip(
                avatar: Icon(
                  isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                  color:
                      isOnline ? AppColors.successColor : AppColors.errorColor,
                  size: 18,
                ),
                label: Text(isOnline ? "Online" : "Offline"),
                backgroundColor:
                    (isOnline ? AppColors.successColor : AppColors.errorColor)
                        .withOpacity(0.1),
                side: BorderSide.none,
              ),
            ],
          ),
          if (cabinet?.remark != null && cabinet!.remark!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.small),
              child: Text(
                cabinet.remark!,
                style: AppTextStyles.bodyText2
                    .copyWith(color: AppColors.secondaryTextColor),
              ),
            ),
        ],
      ),
    );
  }

  // A reusable card for displaying a section of information
  Widget _buildInfoCard(
      {required IconData icon,
      required String title,
      required List<Widget> children}) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.all(AppSpacing.medium),
      elevation: 2.0,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.large)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primaryColor, size: 20),
                const SizedBox(width: AppSpacing.small),
                Text(
                  title,
                  style: AppTextStyles.headline3
                      .copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: AppSpacing.large, thickness: 0.5),
            ...children,
          ],
        ),
      ),
    );
  }

  // A reusable row for a single piece of detail
  Widget _buildDetailItem(
      {required IconData icon,
      required String label,
      required String value,
      Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.small),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.secondaryTextColor),
          const SizedBox(width: AppSpacing.medium),
          Text(label, style: AppTextStyles.bodyText1),
          const Spacer(),
          Text(
            value.isNotEmpty ? value : "N/A",
            style: AppTextStyles.bodyText1.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor ?? AppColors.primaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  // Specific content widgets for each tab
  Widget _buildCabinetInfo(CabinetInfo? cabinet) {
    if (cabinet == null) return _buildEmptyTabContent("No Cabinet Details");

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildInfoCard(
            icon: Icons.inventory_2_outlined,
            title: "Status & Slots",
            children: [
              _buildDetailItem(
                  icon: Icons.dns_rounded,
                  label: "Type",
                  value: cabinet.type ?? ""),
              _buildDetailItem(
                  icon: Icons.power_rounded,
                  label: "Total Slots",
                  value: cabinet.slots?.toString() ?? ""),
              _buildDetailItem(
                  icon: Icons.battery_charging_full_rounded,
                  label: "Busy Slots",
                  value: cabinet.busySlots?.toString() ?? ""),
              _buildDetailItem(
                  icon: Icons.battery_unknown_rounded,
                  label: "Empty Slots",
                  value: cabinet.emptySlots?.toString() ?? ""),
            ],
          ),
          _buildInfoCard(
            icon: Icons.network_check_rounded,
            title: "Network & System",
            children: [
              _buildDetailItem(
                  icon: Icons.qr_code,
                  label: "QR Code",
                  value: cabinet.qrCode ?? ""),
              _buildDetailItem(
                  icon: Icons.router_rounded,
                  label: "IP Address",
                  value: cabinet.ip ?? ""),
              _buildDetailItem(
                  icon: Icons.signal_cellular_alt_rounded,
                  label: "Signal",
                  value: cabinet.signal ?? ""),
              if (cabinet.posDeviceId != null &&
                  cabinet.posDeviceId!.isNotEmpty)
                _buildDetailItem(
                    icon: Icons.credit_card_rounded,
                    label: "POS ID",
                    value: cabinet.posDeviceId!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShopInfo(ShopInfo? shop) {
    if (shop == null) return _buildEmptyTabContent("No Shop Details");

    return SingleChildScrollView(
      child: Column(
        children: [
          if (shop.logo != null && shop.logo!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.medium, horizontal: AppSpacing.large),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                child: CachedNetworkImage(
                  imageUrl: shop.logo!,
                  height: 80,
                  fit: BoxFit.contain,
                  errorWidget: (context, url, error) => const Icon(
                      Icons.hide_image_outlined,
                      size: 50,
                      color: AppColors.secondaryTextColor),
                ),
              ),
            ),
          _buildInfoCard(
            icon: Icons.location_on_outlined,
            title: shop.name ?? "Shop Information",
            children: [
              _buildDetailItem(
                  icon: Icons.maps_home_work_outlined,
                  label: "Address",
                  value: shop.address ?? ""),
              _buildDetailItem(
                  icon: Icons.location_city_rounded,
                  label: "City/Region",
                  value: "${shop.city ?? ''} / ${shop.region ?? ''}"),
              _buildDetailItem(
                  icon: Icons.access_time_rounded,
                  label: "Hours",
                  value: shop.openingTime ?? ""),
              _buildDetailItem(
                  icon: Icons.pin_drop_outlined,
                  label: "Coordinates",
                  value:
                      "Lat: ${shop.latitude ?? 'N/A'}, Lng: ${shop.longitude ?? 'N/A'}"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceStrategyInfo(PriceStrategyInfo? strategy) {
    if (strategy == null) return _buildEmptyTabContent("No Pricing Details");

    return SingleChildScrollView(
      child: _buildInfoCard(
        icon: Icons.monetization_on_outlined,
        title: strategy.name ?? "Pricing Strategy",
        children: [
          _buildDetailItem(
            icon: Icons.timelapse_rounded,
            label: "Rate",
            value:
                "${strategy.price ?? 0} ${strategy.currencySymbol ?? ''} / ${strategy.priceMinute ?? 0} min",
          ),
          _buildDetailItem(
            icon: Icons.timer_off_outlined,
            label: "Free Time",
            value: "${strategy.freeMinutes ?? 0} minutes",
          ),
          _buildDetailItem(
            icon: Icons.shield_outlined,
            label: "Daily Cap",
            value:
                "${strategy.dailyMaxPrice ?? 0} ${strategy.currencySymbol ?? ''}",
          ),
          _buildDetailItem(
            icon: Icons.lock_outline,
            label: "Deposit",
            value:
                "${strategy.depositAmount ?? 0} ${strategy.currencySymbol ?? ''}",
          ),
          _buildDetailItem(
            icon: Icons.event_repeat_rounded,
            label: "Overdue Charge",
            value:
                "${strategy.timeoutAmount ?? 0} ${strategy.currencySymbol ?? ''} after ${strategy.timeoutDay ?? 0} days",
          ),
        ],
      ),
    );
  }

  Widget _buildBatteriesList(List<BatteryInfo> batteries) {
    if (batteries.isEmpty)
      return _buildEmptyTabContent("No Batteries Available");

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.medium),
      itemCount: batteries.length,
      itemBuilder: (context, index) {
        final battery = batteries[index];
        final charge = battery.vol ?? 0;
        final chargeColor = charge > 50
            ? AppColors.successColor
            : (charge > 20 ? AppColors.warningColor : AppColors.errorColor);

        return Card(
          margin: const EdgeInsets.symmetric(
              horizontal: AppSpacing.medium, vertical: AppSpacing.small),
          child: ListTile(
            leading: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.battery_std_rounded, color: chargeColor),
                Text("${charge}%",
                    style: AppTextStyles.bodyText2.copyWith(
                        color: chargeColor, fontWeight: FontWeight.bold)),
              ],
            ),
            title: Text("Battery: ${battery.batteryId ?? 'N/A'}",
                style: AppTextStyles.bodyText1
                    .copyWith(fontWeight: FontWeight.bold)),
            subtitle: Text("In Slot #${battery.slotNum?.toString() ?? 'N/A'}"),
          ),
        );
      },
    );
  }

  Widget _buildEmptyTabContent(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Text(
          message,
          style: AppTextStyles.bodyText1
              .copyWith(color: AppColors.secondaryTextColor),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // A shimmer/skeleton loader that mimics the final UI
  Widget _buildLoadingSkeleton() {
    return Shimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Skeleton
            Padding(
              padding: const EdgeInsets.all(AppSpacing.medium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 100, height: 16, color: Colors.white),
                  const SizedBox(height: AppSpacing.small),
                  Container(width: 200, height: 28, color: Colors.white),
                ],
              ),
            ),
            // TabBar Skeleton
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(4,
                  (_) => Container(width: 60, height: 48, color: Colors.white)),
            ),
            const Divider(height: 1),
            // Card Skeleton
            Padding(
              padding: const EdgeInsets.all(AppSpacing.medium),
              child: Column(
                children: List.generate(
                    2,
                    (_) => Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppSpacing.medium),
                          child: Container(
                            height: 150,
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(
                                    AppBorderRadius.large)),
                          ),
                        )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
