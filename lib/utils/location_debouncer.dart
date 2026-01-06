import 'dart:async';
import 'package:flutter/material.dart';

class LocationDebouncer {
  static Timer? _debounceTimer;
  static const Duration debounceDelay = Duration(seconds: 1);

  static void debounce(VoidCallback callback) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounceDelay, callback);
  }

  static void dispose() {
    _debounceTimer?.cancel();
  }
}