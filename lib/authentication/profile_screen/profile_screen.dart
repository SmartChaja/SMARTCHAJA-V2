import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_chaja/app_constants/app_constants.dart';
import 'package:smart_chaja/authentication/register/viewmodels/auth_viewmodel.dart';
import 'package:smart_chaja/localization/app_locale.dart';
import 'package:smart_chaja/localization/language_selector.dart';
import 'package:intl/intl.dart';
import 'dart:ui';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authViewModelProvider);
    final user = authState.user;
    final isAdmin = user?.role == 'admin';
    final isDark = theme.brightness == Brightness.dark;
    const primaryColor = Color(0xFF10B981); // Emerald green

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

    if (!authState.isAuthenticated || user == null) {
      return Scaffold(
        backgroundColor:
            isDark ? AppColors.backgroundColorDark : AppColors.backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_outline, size: 48, color: primaryColor),
              const SizedBox(height: 16),
              Text(
                'Please sign in to view your profile',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/login'),
                style: FilledButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Sign In'),
              ),
            ],
          ),
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
}
