import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinput/pinput.dart';
import 'package:smart_chaja/app_constants/app_constants.dart';
import 'package:smart_chaja/authentication/register/repositories/auth_repository.dart';
import 'package:smart_chaja/authentication/register/viewmodels/auth_viewmodel.dart';
import 'package:smart_chaja/reusable_widgets/snack_bar.dart';

class VerifyOtpScreen extends ConsumerStatefulWidget {
  final String phoneNumber;

  const VerifyOtpScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  ConsumerState<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends ConsumerState<VerifyOtpScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _pinController = TextEditingController();
  final _focusNode = FocusNode();
  int _resendCountdown = 60;
  Timer? _resendTimer;
  bool _canResend = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
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
    _pinController.dispose();
    _focusNode.dispose();
    _resendTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    _resendCountdown = 60;
    _canResend = false;

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown == 0) {
        timer.cancel();
        setState(() => _canResend = true);
      } else {
        setState(() => _resendCountdown--);
      }
    });
  }

  void _resendOtp() async {
    final authViewModel = ref.read(authViewModelProvider.notifier);

    try {
      final success = await authViewModel.sendOTP(widget.phoneNumber);

      if (!mounted) return;

      if (success) {
        setState(() {
          _startResendTimer();
          _pinController.clear();
        });
        TopSnackBar.show(context, 'OTP resent successfully!',
            color: Colors.blue);
      }
    } catch (e) {
      debugPrint('❌ Resend OTP failed: $e');
    }
  }

  void _navigateBasedOnProfile() async {
    final authRepository = ref.read(authRepositoryProvider);
    final currentUser = authRepository.currentUser;

    if (currentUser == null) {
      TopSnackBar.show(context, 'Authentication failed', color: Colors.red);
      return;
    }

    try {
      debugPrint('🔍 Checking if profile exists for user: ${currentUser.uid}');
      final profileExists =
          await authRepository.userProfileExists(currentUser.uid);
      
      debugPrint('✅ Profile exists result: $profileExists');

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
    }
  }

  void _verifyOtpAndLogin() async {
    if (!_formKey.currentState!.validate()) return;

    debugPrint('🔐 Starting OTP verification...');
    final authViewModel = ref.read(authViewModelProvider.notifier);

    try {
      final bool profileExists =
          await authViewModel.verifyOTP(_pinController.text);

      debugPrint('📝 VerifyOTP returned: $profileExists');

      if (ref.read(authViewModelProvider).error != null) {
        debugPrint('❌ Error in auth state: ${ref.read(authViewModelProvider).error}');
        return; // Error will be shown via listener
      }

      if (!mounted) return;

      if (profileExists) {
        debugPrint('✅ Profile exists - navigating to map');
        TopSnackBar.show(context, 'Login successful!', color: Colors.green);
        Navigator.pushReplacementNamed(context, '/map');
      } else {
        debugPrint('⚠️ Profile does not exist - navigating to register');
        TopSnackBar.show(context, 'Please complete your profile',
            color: Colors.blue);
        Navigator.pushReplacementNamed(context, '/register');
      }
    } catch (e) {
      debugPrint('❌ OTP verification failed: $e');
      TopSnackBar.show(context, 'Verification failed. Please try again.',
          color: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authViewModelProvider, (previous, next) {
      if (next.error != null) {
        TopSnackBar.show(context, next.error!, color: Colors.red);
        ref.read(authViewModelProvider.notifier).clearError();
      }
    });

    final isLoading =
        ref.watch(authViewModelProvider.select((state) => state.isLoading));

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
                    child: _buildOtpInput(isLoading),
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
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        children: [
          const Text(
            'Verify OTP',
            style: TextStyle(
              color: AppColors.primaryTextColor,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Enter the 6-digit code sent to ${widget.phoneNumber}',
            style: const TextStyle(
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

  Widget _buildOtpInput(bool isLoading) {
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: const TextStyle(
        fontSize: 22,
        color: AppColors.primaryTextColor,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dividerColor),
      ),
    );

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStyledCard(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.sms_outlined,
                          color: AppColors.primaryColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SMS sent to',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.secondaryTextColor),
                            ),
                            Text(
                              widget.phoneNumber,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Pinput(
                    controller: _pinController,
                    focusNode: _focusNode,
                    length: 6,
                    defaultPinTheme: defaultPinTheme,
                    separatorBuilder: (index) => const SizedBox(width: 8),
                    validator: (value) =>
                        value!.length != 6 ? 'Enter a 6-digit OTP' : null,
                    hapticFeedbackType: HapticFeedbackType.lightImpact,
                    onCompleted: (pin) => _verifyOtpAndLogin(),
                    cursor: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(bottom: 9),
                          width: 22,
                          height: 1,
                          color: AppColors.primaryColor,
                        ),
                      ],
                    ),
                    focusedPinTheme: defaultPinTheme.copyWith(
                      decoration: defaultPinTheme.decoration!.copyWith(
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: AppColors.primaryColor, width: 2),
                      ),
                    ),
                    submittedPinTheme: defaultPinTheme.copyWith(
                      decoration: defaultPinTheme.decoration!.copyWith(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primaryColor),
                      ),
                    ),
                    errorPinTheme: defaultPinTheme.copyBorderWith(
                      border: Border.all(color: Colors.redAccent),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        color: Colors.orange,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'OTP is valid for 10 minutes',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _canResend
              ? TextButton(
                  onPressed: isLoading ? null : _resendOtp,
                  child: const Text(
                    'Resend OTP',
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                )
              : Text(
                  'Resend OTP in $_resendCountdown seconds',
                  style: const TextStyle(
                    color: AppColors.secondaryTextColor,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
          const SizedBox(height: 24),
          _buildPrimaryButton(
            text: 'Verify & Continue',
            isLoading: isLoading,
            onPressed: isLoading ? null : _verifyOtpAndLogin,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Change Phone Number',
              style: TextStyle(
                color: AppColors.secondaryTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
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