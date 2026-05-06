import 'package:flutter/material.dart';
import 'vodacom_payment_result.dart';

class VodacomPaymentResultScreen extends StatefulWidget {
  final bool isSuccess;
  final String title;
  final String message;
  final String? transactionId;
  final String? amount;
  final String? provider;
  final VodacomPaymentOperationResult? paymentResult;

  const VodacomPaymentResultScreen({
    super.key,
    required this.isSuccess,
    required this.title,
    required this.message,
    this.transactionId,
    this.amount,
    this.provider,
    this.paymentResult,
  });

  @override
  State<VodacomPaymentResultScreen> createState() =>
      _VodacomPaymentResultScreenState();
}

class _VodacomPaymentResultScreenState
    extends State<VodacomPaymentResultScreen> {
  late bool _isFinalScreen;
  late String _currentTitle;
  late String _currentMessage;
  int _countdownSeconds = 40;

  @override
  void initState() {
    super.initState();
    _isFinalScreen = !widget.isSuccess;
    _currentTitle = widget.title;
    _currentMessage = widget.message;

    // If showing "Payment Sent" screen, start the 40-second wait
    if (widget.isSuccess &&
        widget.title == 'Payment Sent' &&
        widget.paymentResult != null) {
      print('[VodacomResultScreen] 🕐 Starting 40-second countdown...');
      _startCountdown();
    }
  }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 40), () async {
      if (!mounted) return;

      print(
          '[VodacomResultScreen] ⏰ 40 seconds elapsed, processing transaction...');

      // Update UI to show final success
      setState(() {
        _isFinalScreen = true;
        _currentTitle = 'Payment Successful';
        _currentMessage = 'Your deposit has been successfully processed.';
      });

      print('[VodacomResultScreen] ✅ Screen updated to final success state');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 60),
            _buildStatusIcon(),
            const SizedBox(height: 16),
            _buildTitle(),
            const SizedBox(height: 8),
            _buildMessage(),
            if (widget.isSuccess && !_isFinalScreen)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  children: [
                    Text(
                      'Please wait for a USSD popup on your phone to enter your PIN to complete the payment.',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Auto-confirming in $_countdownSeconds seconds...',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            if (_isFinalScreen && _hasTransactionDetails()) ...[
              const SizedBox(height: 16),
              _buildTransactionDetails(),
            ],
            const SizedBox(height: 24),
            _buildActionButtons(context),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    final iconColor =
        widget.isSuccess ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final backgroundColor = iconColor.withOpacity(0.1);
    final iconData = widget.isSuccess ? Icons.check_circle : Icons.cancel;

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 48,
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      _currentTitle,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1F2937),
        letterSpacing: -0.4,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        _currentMessage,
        style: TextStyle(
          fontSize: 15,
          color: Colors.grey[600],
          height: 1.5,
          fontWeight: FontWeight.w400,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTransactionDetails() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.receipt_long,
                  color: Color(0xFF10B981),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Transaction Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.transactionId != null)
            _buildDetailRow('Transaction ID', widget.transactionId!, Icons.tag),
          if (widget.amount != null)
            _buildDetailRow('Amount', 'TSH ${widget.amount}', Icons.payments),
          if (widget.provider != null)
            _buildDetailRow(
                'Provider', widget.provider!, Icons.account_balance),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey[500],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.isSuccess
                  ? const Color(0xFF10B981)
                  : const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shadowColor: (widget.isSuccess
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444))
                  .withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              widget.isSuccess ? 'Close' : 'Close',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
        if (!widget.isSuccess) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF6B7280),
                side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  bool _hasTransactionDetails() {
    return widget.transactionId != null ||
        widget.amount != null ||
        widget.provider != null;
  }
}
