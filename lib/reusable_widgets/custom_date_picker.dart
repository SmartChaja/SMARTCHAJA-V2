import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_chaja/reusable_widgets/custom_text_field.dart';


class CustomDatePicker extends StatefulWidget {
  final String label;
  final DateTime? initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final Function(DateTime?) onDateSelected;
  final String? Function(DateTime?)? validator;
  final bool enabled;

  const CustomDatePicker({
    super.key,
    required this.label,
    this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.onDateSelected,
    this.validator,
    this.enabled = true,
  });

  @override
  State<CustomDatePicker> createState() => _CustomDatePickerState();
}

class _CustomDatePickerState extends State<CustomDatePicker> {
  DateTime? _selectedDate;
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    if (_selectedDate != null) {
      _controller.text = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: widget.firstDate,
      lastDate: widget.lastDate,
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _controller.text = DateFormat('yyyy-MM-dd').format(picked);
      });
      widget.onDateSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return EnhancedCustomTextField(
      controller: _controller,
      label: widget.label,
      prefixIcon: Icons.calendar_today,
      readOnly: true,
      enabled: widget.enabled,
      onTap: widget.enabled ? _selectDate : null,
      validator: (_) => widget.validator?.call(_selectedDate),
      hintText: 'Select a date',
    );
  }
}