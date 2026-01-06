import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_chaja/app_constants/app_constants.dart';
import 'package:smart_chaja/authentication/register/repositories/auth_repository.dart';
import 'package:smart_chaja/authentication/register/view/verify_otp_screen.dart';
import 'package:smart_chaja/authentication/register/viewmodels/auth_viewmodel.dart';
import 'package:smart_chaja/reusable_widgets/phone_number_input.dart';
import 'package:smart_chaja/reusable_widgets/snack_bar.dart';

class SendOtpScreen extends ConsumerStatefulWidget {
  const SendOtpScreen({super.key});

  @override
  ConsumerState<SendOtpScreen> createState() => _SendOtpScreenState();
}

class _SendOtpScreenState extends ConsumerState<SendOtpScreen>
    with TickerProviderStateMixin {
  String _fullPhoneNumber = '';
  bool _isSendingOtp = false;
  DateTime? _lastOtpRequest;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _animationController, curve: Curves.easeOutCubic));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _sendOtp() async {
    if (_fullPhoneNumber.isEmpty) {
      TopSnackBar.show(context, 'Please enter a valid phone number',
          color: Colors.red);
      return;
    }

    if (_lastOtpRequest != null &&
        DateTime.now().difference(_lastOtpRequest!).inSeconds < 60) {
      TopSnackBar.show(context, 'Please wait before requesting another OTP',
          color: Colors.orange);
      return;
    }

    setState(() {
      _isSendingOtp = true;
      _lastOtpRequest = DateTime.now();
    });

    final authViewModel = ref.read(authViewModelProvider.notifier);
    final tempController = TextEditingController();

    try {
      await authViewModel.sendOTP(
        _fullPhoneNumber,
        pinController: tempController,
        onAutoVerificationCompleted: () {
          debugPrint('🤖 Auto verification completed in SendOtpScreen');
          _navigateAfterAuth();
        },
      );
    } catch (e) {
      debugPrint('❌ OTP sending failed: $e');
      setState(() => _isSendingOtp = false);
    } finally {
      tempController.dispose();
    }
  }

  // Centralized navigation logic after successful authentication
  void _navigateAfterAuth() async {
    final authRepository = ref.read(authRepositoryProvider);
    final currentUser = authRepository.currentUser;

    if (currentUser == null) {
      TopSnackBar.show(context, 'Authentication failed', color: Colors.red);
      setState(() => _isSendingOtp = false);
      return;
    }

    try {
      final profileExists =
          await authRepository.userProfileExists(currentUser.uid);

      if (!mounted) return;

      if (profileExists) {
        TopSnackBar.show(context, 'Login successful!', color: Colors.green);
        Navigator.pushReplacementNamed(context, '/map');
      } else {
        TopSnackBar.show(context, 'Please complete your profile',
            color: Colors.blue);
        Navigator.pushReplacementNamed(context, '/register');
      }
    } catch (e) {
      debugPrint('❌ Error checking profile: $e');
      TopSnackBar.show(context, 'Error verifying profile. Please try again.',
          color: Colors.red);
      setState(() => _isSendingOtp = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authViewModelProvider, (previous, next) {
      if (next.error != null) {
        TopSnackBar.show(context, next.error!, color: Colors.red);
        ref.read(authViewModelProvider.notifier).clearError();
        setState(() => _isSendingOtp = false);
      } else if (next.verificationId != null &&
          previous?.verificationId != next.verificationId) {
        // Manual OTP verification needed - navigate to VerifyOtpScreen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VerifyOtpScreen(
              phoneNumber: _fullPhoneNumber,
            ),
          ),
        );
        setState(() => _isSendingOtp = false);
      }
    });

    final isLoading =
        ref.watch(authViewModelProvider.select((state) => state.isLoading)) ||
            _isSendingOtp;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _buildPhoneInput(isLoading),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 30),
      decoration: const BoxDecoration(),
      child: const Column(
        children: [
          Text(
            'Welcome',
            style: TextStyle(
              color: AppColors.primaryTextColor,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'Enter your phone number to get started',
            style: TextStyle(
              color: AppColors.secondaryTextColor,
              fontSize: 16,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneInput(bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStyledCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Phone Number',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryTextColor,
                ),
              ),
              const SizedBox(height: 12),
              ResponsiveIntlPhoneField(
                decoration: InputDecoration(
                  labelText: 'Enter your phone number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.dividerColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppColors.primaryColor, width: 2),
                  ),
                ),
                initialCountryCode: 'TZ',
                onChanged: (phone) => _fullPhoneNumber = phone.completeNumber,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildPrimaryButton(
          text: 'Send OTP',
          isLoading: isLoading,
          onPressed: isLoading ? null : _sendOtp,
        ),
      ],
    );
  }

  Widget _buildStyledCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildPrimaryButton({
    required String text,
    required bool isLoading,
    required VoidCallback? onPressed,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: onPressed != null
              ? [
                  AppColors.primaryColor,
                  AppColors.primaryColor.withOpacity(0.8)
                ]
              : [AppColors.disabledTextColor, AppColors.disabledTextColor],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: onPressed != null
            ? [
                BoxShadow(
                  color: AppColors.primaryColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
