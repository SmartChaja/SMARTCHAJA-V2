import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';

class CustomPhoneField extends StatefulWidget {
  final String? label;
  final String? hintText;
  final String? helperText;
  final String? initialCountryCode;
  final Function(String?)? validator;
  final Function(PhoneNumber)? onChanged;

  const CustomPhoneField({
    Key? key,
    this.label,
    this.hintText,
    this.helperText,
    this.initialCountryCode,
    this.validator,
    this.onChanged,
  }) : super(key: key);

  @override
  _CustomPhoneFieldState createState() => _CustomPhoneFieldState();
}

class _CustomPhoneFieldState extends State<CustomPhoneField> {
  bool _isFocused = false;
  String? _errorText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.label != null)
            Text(
              widget.label!,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          const SizedBox(height: 8),
          Focus(
            onFocusChange: (hasFocus) {
              setState(() {
                _isFocused = hasFocus;
                if (!hasFocus) {
                  _errorText = widget.validator?.call(null); // Validation logic
                }
              });
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _errorText != null
                      ? Colors.red
                      : _isFocused
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade300,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _isFocused
                        ? Theme.of(context).primaryColor.withOpacity(0.1)
                        : Colors.transparent,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IntlPhoneField(
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.phone, color: Colors.grey.shade600),
                  hintText: widget.hintText,
                  hintStyle: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                initialCountryCode: widget.initialCountryCode ?? 'KE',
                onChanged: (phone) {
                  setState(() {
                    widget.onChanged?.call(phone);
                    _errorText = widget.validator?.call(phone.completeNumber);
                  });
                },
                validator: (phone) {
                  if (phone == null || phone.completeNumber.isEmpty) {
                    return 'Please enter a phone number';
                  }
                  return null;
                },
              ),
            ),
          ),
          if (_errorText != null)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 12),
              child: Text(
                _errorText!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red,
                ),
              ),
            ),
          if (widget.helperText != null && _errorText == null)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 12),
              child: Text(
                widget.helperText!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
