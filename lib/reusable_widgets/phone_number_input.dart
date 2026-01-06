import 'package:intl_phone_field/country_picker_dialog.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:flutter/material.dart';

class ResponsiveIntlPhoneField extends StatefulWidget {
  final InputDecoration decoration;
  final String initialCountryCode;
  final Function(PhoneNumber) onChanged;
  final String? Function(PhoneNumber?)? validator;
  final TextStyle? style;

  const ResponsiveIntlPhoneField({
    super.key,
    required this.decoration,
    required this.initialCountryCode,
    required this.onChanged,
    this.validator,
    this.style,
  });

  @override
  State<ResponsiveIntlPhoneField> createState() =>
      _ResponsiveIntlPhoneFieldState();
}

class _ResponsiveIntlPhoneFieldState extends State<ResponsiveIntlPhoneField> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600; // Adjust breakpoint as needed

    return IntlPhoneField(
      decoration: widget.decoration,
      initialCountryCode: widget.initialCountryCode,
      onChanged: widget.onChanged,
      validator: widget.validator,
      style: widget.style,
      dropdownDecoration: BoxDecoration(
        // Customize the dropdown's appearance here
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      pickerDialogStyle: PickerDialogStyle(
        searchFieldInputDecoration: InputDecoration(
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[800]
              : Colors.grey[100],
          hintText: 'Search Country',
          hintStyle: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[400]
                : Colors.grey[600],
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Theme.of(context).primaryColor,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).primaryColor,
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Colors.red,
              width: 1.5,
            ),
          ),
          helperText: 'Search your country',
          helperStyle: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[400]
                : Colors.grey[600],
          ),
        ),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.grey[100],
        countryCodeStyle: TextStyle(
            fontSize: isSmallScreen ? 12 : 16, color: widget.style?.color),
        // Make the picker dialog smaller
        padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 8 : 16,
            vertical: isSmallScreen ? 8 : 16),
        searchFieldPadding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 8 : 16,
            vertical: isSmallScreen ? 8 : 16),
      ),
    );
  }
}
