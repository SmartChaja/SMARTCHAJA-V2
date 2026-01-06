import 'dart:ui';
import 'package:flutter/material.dart';

Widget buildStatusOverlay({
  required String message,
  IconData? icon,
  bool isLoading = false,
  bool isError = false,
}) {
  return Positioned(
    left: 0,
    right: 0,
    top: 120,
    child: Center(
      child: AnimatedOpacity(
        opacity: 1.0,
        duration: const Duration(milliseconds: 300),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            margin: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.black87),
                  ),
                if (icon != null && !isLoading)
                  Icon(
                    icon,
                    size: 32,
                    color: isError ? Colors.red : Colors.grey[600],
                  ),
                const SizedBox(width: 12), // corrected from height
                Flexible(
                  child: Text(
                    message,
                    style: TextStyle(
                      color: isError ? Colors.red : Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    softWrap: true,
                    overflow: TextOverflow.visible, // allow wrap
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











