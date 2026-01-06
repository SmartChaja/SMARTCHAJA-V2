// lib/reusable_widgets/custom_dropdown.dart

import 'package:flutter/material.dart';
import 'dart:math';

/// Simple data holder for each dropdown item.
class DropdownOption {
  final String label;
  final IconData? icon;

  const DropdownOption({required this.label, this.icon});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DropdownOption &&
          runtimeType == other.runtimeType &&
          label == other.label;

  @override
  int get hashCode => label.hashCode;
}

// ─────────────────────────────────────────────────────────────────────────────
//  CONSTANTS – keep the same visual spacing you already love
// ─────────────────────────────────────────────────────────────────────────────
const double _kMaxDropdownHeight = 200.0;
const double _kEstimatedOptionHeight = 48.0;
const double _kDropdownMargin = 4.0;

/// A **beautiful**, **reusable**, **safe** dropdown that looks like a text-field.
class CustomDropdown<T extends DropdownOption> extends StatefulWidget {
  final List<T> options;
  final T? selectedOption;
  final String hintText;
  final void Function(T) onSelected;
  final String? Function(T?)? validator;
  final IconData? prefixIcon;

  const CustomDropdown({
    super.key,
    required this.options,
    required this.selectedOption,
    required this.hintText,
    required this.onSelected,
    this.validator,
    this.prefixIcon,
  });

  @override
  State<CustomDropdown<T>> createState() => _CustomDropdownState<T>();
}

class _CustomDropdownState<T extends DropdownOption>
    extends State<CustomDropdown<T>> {
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  @override
  void dispose() {
    // Remove overlay WITHOUT calling setState during disposal
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isOpen = false; // Update field directly, no setState
    _focusNode.dispose();
    super.dispose();
  }

  // ────────────────────────────────────────────────────────────────────────
  //  PUBLIC API – open / close
  // ────────────────────────────────────────────────────────────────────────
  void _toggleDropdown() {
    if (!mounted) return;
    _isOpen ? _removeOverlay() : _showOverlay();
  }

  // ────────────────────────────────────────────────────────────────────────
  //  SHOW MENU – decides direction, creates overlay, **guards with mounted**
  // ────────────────────────────────────────────────────────────────────────
  void _showOverlay() {
    if (!mounted) return;
    _removeOverlay();

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Size size = renderBox.size;
    final Offset position = renderBox.localToGlobal(Offset.zero);
    final double screenHeight = MediaQuery.of(context).size.height;

    // ---- 1. Estimate menu height ---------------------------------------
    final double estimatedMenuHeight = min(
      widget.options.length * _kEstimatedOptionHeight,
      _kMaxDropdownHeight,
    );

    // ---- 2. Space below the field ---------------------------------------
    final double spaceBelow = screenHeight - position.dy - size.height;

    // ---- 3. Open upwards if there isn't enough room --------------------
    final bool opensUp = spaceBelow < estimatedMenuHeight;

    // ---- 4. Final offset ------------------------------------------------
    final Offset menuOffset = opensUp
        ? Offset(0, -estimatedMenuHeight - _kDropdownMargin)
        : Offset(0, size.height + _kDropdownMargin);

    // ---- 5. Build the overlay -------------------------------------------
    _overlayEntry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          // Close when tapping outside
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggleDropdown,
              child: const ColoredBox(color: Colors.transparent),
            ),
          ),
          // The actual menu
          Positioned(
            width: size.width,
            child: CompositedTransformFollower(
              link: _layerLink,
              offset: menuOffset,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  constraints:
                      const BoxConstraints(maxHeight: _kMaxDropdownHeight),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    children: widget.options.asMap().entries.map((entry) {
                      final int idx = entry.key;
                      final T option = entry.value;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildOption(option),
                          if (idx != widget.options.length - 1)
                            const Divider(height: 1),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    // Insert only if we are still mounted
    if (mounted) {
      Overlay.of(context).insert(_overlayEntry!);
      setState(() => _isOpen = true);
      _focusNode.requestFocus();
    }
  }

  // ────────────────────────────────────────────────────────────────────────
  //  REMOVE MENU – safe cleanup, avoids setState during dispose
  // ────────────────────────────────────────────────────────────────────────
  void _removeOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
    // Only call setState if widget is mounted and not being disposed
    if (mounted) {
      setState(() => _isOpen = false);
    }
  }

  // ────────────────────────────────────────────────────────────────────────
  //  ONE OPTION ROW
  // ────────────────────────────────────────────────────────────────────────
  Widget _buildOption(T option) {
    final bool isSelected = widget.selectedOption == option;

    return InkWell(
      onTap: () {
        if (!mounted) return;
        widget.onSelected(option);
        _toggleDropdown();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        color: isSelected
            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
            : null,
        child: Row(
          children: [
            if (option.icon != null) ...[
              Icon(
                option.icon,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[700],
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                option.label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color:
                      isSelected ? Theme.of(context).colorScheme.primary : null,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check,
                  color: Theme.of(context).colorScheme.primary, size: 20),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────
  //  BUILD – the "text-field" that opens the menu
  // ────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggleDropdown,
        child: AbsorbPointer(
          child: TextFormField(
            focusNode: _focusNode,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.transparent,
              hintText: widget.hintText,
              hintStyle: TextStyle(color: Colors.grey[600]),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              prefixIcon: widget.prefixIcon != null
                  ? Icon(widget.prefixIcon,
                      color: Theme.of(context).primaryColor)
                  : null,
              suffixIcon: Icon(
                _isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade400),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade400),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
            ),
            controller: TextEditingController(
              text: widget.selectedOption?.label ?? '',
            )..selection = const TextSelection.collapsed(offset: 0),
            readOnly: true,
            validator: (_) => widget.validator?.call(widget.selectedOption),
          ),
        ),
      ),
    );
  }
}