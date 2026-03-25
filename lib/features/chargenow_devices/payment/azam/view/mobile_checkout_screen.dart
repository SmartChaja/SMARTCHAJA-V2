import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_chaja/features/chargenow_devices/payment/azam/model/payment_model.dart';
import 'package:smart_chaja/features/chargenow_devices/payment/azam/provider/payment_providers.dart';
import 'package:smart_chaja/features/chargenow_devices/payment/azam/response/payment_result.dart';
import 'package:smart_chaja/features/chargenow_devices/payment/vodacom/provider/vodacom_payment_providers.dart';
import 'package:smart_chaja/features/chargenow_devices/payment/screen/mobile_widgets/dialog_utils.dart';
import 'package:smart_chaja/features/chargenow_devices/payment/screen/mobile_widgets/mobile_number_validator.dart';

class MobileCheckoutScreen extends ConsumerStatefulWidget {
  const MobileCheckoutScreen({super.key});

  @override
  _MobileCheckoutScreenState createState() => _MobileCheckoutScreenState();
}

class _MobileCheckoutScreenState extends ConsumerState<MobileCheckoutScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _mobileNumberController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedProvider = 'Airtel';

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<Map<String, dynamic>> _providers = [
    {
      'name': 'Airtel',
      'color': const Color(0xFFDC2626),
      'icon': Icons.phone_android_rounded
    },
    {
      'name': 'Tigo',
      'color': const Color(0xFF1E40AF),
      'icon': Icons.signal_cellular_alt_rounded
    },
    {
      'name': 'Halopesa',
      'color': const Color(0xFFEA580C),
      'icon': Icons.account_balance_wallet_rounded
    },
    {
      'name': 'Azampesa',
      'color': const Color(0xFF0EA5E9),
      'icon': Icons.payment_rounded
    },
    {
      'name': 'Mpesa',
      'color': const Color(0xFF16A34A),
      'icon': Icons.mobile_friendly_rounded
    },
    {
      'name': 'TTCL',
      'color': const Color(0xFF7C3AED),
      'icon': Icons.router_rounded
    },
    {
      'name': 'Zantel',
      'color': const Color(0xFF92400E),
      'icon': Icons.network_cell_rounded
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _mobileNumberController.dispose();
    _amountController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _submitPayment() {
    if (_formKey.currentState!.validate()) {
      final mobileNumber = _mobileNumberController.text;
      final amount = _amountController.text;

      // Route to appropriate payment provider
      if (_selectedProvider == 'Mpesa') {
        _submitVodacomPayment(mobileNumber, amount);
      } else {
        _submitAzamPayment(mobileNumber, amount);
      }
    }
  }

  /// Handles Vodacom/M-Pesa C2B payment (Tanzania)
  void _submitVodacomPayment(String mobileNumber, String amount) {
    // Normalize the mobile number for Vodacom Tanzania
    String normalizedNumber = mobileNumber;
    if (mobileNumber.length == 10 && mobileNumber.startsWith('0')) {
      normalizedNumber = '255${mobileNumber.substring(1)}';
    } else if (!mobileNumber.startsWith('255') && mobileNumber.length < 12) {
      normalizedNumber = '255$mobileNumber';
    }

    // Generate unique transaction reference (max 20 chars)
    final now = DateTime.now().millisecondsSinceEpoch;
    final random = (1000 + (DateTime.now().microsecond % 9000)).toString();
    // Use last 8 digits of timestamp + 4 random digits, prefix with 'TXN' (max 15 chars)
    final tsPart = now.toString().substring(now.toString().length - 8);
    final transactionRef = 'TXN${tsPart}${random}';
    // If for any reason it's longer than 20, truncate
    final safeTransactionRef = transactionRef.length > 20
        ? transactionRef.substring(0, 20)
        : transactionRef;

    // Use 'mobile wallet payment' for sandbox, 'Mobile Wallet Top-up' for production
    final purchasedItemsDesc = 'mobile wallet payment';

    ref.read(vodacomPaymentViewModelProvider.notifier).performC2BPayment(
          amount: amount,
          customerMsisdn: normalizedNumber,
          serviceProviderCode: '000000', // For sandbox, must be '000000'
          transactionReference: safeTransactionRef,
          purchasedItemsDesc: purchasedItemsDesc,
        );
  }

  /// Handles Azam payment (for Tanzania/other providers)
  void _submitAzamPayment(String mobileNumber, String amount) {
    // Validate the mobile number format
    if (!MobileNumberValidator.validateMobileNumber(
        mobileNumber, _selectedProvider)) {
      showInvalidMobileNumberDialog(context);
      return;
    }

    // Normalize the number before sending to API
    final normalizedNumber = MobileNumberValidator.normalizeForApi(
      mobileNumber,
      _selectedProvider,
    );

    // Debug logs to verify normalization
    debugPrint('Original input: $mobileNumber');
    debugPrint('Normalized for API: $normalizedNumber');
    debugPrint('Provider: $_selectedProvider');

    // Send normalized number to API
    ref.read(paymentViewModelProvider.notifier).performMobileCheckout(
          merchantMobileNumber: normalizedNumber,
          amount: amount,
          currency: 'TZS',
          provider: _selectedProvider,
        );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to Azam payment state
    ref.listen<AsyncValue<PaymentResult?>>(paymentViewModelProvider,
        (previous, next) {
      next.when(
        data: (result) {
          if (result != null) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentResultScreen(
                  isSuccess: result.isSuccess,
                  title: result.isSuccess
                      ? 'Payment Successful'
                      : 'Payment Failed',
                  message: result.isSuccess
                      ? 'Your deposit has been successfully processed.'
                      : result.message,
                  transactionId: result.transactionId,
                  amount: result.amount,
                  provider: result.provider,
                ),
              ),
            );
          }
        },
        loading: () {},
        error: (error, stack) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const PaymentResultScreen(
                isSuccess: false,
                title: 'Payment Failed',
                message: 'An unexpected error occurred. Please try again.',
              ),
            ),
          );
        },
      );
    });

    // Listen to Vodacom payment state
    ref.listen(vodacomPaymentViewModelProvider, (previous, next) {
      next.when(
        data: (result) {
          if (result != null) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentResultScreen(
                  isSuccess: result.isSuccess,
                  title: result.isSuccess
                      ? 'Payment Successful'
                      : 'Payment Failed',
                  message: result.isSuccess
                      ? 'Your deposit has been successfully processed.'
                      : result.message,
                  transactionId: result.transactionId,
                  amount: result.amount,
                  provider: result.provider,
                ),
              ),
            );
          }
        },
        loading: () {},
        error: (error, stack) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const PaymentResultScreen(
                isSuccess: false,
                title: 'Payment Failed',
                message: 'An unexpected error occurred. Please try again.',
              ),
            ),
          );
        },
      );
    });

    final paymentState = ref.watch(paymentViewModelProvider);
    final vodacomState = ref.watch(vodacomPaymentViewModelProvider);

    // Show loading if either payment method is processing
    final isLoading = paymentState.isLoading || vodacomState.isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProviderSelection(),
                        const SizedBox(height: 20),
                        _buildMobileNumberField(),
                        const SizedBox(height: 20),
                        _buildAmountField(),
                        const SizedBox(height: 28),
                        _buildSubmitButton(isLoading),
                        const SizedBox(height: 24),
                        _buildInfoCard(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 160,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF059669),
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF059669), Color(0xFF10B981)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text(
                    'Mobile Money',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Quick and secure mobile payments',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.95),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProviderSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Provider',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedProvider,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              prefixIcon: Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getProviderColor(_selectedProvider).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getProviderIcon(_selectedProvider),
                  color: _getProviderColor(_selectedProvider),
                  size: 20,
                ),
              ),
            ),
            items: _providers.map((provider) {
              return DropdownMenuItem<String>(
                value: provider['name'] as String,
                child: Text(
                  provider['name'] as String,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedProvider = newValue;
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Color _getProviderColor(String providerName) {
    return (_providers.firstWhere((p) => p['name'] == providerName))['color']
        as Color;
  }

  IconData _getProviderIcon(String providerName) {
    return (_providers.firstWhere((p) => p['name'] == providerName))['icon']
        as IconData;
  }

  Widget _buildMobileNumberField() {
    final selectedProviderData =
        _providers.firstWhere((p) => p['name'] == _selectedProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mobile Number',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: _mobileNumberController,
            decoration: InputDecoration(
              border: InputBorder.none,
              prefixIcon: Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: selectedProviderData['color'].withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.phone_rounded,
                  color: selectedProviderData['color'],
                  size: 20,
                ),
              ),
              hintText: 'Enter your mobile number',
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 15,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            ),
            keyboardType: TextInputType.phone,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a mobile number';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Amount',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: _amountController,
            decoration: InputDecoration(
              border: InputBorder.none,
              prefixIcon: Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Color(0xFF059669),
                  size: 20,
                ),
              ),
              hintText: 'Enter amount to deposit',
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 15,
              ),
              suffixText: 'TZS',
              suffixStyle: const TextStyle(
                color: Color(0xFF059669),
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            ),
            keyboardType: TextInputType.number,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter an amount';
              }
              if (double.tryParse(value) == null || double.parse(value) <= 0) {
                return 'Please enter a valid amount';
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            ...[1000, 5000, 10000]
                .map((amount) => Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              _amountController.text = amount.toString();
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color:
                                    const Color(0xFF059669).withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color:
                                      const Color(0xFF059669).withOpacity(0.25),
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                '${amount ~/ 1000}K',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF059669),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ],
        ),
      ],
    );
  }

  Widget _buildSubmitButton(bool isLoading) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: isLoading
          ? Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF059669).withOpacity(0.7),
                    const Color(0xFF10B981).withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
              ),
            )
          : Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF10B981)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF059669).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _submitPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_rounded, size: 18),
                    SizedBox(width: 10),
                    Text(
                      'Proceed with Payment',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.info_rounded,
                  color: Color(0xFF3B82F6),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              const Text(
                'Payment Instructions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildInstructionStep('1', 'Enter your mobile number and amount'),
          _buildInstructionStep(
              '2', 'You\'ll receive a payment prompt on your phone'),
          _buildInstructionStep('3', 'Enter your mobile money PIN to confirm'),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String number, String instruction) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                instruction,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF4B5563),
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
