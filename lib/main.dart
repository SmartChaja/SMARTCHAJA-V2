import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_chaja/app_constants/app_constants.dart';
import 'package:smart_chaja/authentication/profile_screen/profile_screen.dart';
import 'package:smart_chaja/authentication/register/view/profile_creation_screen.dart';
import 'package:smart_chaja/authentication/register/view/send_otp_screen.dart';
import 'package:smart_chaja/authentication/welcome/welcome_screen.dart';
import 'package:smart_chaja/authentication/wallet/admin_dashboard.dart';
import 'package:smart_chaja/authentication/wallet/admin_rented_power_banks_screen.dart';
import 'package:smart_chaja/authentication/wallet/admin_transactions_screen.dart';
import 'package:smart_chaja/authentication/wallet/my-wallet.dart';
import 'package:smart_chaja/features/chargenow_devices/bind_device_to_shop/view/bind_device_to_shop_view.dart';
import 'package:smart_chaja/features/chargenow_devices/create_rent_order/view/create_rent_order_screen.dart';
import 'package:smart_chaja/features/chargenow_devices/create_rent_order/view/qr_generator_screen.dart';
import 'package:smart_chaja/features/chargenow_devices/create_shop/view/create_shop_view.dart';
import 'package:smart_chaja/features/chargenow_devices/delete_shop/view/delete_shop_view.dart';
import 'package:smart_chaja/features/chargenow_devices/device_info/view/widgets/charge_now_device_detail_screen.dart';
import 'package:smart_chaja/features/chargenow_devices/device_list/view/charge_now_devices_screen.dart';
import 'package:smart_chaja/features/chargenow_devices/device_list_advanced/view/device_list_view.dart';
import 'package:smart_chaja/features/chargenow_devices/eject_battery_slot/view/eject_battery_view.dart';
import 'package:smart_chaja/features/chargenow_devices/get_order_detail/view/get_order_detail_view.dart';
import 'package:smart_chaja/features/chargenow_devices/get_shop_list/view/get_shop_list_view.dart';
import 'package:smart_chaja/features/chargenow_devices/order_list/view/order_list_view.dart';
import 'package:smart_chaja/features/chargenow_devices/payment/azam/view/main_payment_screen.dart';
import 'package:smart_chaja/features/chargenow_devices/plan/view/plan_selection_view.dart';
import 'package:smart_chaja/features/chargenow_devices/query_rent_order_status/view/query_rent_order_view.dart';
import 'package:smart_chaja/features/chargenow_devices/rent_eject/view/rent_eject_view.dart';
import 'package:smart_chaja/features/chargenow_devices/splash_screen/splash_screen.dart';
import 'package:smart_chaja/features/chargenow_devices/update_shop/view/update_shop_view.dart';
import 'package:smart_chaja/localization/app_locale.dart';
import 'package:smart_chaja/localization/language_manager.dart';
import 'package:smart_chaja/localization/language_provider.dart';
import 'package:smart_chaja/session/app_provider_observer.dart';
import 'firebase_options.dart';
import 'package:upgrader/upgrader.dart';
import 'package:smart_chaja/features/chargenow_devices/payment/vodacom/service/vodacom_secure_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Load environment variables from .env file
    await dotenv.load(fileName: ".env");
    debugPrint('✅ Environment variables loaded');
  } catch (e) {
    debugPrint('⚠️ Warning: Could not load .env file: $e');
  }

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized');

    // Initialize Vodacom secure credentials
    await _initializeVodacomSecurityConfig();

    // Configure Firebase Auth settings
    await _configureFirebaseAuth();

    // ⚠️ TEMPORARILY DISABLED FOR EMULATOR TESTING
    // App Check is commented out to allow testing on emulators without Firebase blocking
    // MUST UNCOMMENT AND RE-ENABLE THIS BEFORE UPLOADING TO PLAY STORE!
    await _activateAppCheck();

    // Initialize localization
    await LanguageManager.init();
    debugPrint('✅ Localization initialized');

    runApp(
      ProviderScope(
        observers: [AppProviderObserver()],
        child: const MyApp(),
      ),
    );
  } catch (e) {
    debugPrint('❌ Error during app initialization: $e');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text('Failed to initialize app'),
                const SizedBox(height: 8),
                Text(e.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => main(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Initialize Vodacom secure configuration for API credentials
/// Fetches credentials from Firebase Remote Config at startup
Future<void> _initializeVodacomSecurityConfig() async {
  try {
    final secureConfig = VodacomSecureConfig();
    await secureConfig.initialize();
    debugPrint('✅ Vodacom secure credentials initialized');
  } catch (e) {
    debugPrint('⚠️ Warning: Vodacom security config initialization failed: $e');
    debugPrint('   Fallback to environment variables will be used');
  }
}

Future<void> _configureFirebaseAuth() async {
  try {
    final auth = FirebaseAuth.instance;
    await auth.setLanguageCode('en');
    debugPrint('✅ Firebase Auth configured');
  } catch (e) {
    debugPrint('⚠️ Warning: Firebase Auth configuration failed: $e');
  }
}

// ⚠️ APP CHECK FUNCTION - COMMENTED OUT FOR EMULATOR TESTING
// This function is disabled to allow testing on Android emulators
// Firebase was blocking all requests from emulator devices
//
// BEFORE PUBLISHING TO PLAY STORE:
// 1. UNCOMMENT the await _activateAppCheck(); line in main()
// 2. UNCOMMENT this entire function
// 3. Ensure androidProvider is set to AndroidProvider.playIntegrity (production)
// 4. Test thoroughly on a real device
//
Future<void> _activateAppCheck() async {
  try {
    // if (kDebugMode) {
    //   // ⚠️ DEBUG MODE ONLY - Disables strict device verification
    //   // This allows testing on emulators without Firebase blocking requests
    //   //
    //   // IMPORTANT: REMOVE THIS kDebugMode CHECK BEFORE PUBLISHING TO PLAY STORE!
    //   // In production, App Check must use playIntegrity for Android
    //   // Otherwise, you won't catch real device issues
    //   await FirebaseAppCheck.instance.activate(
    //     androidProvider: AndroidProvider.debug,
    //     appleProvider: AppleProvider.debug,
    //     webProvider: ReCaptchaV3Provider('debug-token'),
    //   );
    //   // Temporarily disabled to avoid rate limiting during testing
    //   // final token = await FirebaseAppCheck.instance.getToken();
    //   debugPrint(
    //       '✅ Firebase App Check activated (Debug mode - DEVICE CHECK DISABLED)');
    //   debugPrint(
    //       '⚠️ Remember: Remove kDebugMode check before Play Store release!');
    // } else {
    // Production build - Enable strict device verification
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
      appleProvider: AppleProvider.appAttestWithDeviceCheckFallback,
      webProvider: ReCaptchaV3Provider(
        dotenv.env['RECAPTCHA_V3_SITE_KEY'] ?? 'your-recaptcha-v3-site-key',
      ),
    );
    //   debugPrint(
    //       '✅ Firebase App Check activated (Production mode - STRICT VERIFICATION ENABLED)');
    // }
  } catch (error) {
    debugPrint('❌ Error activating Firebase App Check: $error');
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageState = ref.watch(languageProvider);

    final appTitle = AppLocale.appTitle.getString(context);

    return MaterialApp(
      title: appTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryColor),
        useMaterial3: true,
        fontFamily: languageState.localizationInstance.fontFamily,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
      routes: {
        '/map': (context) => const ChargeNowDevicesScreen(),
        '/wallet': (context) => const WalletScreen(),
        '/adminDashboard': (context) => const AdminDashboardScreen(),
        '/adminTransactions': (context) => const AdminTransactionsScreen(),
        '/adminRentedPowerBanks': (context) =>
            const AdminRentedPowerBanksScreen(),
        '/createShop': (context) => const CreateShopView(),
        '/updateShop': (context) => const UpdateShopView(),
        '/deleteShop': (context) => const DeleteShopView(),
        '/bindDeviceToShop': (context) => const BindDeviceToShopView(),
        '/getShopList': (context) => const GetShopListView(),
        '/createRentOrder': (context) => const CreateRentOrderScreen(),
        '/RentEject': (context) => const RentEjectView(),
        '/orderList': (context) => const OrderListView(),
        '/getOrderDetail': (context) => GetOrderDetailView(),
        '/queryRentOrder': (context) => QueryRentOrderView(),
        '/userprofile': (context) => const ProfileScreen(),
        '/deviceInfo': (context) => const ChargeNowDeviceDetailScreen(),
        '/deviceDetails': (context) => const DeviceListView(),
        '/ejectBattery': (context) => EjectBatteryView(),
        '/welcome': (context) => const WelcomeScreen(),
        '/send-otp': (context) => const SendOtpScreen(),
        '/register': (context) => const ProfileCreationScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/splash': (context) => const SplashScreen(),
        '/qr-generator': (context) => const QRGeneratorScreen(),
        '/payment': (context) => const MainPaymentScreen(),
        '/plans': (context) => const PlanSelectionView(),
        '/home': (context) => const ChargeNowDevicesScreen(),
      },
      supportedLocales: languageState.localizationInstance.supportedLocales,
      localizationsDelegates:
          languageState.localizationInstance.localizationsDelegates,
      home: UpgradeAlert(
        child: const SplashScreen(),
      ),
      builder: (context, child) {
        ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text(
                      'Something went wrong',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (kDebugMode) ...[
                      Text(
                        errorDetails.exception.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          runApp(
                            ProviderScope(
                              observers: [AppProviderObserver()],
                              child: const MyApp(),
                            ),
                          );
                        },
                        child: const Text('Restart App'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        };
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
