import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_chaja/features/chargenow_devices/payment/azam/model/payment_model.dart';
import 'package:smart_chaja/features/chargenow_devices/payment/azam/provider/payment_providers.dart';
import 'package:smart_chaja/features/chargenow_devices/payment/azam/response/payment_result.dart';

class BankCheckoutScreen extends ConsumerStatefulWidget {
  const BankCheckoutScreen({super.key});

  @override
  _BankCheckoutScreenState createState() => _BankCheckoutScreenState();
}

class _BankCheckoutScreenState extends ConsumerState<BankCheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _accountNumberController = TextEditingController();
  final _mobileNumberController = TextEditingController();
  final _merchantNameController = TextEditingController();
  final _amountController = TextEditingController();
  final _otpController = TextEditingController();
  String _selectedProvider = 'CRDB';
  final List<String> _providers = [
    'CRDB',
    'NMB',
    'NBC',
    'Stanbic',
    'Standard Chartered',
  ];

  // Bank colors for visual appeal
  final Map<String, Color> _bankColors = {
    'CRDB': const Color(0xFF00A651),
    'NMB': const Color(0xFF004B87),
    'NBC': const Color(0xFF1E3A8A),
    'Stanbic': const Color(0xFF004B87),
    'Standard Chartered': const Color(0xFF0052A3),
  };

  @override
  void dispose() {
    _accountNumberController.dispose();
    _mobileNumberController.dispose();
    _merchantNameController.dispose();
    _amountController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _submitPayment() {
    if (_formKey.currentState!.validate()) {
      ref.read(paymentViewModelProvider.notifier).performBankCheckout(
            merchantAccountNumber: _accountNumberController.text,
            merchantMobileNumber: _mobileNumberController.text,
            merchantName: _merchantNameController.text.isNotEmpty
                ? _merchantNameController.text
                : null,
            amount: _amountController.text,
            currency: 'TZS',
            provider: _selectedProvider,
            otp: _otpController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  transactionId: result.referenceId,
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

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Bank Checkout',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[50],
      body: Center(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Form Section
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bank Selection
                      const Text(
                        'Select Bank',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _selectedProvider,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            prefixIcon:
                                Icon(Icons.business, color: Colors.grey),
                          ),
                          items: _providers.map((provider) {
                            return DropdownMenuItem(
                              value: provider,
                              child: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color:
                                          _bankColors[provider] ?? Colors.grey,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(provider),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedProvider = value!;
                            });
                          },
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Account Number Field
                      _buildInputField(
                        label: 'Account Number',
                        controller: _accountNumberController,
                        icon: Icons.account_balance_wallet,
                        hintText: 'Enter your account number',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an account number';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Mobile Number Field
                      _buildInputField(
                        label: 'Mobile Number',
                        controller: _mobileNumberController,
                        icon: Icons.phone,
                        hintText: 'Enter mobile number',
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a mobile number';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Merchant Name Field
                      _buildInputField(
                        label: 'Merchant Name (Optional)',
                        controller: _merchantNameController,
                        icon: Icons.person,
                        hintText: 'Enter merchant name',
                        isRequired: false,
                      ),

                      const SizedBox(height: 20),

                      // Amount Field
                      _buildInputField(
                        label: 'Amount',
                        controller: _amountController,
                        icon: Icons.money,
                        hintText: 'Enter amount',
                        keyboardType: TextInputType.number,
                        suffixText: 'TZS',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an amount';
                          }
                          if (double.tryParse(value) == null ||
                              double.parse(value) <= 0) {
                            return 'Please enter a valid amount';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // OTP Field
                      _buildInputField(
                        label: 'OTP',
                        controller: _otpController,
                        icon: Icons.security,
                        hintText: 'Enter OTP code',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an OTP';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 40),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: paymentState.isLoading
                            ? Container(
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF059669).withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                ),
                              )
                            : ElevatedButton(
                                onPressed: _submitPayment,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF059669),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                                child: const Text(
                                  'Deposit Now',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                      ),

                      const SizedBox(height: 24),

                      // Info Cards
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.amber[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: Colors.amber[700], size: 20),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Make sure to enter the correct OTP received from your bank.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hintText,
    TextInputType? keyboardType,
    String? suffixText,
    String? Function(String?)? validator,
    bool isRequired = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              border: InputBorder.none,
              prefixIcon: Icon(icon, color: Colors.grey),
              hintText: hintText,
              suffixText: suffixText,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }
}
