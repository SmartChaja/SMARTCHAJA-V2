import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_chaja/app_constants/app_constants.dart';
import 'package:smart_chaja/authentication/register/viewmodels/auth_viewmodel.dart';
import 'package:smart_chaja/localization/app_locale.dart';
import 'package:smart_chaja/localization/language_selector.dart';
import 'package:intl/intl.dart';
import 'package:smart_chaja/features/chargenow_devices/plan/provider/plan_provider.dart';
import 'package:smart_chaja/features/chargenow_devices/plan/model/plan_state.dart';
import 'dart:ui';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isNavigatingAfterDeletion = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authViewModelProvider);
    final user = authState.user;
    final isAdmin = user?.role == 'admin';
    final isDark = theme.brightness == Brightness.dark;
    const primaryColor = Color(0xFF10B981); // Emerald green

    // Listen for auth state changes - if user becomes unauthenticated after deletion, navigate immediately
    // This listener only triggers when the value changes, not on every build
    ref.listen<bool>(authViewModelProvider.select((state) => state.isAuthenticated), (previous, next) {
      if (previous == true && next == false && !_isNavigatingAfterDeletion && mounted) {
        // User just became unauthenticated (likely after deletion) - navigate to welcome immediately
        _isNavigatingAfterDeletion = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
              '/welcome',
              (route) => false,
            );
          }
        });
      }
    });

    if (authState.isLoading) {
      return Scaffold(
        backgroundColor:
            isDark ? AppColors.backgroundColorDark : AppColors.backgroundColor,
        body:
            const Center(child: CircularProgressIndicator(color: primaryColor)),
      );
    }

    if (authState.error != null) {
      return Scaffold(
        backgroundColor:
            isDark ? AppColors.backgroundColorDark : AppColors.backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.errorColor),
              const SizedBox(height: 16),
              Text('Error loading profile',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(color: AppColors.errorColor)),
              const SizedBox(height: 8),
              Text(
                authState.error!,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.errorColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () =>
                    ref.read(authViewModelProvider.notifier).clearError(),
                style: FilledButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // If not authenticated and we're not navigating, show payment plans and sign in
    // But if we're navigating after deletion, show loading to prevent flicker
    if (!authState.isAuthenticated || user == null) {
      if (_isNavigatingAfterDeletion) {
        // Show loading while navigating to prevent showing "sign in" screen
        return Scaffold(
          backgroundColor:
              isDark ? AppColors.backgroundColorDark : AppColors.backgroundColor,
          body: const Center(child: CircularProgressIndicator()),
        );
      }
      return Scaffold(
        backgroundColor:
            isDark ? AppColors.backgroundColorDark : AppColors.backgroundColor,
        body: Column(
          children: [
            // Header section with gradient - full width
            Container(
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryColor.withOpacity(0.95),
                    primaryColor.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.person_outline_rounded,
                          size: 28,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Your Profile',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Join SmartChaja to manage rentals & track your account',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Scrollable content - full width
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile Features Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create Your Account',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildProfileFeatureItem(
                            context,
                            theme,
                            Icons.electric_bolt_rounded,
                            'Rent Power Banks',
                            'Access premium rental plans instantly',
                            primaryColor,
                          ),
                          const SizedBox(height: 12),
                          _buildProfileFeatureItem(
                            context,
                            theme,
                            Icons.wallet_rounded,
                            'Manage Wallet',
                            'Track balance, transactions & refunds',
                            primaryColor,
                          ),
                          const SizedBox(height: 12),
                          _buildProfileFeatureItem(
                            context,
                            theme,
                            Icons.history_rounded,
                            'View History',
                            'Check all your rental & transaction history',
                            primaryColor,
                          ),
                          const SizedBox(height: 12),
                          _buildProfileFeatureItem(
                            context,
                            theme,
                            Icons.verified_rounded,
                            'Secure Account',
                            'Your data is protected with enterprise security',
                            primaryColor,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Rental Plans Preview
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: primaryColor.withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Available Rental Plans',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: primaryColor,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Browse our flexible rental plans designed for your needs',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            
            // Fixed CTA Buttons at bottom - full width
            Container(
              width: MediaQuery.of(context).size.width,
              padding: const EdgeInsets.all(16),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Rent Plan Button
                    FilledButton(
                      onPressed: () {
                        // Show rental plans in a modal or navigate to plans page
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (context) => DraggableScrollableSheet(
                            expand: false,
                            initialChildSize: 0.9,
                            maxChildSize: 0.95,
                            builder: (context, scrollController) => SingleChildScrollView(
                              controller: scrollController,
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Our Rental Plans',
                                          style: theme.textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () => Navigator.pop(context),
                                          icon: const Icon(Icons.close_rounded),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    _buildPaymentPlansList(context, theme, primaryColor, ref),
                                    const SizedBox(height: 24),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.card_giftcard, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'View Rental Plans',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Sign In Button
                    OutlinedButton(
                      onPressed: () =>
                          Navigator.pushReplacementNamed(context, '/send-otp'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        side: BorderSide(color: primaryColor, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.arrow_forward_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Sign In for Full Access',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundColorDark : AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Profile',
          style: theme.textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: SafeArea(
              top:
                  false, // Avoid extra padding since AppBar handles top safe area
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(context, user, primaryColor),
                  const SizedBox(height: 24),
                  _buildSettingsGroup(
                    context,
                    title: 'Personal Information',
                    children: [
                      _buildInfoItem(
                        context,
                        icon: Icons.person_outline_rounded,
                        label: AppLocale.fullName.getString(context),
                        value: user.fullName,
                        primaryColor: primaryColor,
                      ),
                      _buildInfoItem(
                        context,
                        icon: Icons.phone_outlined,
                        label: AppLocale.phoneNumber.getString(context),
                        value: user.phoneNumber,
                        primaryColor: primaryColor,
                      ),
                      _buildInfoItem(
                        context,
                        icon: Icons.wc_outlined,
                        label: AppLocale.gender.getString(context),
                        value: user.gender,
                        primaryColor: primaryColor,
                      ),
                      _buildInfoItem(
                        context,
                        icon: Icons.calendar_today_outlined,
                        label: 'Date of Birth',
                        value:
                            DateFormat('MMM dd, yyyy').format(user.dateOfBirth),
                        primaryColor: primaryColor,
                      ),
                      _buildInfoItem(
                        context,
                        icon: Icons.badge_outlined,
                        label: AppLocale.nationalId.getString(context),
                        value: user.nationalId,
                        isLast: true,
                        primaryColor: primaryColor,
                      ),
                    ],
                  ),
                  _buildSettingsGroup(
                    context,
                    title: 'Account Statistics',
                    children: [
                      _buildInfoItem(
                        context,
                        icon: Icons.calendar_today_rounded,
                        label: 'Member Since',
                        value: DateFormat('MMM yyyy').format(user.createdAt),
                        primaryColor: primaryColor,
                      ),
                      _buildInfoItem(
                        context,
                        icon: Icons.badge_rounded,
                        label: 'ID Number',
                        value:
                            '${user.nationalId.length >= 4 ? user.nationalId.substring(0, 4) : user.nationalId}****',
                        isLast: true,
                        primaryColor: primaryColor,
                      ),
                    ],
                  ),
                  _buildSettingsGroup(
                    context,
                    title: 'Preferences',
                    children: [
                      _buildLanguageItem(context, primaryColor: primaryColor),
                    ],
                  ),
                  if (isAdmin)
                    _buildSettingsGroup(
                      context,
                      title: 'Quick Actions',
                      children: [
                        _buildSettingsItem(
                          context,
                          icon: Icons.dashboard_rounded,
                          title: 'Admin Managament',
                          onTap: () =>
                              Navigator.pushNamed(context, '/adminDashboard'),
                          primaryColor: primaryColor,
                        ),
                        _buildSettingsItem(
                          context,
                          icon: Icons.list_rounded,
                          title: 'Rented Power Banks',
                          onTap: () => Navigator.pushNamed(
                              context, '/adminRentedPowerBanks'),
                          primaryColor: primaryColor,
                        ),
                        _buildSettingsItem(
                          context,
                          icon: Icons.wallet_rounded,
                          title: 'Transactions',
                          onTap: () => Navigator.pushNamed(
                              context, '/adminTransactions'),
                          primaryColor: primaryColor,
                        ),
                        _buildSettingsItem(
                          context,
                          icon: Icons.qr_code_2_rounded,
                          title: 'QR Generator',
                          onTap: () =>
                              Navigator.pushNamed(context, '/qr-generator'),
                          primaryColor: primaryColor,
                        ),
                        _buildSettingsItem(
                          context,
                          icon: Icons.qr_code_scanner_rounded,
                          title: 'QR Scanner',
                          onTap: () =>
                              Navigator.pushNamed(context, '/createRentOrder'),
                          primaryColor: primaryColor,
                        ),
                        _buildSettingsItem(
                          context,
                          icon: Icons.qr_code_scanner_rounded,
                          title: 'View Plans',
                          onTap: () => Navigator.pushNamed(context, '/plans'),
                          primaryColor: primaryColor,
                        ),
                        _buildSettingsItem(
                          context,
                          icon: Icons.shop_2_rounded,
                          title: 'Create Shop',
                          onTap: () =>
                              Navigator.pushNamed(context, '/createShop'),
                          primaryColor: primaryColor,
                        ),
                        _buildSettingsItem(
                          context,
                          icon: Icons.shop_2_rounded,
                          title: 'Update Shop',
                          onTap: () =>
                              Navigator.pushNamed(context, '/updateShop'),
                          primaryColor: primaryColor,
                        ),
                        _buildSettingsItem(
                          context,
                          icon: Icons.shop_2_rounded,
                          title: 'Delete Shop',
                          onTap: () =>
                              Navigator.pushNamed(context, '/deleteShop'),
                          primaryColor: primaryColor,
                        ),
                        _buildSettingsItem(
                          context,
                          icon: Icons.shop_2_rounded,
                          title: 'Get Shop List',
                          onTap: () =>
                              Navigator.pushNamed(context, '/getShopList'),
                          primaryColor: primaryColor,
                        ),
                        _buildSettingsItem(
                          context,
                          icon: Icons.info_rounded,
                          title: 'Device Information',
                          onTap: () =>
                              Navigator.pushNamed(context, '/deviceInfo'),
                          primaryColor: primaryColor,
                        ),
                        _buildSettingsItem(
                          context,
                          icon: Icons.add_rounded,
                          title: 'Bind Device to Shop',
                          onTap: () =>
                              Navigator.pushNamed(context, '/bindDeviceToShop'),
                          primaryColor: primaryColor,
                        ),
                        _buildSettingsItem(
                          context,
                          icon: Icons.add_rounded,
                          title: 'Rent and Eject specified Slot',
                          onTap: () =>
                              Navigator.pushNamed(context, '/RentEject'),
                          primaryColor: primaryColor,
                        ),
                        _buildSettingsItem(
                          context,
                          icon: Icons.list_rounded,
                          title: 'Order List',
                          onTap: () =>
                              Navigator.pushNamed(context, '/orderList'),
                          primaryColor: primaryColor,
                        ),
                        _buildSettingsItem(
                          context,
                          icon: Icons.wallet_rounded,
                          title: 'Get Order Details',
                          onTap: () =>
                              Navigator.pushNamed(context, '/getOrderDetail'),
                          primaryColor: primaryColor,
                        ),
                        _buildSettingsItem(
                          context,
                          icon: Icons.history_rounded,
                          title: 'Query Rent Order',
                          onTap: () =>
                              Navigator.pushNamed(context, '/queryRentOrder'),
                          primaryColor: primaryColor,
                        ),
                        _buildSettingsItem(
                          context,
                          icon: Icons.eject_rounded,
                          title: 'Eject Battery',
                          onTap: () =>
                              Navigator.pushNamed(context, '/ejectBattery'),
                          primaryColor: primaryColor,
                        ),
                        _buildSettingsItem(
                          context,
                          icon: Icons.wallet_rounded,
                          title: 'Wallet',
                          onTap: () => Navigator.pushNamed(context, '/wallet'),
                          primaryColor: primaryColor,
                        ),
                        _buildSettingsItem(
                          context,
                          icon: Icons.history_rounded,
                          title: 'Activity History',
                          onTap: () {},
                          primaryColor: primaryColor,
                        ),
                      ],
                    ),
                  _buildSettingsGroup(
                    context,
                    title: 'Account',
                    children: [
                      _buildSettingsItem(
                        context,
                        icon: Icons.edit_rounded,
                        title: AppLocale.editProfile.getString(context),
                        onTap: () => _showEditProfileDialog(context, ref, user),
                        primaryColor: primaryColor,
                      ),
                      _buildSettingsItem(
                        context,
                        icon: Icons.support_agent_rounded,
                        title: 'Support',
                        onTap: () {},
                        primaryColor: primaryColor,
                      ),
                      _buildSettingsItem(
                        context,
                        icon: Icons.logout_rounded,
                        title: 'Sign Out',
                        onTap: () => _showSignOutDialog(context, ref),
                        textColor: AppColors.errorColor,
                        isLast: false,
                        primaryColor: primaryColor,
                      ),
                      _buildSettingsItem(
                        context,
                        icon: Icons.delete_forever_rounded,
                        title: 'Delete Account',
                        onTap: () => _showDeleteAccountDialog(context, ref),
                        textColor: AppColors.errorColor,
                        isLast: true,
                        primaryColor: primaryColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: () => _showEditProfileDialog(context, ref, user),
              backgroundColor: primaryColor,
              child: const Icon(Icons.edit_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, user, Color primaryColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor,
            isDark
                ? primaryColor.withOpacity(0.8)
                : primaryColor.withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Hero(
            tag: 'profile_picture',
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: user.profilePictureUrl != null
                  ? ClipOval(
                      child: Image.network(
                        user.profilePictureUrl!,
                        fit: BoxFit.cover,
                        width: 80,
                        height: 80,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                          CupertinoIcons.person_fill,
                          size: 40,
                          color: Colors.white,
                        ),
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: progress.expectedTotalBytes != null
                                  ? progress.cumulativeBytesLoaded /
                                      (progress.expectedTotalBytes ?? 1)
                                  : null,
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                    )
                  : const Icon(
                      CupertinoIcons.person_fill,
                      size: 40,
                      color: Colors.white,
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  user.phoneNumber,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Text(
                    user.role.toUpperCase(),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(BuildContext context,
      {required String title, required List<Widget> children}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.secondaryTextColorDark
                    : AppColors.secondaryTextColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color:
                  isDark ? AppColors.surfaceColorDark : AppColors.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Column(children: children),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    Color? textColor,
    bool isLast = false,
    required Color primaryColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(isLast ? 0 : 12),
          bottom: Radius.circular(isLast ? 12 : 0),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: isLast
                ? null
                : Border(
                    bottom: BorderSide(
                      color: isDark
                          ? AppColors.dividerColorDark
                          : AppColors.dividerColor,
                      width: 0.5,
                    ),
                  ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: textColor ?? primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: textColor ??
                        (isDark
                            ? AppColors.primaryTextColorDark
                            : AppColors.primaryTextColor),
                  ),
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark
                      ? AppColors.secondaryTextColorDark
                      : AppColors.secondaryTextColor,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool isLast = false,
    required Color primaryColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: isDark
                      ? AppColors.dividerColorDark
                      : AppColors.dividerColor,
                  width: 0.5,
                ),
              ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 18,
              color: primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.secondaryTextColorDark
                        : AppColors.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.primaryTextColorDark
                        : AppColors.primaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageItem(BuildContext context,
      {required Color primaryColor}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.language_rounded,
              size: 18,
              color: primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppLocale.language.getString(context),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppColors.primaryTextColorDark
                    : AppColors.primaryTextColor,
              ),
            ),
          ),
          const LanguageSelector(),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, WidgetRef ref, user) {
    final formKey = GlobalKey<FormState>();
    final fullNameController = TextEditingController(text: user.fullName);
    final nationalIdController = TextEditingController(text: user.nationalId);
    String selectedGender = user.gender;
    DateTime selectedDate = user.dateOfBirth;
    const primaryColor = Color(0xFF10B981);

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Edit Profile'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: fullNameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      prefixIcon: const Icon(Icons.person_outline_rounded,
                          color: primaryColor),
                    ),
                    validator: (value) => value?.trim().isEmpty ?? true
                        ? 'Please enter your full name'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedGender,
                    decoration: InputDecoration(
                      labelText: 'Gender',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      prefixIcon:
                          const Icon(Icons.wc_outlined, color: primaryColor),
                    ),
                    items: ['Male', 'Female', 'Other']
                        .map((gender) => DropdownMenuItem(
                            value: gender, child: Text(gender)))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => selectedGender = value!),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                        builder: (context, child) => Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: primaryColor,
                              onPrimary: Colors.white,
                              surface: Colors.white,
                              onSurface: Colors.black87,
                            ),
                          ),
                          child: child!,
                        ),
                      );
                      if (date != null) setState(() => selectedDate = date);
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Date of Birth',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        prefixIcon: const Icon(Icons.calendar_today_outlined,
                            color: primaryColor),
                      ),
                      child:
                          Text(DateFormat('MMM dd, yyyy').format(selectedDate)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nationalIdController,
                    decoration: InputDecoration(
                      labelText: 'National ID',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      prefixIcon:
                          const Icon(Icons.badge_outlined, color: primaryColor),
                    ),
                    validator: (value) => value?.trim().isEmpty ?? true
                        ? 'Please enter your national ID'
                        : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            FilledButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  Navigator.of(dialogContext).pop();
                  final success = await ref
                      .read(authViewModelProvider.notifier)
                      .updateUserProfile(
                        fullName: fullNameController.text.trim(),
                        gender: selectedGender,
                        dateOfBirth: selectedDate,
                        nationalId: nationalIdController.text.trim(),
                      );
                  if (!context.mounted) {
                    return; // Check if context is still valid
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Profile updated successfully'
                            : ref.read(authViewModelProvider).error ??
                                'Failed to update profile',
                      ),
                      backgroundColor:
                          success ? primaryColor : AppColors.errorColor,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  );
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Sign Out'),
        content: const Text(
            'Are you sure you want to sign out? You will need to sign in again to access your account.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await ref.read(authViewModelProvider.notifier).signOut();
              if (!context.mounted) return; // Check if context is still valid
              Navigator.pushReplacementNamed(context, '/send-otp');
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.errorColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Delete Account'),
        content: const Text(
          'This will permanently delete your account and all associated data. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _showDeleteConfirmationDialog(context, ref);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.errorColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, WidgetRef ref) {
    final confirmController = TextEditingController();
    final feedbackController = TextEditingController();
    ValueNotifier<bool> isDeleteEnabled = ValueNotifier(false);

    confirmController.addListener(() {
      isDeleteEnabled.value = confirmController.text == 'Delete';
    });

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Confirm Account Deletion'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Type "Delete" to confirm:'),
              const SizedBox(height: 12),
              TextField(
                controller: confirmController,
                decoration: InputDecoration(
                  hintText: 'Type "Delete"',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Why are you deleting your account? (Optional)'),
              const SizedBox(height: 8),
              TextField(
                controller: feedbackController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Your feedback helps us improve...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: isDeleteEnabled,
            builder: (context, isEnabled, _) => FilledButton(
              onPressed: isEnabled
                  ? () async {
                      // Close the dialog first
                      Navigator.of(dialogContext).pop();
                      
                      // Show loading
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Deleting account...')),
                        );
                      }

                      debugPrint('🔴 DELETING ACCOUNT: Started deletion process...');
                      final success = await ref
                          .read(authViewModelProvider.notifier)
                          .deleteAccount(feedback: feedbackController.text);
                      debugPrint('🔴 DELETING ACCOUNT: Success=$success');

                      if (success) {
                        debugPrint('✅ DELETION SUCCESSFUL: Navigating to welcome screen');
                        if (!context.mounted) return;
                        
                        // Set flag to prevent showing "sign in" screen during navigation
                        if (mounted) {
                          setState(() {
                            _isNavigatingAfterDeletion = true;
                          });
                        }
                        
                        // Navigate immediately to welcome screen using root navigator
                        final navigator = Navigator.of(context, rootNavigator: true);
                        navigator.pushNamedAndRemoveUntil(
                          '/welcome',
                          (route) => false,
                        );
                        debugPrint('✅ NAVIGATION: Navigated to /welcome');
                      } else {
                        // Show error
                        debugPrint('❌ DELETION FAILED: Showing error message');
                        if (!context.mounted) return;
                        final error = ref.read(authViewModelProvider).error;
                        debugPrint('❌ ERROR MESSAGE: $error');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Error: ${error ?? 'Failed to delete account'}')),
                        );
                      }
                    }
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor:
                    isEnabled ? AppColors.errorColor : Colors.grey[400],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Delete Permanently'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitRow(
    BuildContext context,
    ThemeData theme,
    IconData icon,
    String title,
    String subtitle,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactBenefitRow(
    BuildContext context,
    ThemeData theme,
    IconData icon,
    String title,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileFeatureItem(
    BuildContext context,
    ThemeData theme,
    IconData icon,
    String title,
    String subtitle,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.black54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentPlansList(
    BuildContext context,
    ThemeData theme,
    Color primaryColor,
    WidgetRef ref,
  ) {
    final planState = ref.watch(planViewModelProvider);

    // Only fetch plans if not already loaded or loading
    if (planState.status != PlanStatus.loading &&
        planState.status != PlanStatus.success &&
        planState.status != PlanStatus.error) {
      Future.microtask(
        () => ref.read(planViewModelProvider.notifier).fetchPlans(),
      );
    }

    if (planState.status == PlanStatus.loading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: primaryColor),
              const SizedBox(height: 16),
              Text(
                'Loading available plans...',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    if (planState.status == PlanStatus.error) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[200]!, width: 1.5),
              ),
              child: Column(
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
                  const SizedBox(height: 12),
                  Text(
                    'Unable to Load Plans',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.red[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please check your connection and try again',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.red[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      ref.read(planViewModelProvider.notifier).fetchPlans();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (planState.plans == null || planState.plans!.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(Icons.info_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'No Plans Available',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: planState.plans!.length,
      itemBuilder: (context, index) {
        final plan = planState.plans![index];
        final isFirstPlan = index == 0;
        final isPopular = index == 1; // Mark second plan as popular

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Stack(
            children: [
              // Main card
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: isPopular
                        ? [primaryColor.withOpacity(0.95), primaryColor.withOpacity(0.85)]
                        : [Colors.white, Colors.grey[50]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isPopular
                          ? primaryColor.withOpacity(0.3)
                          : Colors.black.withOpacity(0.08),
                      blurRadius: isPopular ? 16 : 12,
                      offset: Offset(0, isPopular ? 8 : 4),
                    ),
                  ],
                  border: Border.all(
                    color: isPopular
                        ? primaryColor.withOpacity(0.4)
                        : Colors.grey[200]!,
                    width: 1.5,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  plan.name,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: isPopular ? Colors.white : Colors.black87,
                                    fontSize: 20,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.schedule_rounded,
                                      size: 16,
                                      color: isPopular
                                          ? Colors.white.withOpacity(0.8)
                                          : Colors.grey[600],
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${plan.durationDays} day${plan.durationDays > 1 ? 's' : ''} duration',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: isPopular
                                            ? Colors.white.withOpacity(0.9)
                                            : Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Price badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isPopular
                                  ? Colors.white.withOpacity(0.2)
                                  : primaryColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isPopular
                                    ? Colors.white.withOpacity(0.3)
                                    : primaryColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${plan.price.toStringAsFixed(0)}',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: isPopular ? Colors.white : primaryColor,
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  plan.currency,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: isPopular
                                        ? Colors.white.withOpacity(0.8)
                                        : Colors.grey[600],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Divider
                      Container(
                        height: 1,
                        color: isPopular
                            ? Colors.white.withOpacity(0.2)
                            : Colors.grey[200],
                      ),
                      const SizedBox(height: 16),
                      // Features row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isPopular
                                  ? Colors.white.withOpacity(0.1)
                                  : primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.flash_on,
                              size: 16,
                              color:
                                  isPopular ? Colors.white : primaryColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Instant activation & 24/7 support',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isPopular
                                    ? Colors.white.withOpacity(0.9)
                                    : Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Popular badge
              if (isPopular)
                Positioned(
                  top: 0,
                  right: 20,
                  child: Transform.translate(
                    offset: const Offset(0, -8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber[400],
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber[400]!.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: Colors.amber[900],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Most Popular',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.amber[900],
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
