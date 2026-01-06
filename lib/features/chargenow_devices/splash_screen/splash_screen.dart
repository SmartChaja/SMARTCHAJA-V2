import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:smart_chaja/app_constants/app_constants.dart';
import 'package:smart_chaja/authentication/register/repositories/auth_repository.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        _controller.repeat();
      }
    });
    // Run authentication check after a short delay
    Future.delayed(const Duration(milliseconds: 1500), _checkAuth);
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    final authRepository = ref.read(authRepositoryProvider);
    final currentUser = authRepository.currentUser;
    if (currentUser != null) {
      try {
        final profileExists =
            await authRepository.userProfileExists(currentUser.uid);
        if (!mounted) return;
        if (profileExists) {
          debugPrint('✅ User authenticated with profile → Navigating to Home');
          _navigateTo('/map');
        } else {
          debugPrint(
              '⚠️ User authenticated but no profile → Navigating to Register');
          _navigateTo('/register');
        }
      } catch (e) {
        debugPrint('❌ Error checking profile existence: $e');
        if (!mounted) return;
        _navigateTo('/register');
      }
    } else {
      debugPrint('❌ User not authenticated → Navigating to Welcome');
      _navigateTo('/welcome');
    }
  }

  void _navigateTo(String route) {
    if (!mounted) return;
    debugPrint('🚀 Navigating to route: $route');
    Navigator.of(context).pushReplacementNamed(route).catchError((error) {
      debugPrint('❌ Navigation error to $route: $error');
      return null;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/lottie/power.json',
              controller: _controller,
              width: 200,
              height: 200,
              fit: BoxFit.contain,
              onLoaded: (composition) {
                _controller
                  ..duration = composition.duration
                  ..repeat();
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'SmartChaja',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 0, 167, 50),
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(
              color: Color.fromARGB(255, 0, 116, 4),
            ),
          ],
        ),
      ),
    );
  }
}
