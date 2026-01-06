import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EnhancedCustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String? label;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;
  final String? helperText;
  final String? hintText;
  final int? maxLines;
  final void Function(String)? onChanged;
  final List<TextInputFormatter>? inputFormatters;
  final bool readOnly;
  final VoidCallback? onTap;
  final InputDecoration? decoration;
  final String? errorText;
  final bool enabled; // Added enabled parameter

  const EnhancedCustomTextField({
    super.key,
    required this.controller,
    this.label,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.prefixIcon,
    this.helperText,
    this.hintText,
    this.maxLines,
    this.onChanged,
    this.inputFormatters,
    this.readOnly = false,
    this.onTap,
    this.decoration,
    this.errorText,
    this.enabled = true, // Default to true
  });

  @override
  State<EnhancedCustomTextField> createState() => _EnhancedCustomTextFieldState();
}

class _EnhancedCustomTextFieldState extends State<EnhancedCustomTextField> {
  bool _isFocused = false;
  late bool _obscureText;
  String? _internalErrorText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final displayErrorText = widget.errorText ?? _internalErrorText;

    return Padding(
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
                  color: Theme.of(context).primaryColorDark,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: widget.enabled ? Colors.grey[100] : Colors.grey[200], // Slightly different color when disabled
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _isFocused
                      ? Theme.of(context).primaryColor.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.1),
                  blurRadius: _isFocused ? 12 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: displayErrorText != null
                    ? Colors.red.withOpacity(0.8)
                    : _isFocused
                        ? Theme.of(context).primaryColor
                        : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Focus(
              onFocusChange: (hasFocus) {
                setState(() {
                  _isFocused = hasFocus;
                  if (!hasFocus && widget.errorText == null) {
                    _internalErrorText = widget.validator?.call(widget.controller.text);
                  }
                });
              },
              child: TextFormField(
                controller: widget.controller,
                obscureText: _obscureText,
                keyboardType: widget.keyboardType,
                maxLines: _obscureText ? 1 : widget.maxLines,
                inputFormatters: widget.inputFormatters,
                readOnly: widget.readOnly,
                onTap: widget.onTap,
                enabled: widget.enabled, // Pass enabled to TextFormField
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: widget.enabled ? Colors.black87 : Colors.grey[600], // Adjust text color when disabled
                ),
                decoration: widget.decoration?.copyWith(
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
                              color: _isFocused && widget.enabled
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey[600],
                              size: 22,
                            )
                          : null,
                      suffixIcon: widget.obscureText
                          ? IconButton(
                              icon: Icon(
                                _obscureText
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: _isFocused && widget.enabled
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey[600],
                                size: 22,
                              ),
                              onPressed: widget.enabled
                                  ? () {
                                      setState(() {
                                        _obscureText = !_obscureText;
                                      });
                                    }
                                  : null, // Disable suffix icon when not enabled
                            )
                          : null,
                      hintText: widget.hintText,
                      hintStyle: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.italic,
                      ),
                    ) ??
                    InputDecoration(
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
                              color: _isFocused && widget.enabled
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey[600],
                              size: 22,
                            )
                          : null,
                      suffixIcon: widget.obscureText
                          ? IconButton(
                              icon: Icon(
                                _obscureText
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: _isFocused && widget.enabled
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey[600],
                                size: 22,
                              ),
                              onPressed: widget.enabled
                                  ? () {
                                      setState(() {
                                        _obscureText = !_obscureText;
                                      });
                                    }
                                  : null, // Disable suffix icon when not enabled
                            )
                          : null,
                      hintText: widget.hintText,
                      hintStyle: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                onChanged: (value) {
                  if (widget.errorText == null) {
                    setState(() {
                      _internalErrorText = widget.validator?.call(value);
                    });
                  }
                  widget.onChanged?.call(value);
                },
              ),
            ),
          ),
          if (displayErrorText != null)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 12),
              child: Text(
                displayErrorText,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          if (widget.helperText != null && displayErrorText == null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 12),
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
    );
  }
}