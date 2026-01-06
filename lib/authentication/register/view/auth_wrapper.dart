// Optional: Enhanced AuthWrapper with error handling
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_chaja/authentication/beemafrica_service.dart/send_otp_screen.dart';
import 'package:smart_chaja/authentication/register/view/profile_creation_screen.dart';
import 'package:smart_chaja/authentication/register/viewmodels/auth_viewmodel.dart';
import 'package:smart_chaja/features/chargenow_devices/device_list/view/charge_now_devices_screen.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authViewModelProvider);

    // Show error if there's an authentication error
    if (authState.error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Authentication Error',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  authState.error!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  ref.read(authViewModelProvider.notifier).clearError();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // User is not authenticated - show login screen
    if (!authState.isAuthenticated) {
      return const SendOtpScreen();
    }

    // User is authenticated but no profile exists - show registration screen
    if (authState.user == null) {
      return const ProfileCreationScreen();
    }

    // User is authenticated and has a profile - show main app
    return const ChargeNowDevicesScreen();
  }
}
