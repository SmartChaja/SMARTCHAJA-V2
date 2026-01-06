import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:smart_chaja/features/chargenow_devices/device_list/model/charge_now_device_list_response.dart';

class NavigationHelper {
  /// Shows a dialog to let user choose their preferred navigation app
  static Future<void> showNavigationOptions(
    BuildContext context,
    DeviceListItem device,
  ) async {
    if (!context.mounted) return; // Ensure context is valid

    final shop = device.shop;
    if (shop == null || shop.latitude.isEmpty || shop.longitude.isEmpty) {
      _showErrorSnackBar(context, 'Location information not available');
      return;
    }

    final lat = double.tryParse(shop.latitude);
    final lng = double.tryParse(shop.longitude);

    if (lat == null || lng == null) {
      _showErrorSnackBar(context, 'Invalid location coordinates');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Enable scrollable content
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => NavigationOptionsSheet(
        shopName: shop.shopName.isNotEmpty ? shop.shopName : 'Unnamed Shop',
        shopAddress: shop.shopAddress.isNotEmpty ? shop.shopAddress : 'No Address',
        latitude: lat,
        longitude: lng,
      ),
    );
  }

  /// Launch Google Maps with directions
  static Future<void> launchGoogleMaps(
    double lat,
    double lng,
    String destination,
  ) async {
    final url = Platform.isIOS
        ? 'https://maps.apple.com/?daddr=$lat,$lng&dirflg=d'
        : 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving';

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch maps';
    }
  }

  /// Launch Waze navigation
  static Future<void> launchWaze(double lat, double lng) async {
    final url = 'https://waze.com/ul?ll=$lat,$lng&navigate=yes';
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch Waze';
    }
  }

  /// Launch default maps app with coordinates
  static Future<void> launchDefaultMaps(double lat, double lng) async {
    final url = 'geo:$lat,$lng?q=$lat,$lng';
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // Fallback to Google Maps web
      await launchGoogleMaps(lat, lng, '');
    }
  }

  static void _showErrorSnackBar(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class NavigationOptionsSheet extends StatelessWidget {
  final String shopName;
  final String shopAddress;
  final double latitude;
  final double longitude;

  const NavigationOptionsSheet({
    super.key,
    required this.shopName,
    required this.shopAddress,
    required this.latitude,
    required this.longitude,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8, // Limit height
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Navigate to',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ) ??
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                shopName,
                style: Theme.of(context).textTheme.titleMedium ??
                    const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                shopAddress,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ) ??
                    TextStyle(fontSize: 14, color: Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 24),
              Text(
                'Choose navigation app:',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ) ??
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              // Navigation options
              _buildNavigationOption(
                context,
                icon: Icons.map,
                title: Platform.isIOS ? 'Apple Maps' : 'Google Maps',
                subtitle: 'Default maps application',
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await NavigationHelper.launchGoogleMaps(
                      latitude,
                      longitude,
                      shopName,
                    );
                  } catch (e) {
                    NavigationHelper._showErrorSnackBar(
                      context,
                      'Could not open maps app',
                    );
                  }
                },
              ),
              _buildNavigationOption(
                context,
                icon: Icons.navigation,
                title: 'Waze',
                subtitle: 'Navigate with Waze',
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await NavigationHelper.launchWaze(latitude, longitude);
                  } catch (e) {
                    NavigationHelper._showErrorSnackBar(
                      context,
                      'Could not open Waze. Make sure it\'s installed.',
                    );
                  }
                },
              ),
              _buildNavigationOption(
                context,
                icon: Icons.share_location,
                title: 'Other Apps',
                subtitle: 'Share location with other apps',
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await NavigationHelper.launchDefaultMaps(latitude, longitude);
                  } catch (e) {
                    NavigationHelper._showErrorSnackBar(
                      context,
                      'Could not share location',
                    );
                  }
                },
              ),
              const SizedBox(height: 16),
              // Cancel button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(height: 16), // Extra padding for safety
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ) ??
                        const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ) ??
                        TextStyle(fontSize: 12, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}