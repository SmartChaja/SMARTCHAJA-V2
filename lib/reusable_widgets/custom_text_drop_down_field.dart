// file: enhanced_custom_dropdown.dart (or wherever it's defined)

import 'package:flutter/material.dart';

class EnhancedCustomDropdown extends StatefulWidget {
  final String? label;
  final String? value;
  final List<String> items;
  final void Function(String?) onChanged;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;
  final String? helperText;
  final String? hintText;
  final InputDecoration? decoration;
  final bool enabled; // <-- ADD THIS PROPERTY

  const EnhancedCustomDropdown({
    super.key,
    this.label,
    this.value,
    required this.items,
    required this.onChanged,
    this.validator,
    this.prefixIcon,
    this.helperText,
    this.hintText,
    this.decoration,
    this.enabled = true, // <-- ADD DEFAULT VALUE
  });

  @override
  State<EnhancedCustomDropdown> createState() => _EnhancedCustomDropdownState();
}

class _EnhancedCustomDropdownState extends State<EnhancedCustomDropdown> {
  bool _isFocused = false;
  String? _errorText;

  @override
  Widget build(BuildContext context) {
    // Determine colors based on enabled state
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color disabledColor = Colors.grey[400]!;
    final Color currentPrimaryColor = widget.enabled ? primaryColor : disabledColor;
    final Color currentIconColor = widget.enabled ? (_isFocused ? primaryColor : Colors.grey[600]!) : disabledColor;
    final Color currentTextColor = widget.enabled ? Colors.black87 : Colors.grey[700]!;
    final Color currentHintColor = widget.enabled ? Colors.grey[500]! : Colors.grey[400]!;
    final Color currentBackgroundColor = widget.enabled ? Colors.grey[100]! : Colors.grey[200]!;


    return AbsorbPointer( // <-- WRAP WITH AbsorbPointer
      absorbing: !widget.enabled, // Absorb touch events if not enabled
      child: Opacity( // <-- WRAP WITH Opacity for visual feedback
        opacity: widget.enabled ? 1.0 : 0.6, // Make it look disabled
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.label != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    widget.label!,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: widget.enabled ? Theme.of(context).primaryColorDark : disabledColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: currentBackgroundColor, // Use dynamic background color
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: widget.enabled ? [ // Only show shadow if enabled
                    BoxShadow(
                      color: _isFocused
                          ? currentPrimaryColor.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.1),
                      blurRadius: _isFocused ? 12 : 8,
                      offset: const Offset(0, 4),
                    ),
                  ] : [],
                  border: Border.all(
                    color: _errorText != null && widget.enabled // Check enabled for error border
                        ? Colors.red.withOpacity(0.8)
                        : _isFocused && widget.enabled // Check enabled for focus border
                            ? currentPrimaryColor
                            : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Focus(
                  onFocusChange: (hasFocus) {
                    if (widget.enabled) { // Only handle focus if enabled
                      setState(() {
                        _isFocused = hasFocus;
                        if (!hasFocus) {
                          _errorText = widget.validator?.call(widget.value);
                        }
                      });
                    }
                  },
                  child: DropdownButtonFormField<String>(
                    value: widget.value,
                    items: widget.items
                        .map((item) => DropdownMenuItem(
                              value: item,
                              child: Text(
                                item,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: currentTextColor, // Use dynamic text color
                                ),
                              ),
                            ))
                        .toList(),
                    onChanged: widget.enabled ? (value) { // Pass null if not enabled
                      widget.onChanged(value);
                      setState(() {
                        _errorText = widget.validator?.call(value);
                      });
                    } : null,
                    validator: widget.enabled ? widget.validator : null, // Disable validator if not enabled
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: currentTextColor,
                    ),
                    decoration: widget.decoration ?? InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 18,
                        horizontal: 20,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      prefixIcon: widget.prefixIcon != null
                          ? Icon(
                              widget.prefixIcon,
                              color: currentIconColor, // Use dynamic icon color
                              size: 22,
                            )
                          : null,
                      hintText: widget.hintText,
                      hintStyle: TextStyle(
                        color: currentHintColor, // Use dynamic hint color
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    dropdownColor: currentBackgroundColor,
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: currentIconColor,
                      size: 24,
                    ),
                  ),
                ),
              ),
              if (_errorText != null && widget.enabled)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 12),
                  child: Text(
                    _errorText!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              if (widget.helperText != null && _errorText == null && widget.enabled)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 12),
                  child: Text(
                    widget.helperText!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}