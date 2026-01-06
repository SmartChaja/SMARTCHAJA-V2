import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lottie/lottie.dart';
import 'package:smart_chaja/app_constants/app_constants.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  AnimationController? _lottieController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _lottieController = AnimationController(vsync: this);
    _lottieController!.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        _lottieController!.repeat();
      }
    });

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _lottieController?.dispose();
    super.dispose();
  }

  void _onAgreeAndContinue(BuildContext context) {
    Navigator.of(context).pushReplacementNamed('/send-otp');
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: try to launch anyway as some devices may not properly report canLaunchUrl
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch URL: $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Scrollable content area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top spacing for better visual hierarchy
                        const SizedBox(height: 30),
                        // Logo above title - centered layout with logo prominence
                        Center(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Lottie logo from splash screen (static, green, smaller)
                              _lottieController != null
                                  ? ColorFiltered(
                                      colorFilter: ColorFilter.mode(
                                        AppColors.primaryColor,
                                        BlendMode.srcIn,
                                      ),
                                      child: Lottie.asset(
                                        'assets/lottie/power.json',
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.contain,
                                        repeat: false,
                                        frameRate: FrameRate.max,
                                      ),
                                    )
                                  : const SizedBox(
                                      width: 100,
                                      height: 100,
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                              const SizedBox(height: 16),
                              // Title below logo (centered)
                              const Text(
                                'Welcome to\nSmartChaja',
                                style: TextStyle(
                                  color: AppColors.primaryTextColor,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                  letterSpacing: -0.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                        // Service Description
                        Text(
                          'A simple, secure, and convenient way to rent power banks whenever your phone battery runs low. Find nearby SmartChaja stations, rent instantly, and stay connected wherever you go.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                            color: AppColors.primaryTextColor,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 36),
                        // Privacy Policy Information - improved presentation
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                              color: AppColors.primaryTextColor,
                              height: 1.6,
                            ),
                            children: [
                              const TextSpan(
                                text:
                                    'To improve your experience, SmartChaja may collect limited usage information in accordance with our ',
                              ),
                              WidgetSpan(
                                child: GestureDetector(
                                  onTap: () =>
                                      _launchURL('https://www.tewl.co.tz/terms-conditions/'),
                                  child: Text(
                                    'Privacy Policy',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: AppColors.primaryColor,
                                      decoration: TextDecoration.underline,
                                      decorationThickness: 1.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              const TextSpan(
                                text: '. ',
                              ),
                              WidgetSpan(
                                child: GestureDetector(
                                  onTap: () =>
                                      _launchURL('https://www.tewl.co.tz/app/'),
                                  child: Text(
                                    'Learn more',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: AppColors.primaryColor,
                                      decoration: TextDecoration.underline,
                                      decorationThickness: 1.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              const TextSpan(
                                text: '.',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 36),
                        // Terms of Service Acceptance - improved presentation
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                              color: AppColors.primaryTextColor,
                              height: 1.6,
                            ),
                            children: [
                              const TextSpan(
                                text:
                                    'Tap "Agree & Continue" to accept the SmartChaja ',
                              ),
                              WidgetSpan(
                                child: GestureDetector(
                                  onTap: () => _launchURL(
                                      'https://www.tewl.co.tz/terms-conditions/'),
                                  child: Text(
                                    'Terms of Service',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: AppColors.primaryColor,
                                      decoration: TextDecoration.underline,
                                      decorationThickness: 1.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              const TextSpan(
                                text: '.',
                              ),
                            ],
                          ),
                        ),
                        // Bottom spacing before button - reduced from 40px to 32px
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Sticky button at bottom
            Container(
              padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 24.0),
              decoration: BoxDecoration(
                color: AppColors.backgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: _buildAgreeButton(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgreeButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor,
            AppColors.primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () => _onAgreeAndContinue(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'Agree & Continue',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}
