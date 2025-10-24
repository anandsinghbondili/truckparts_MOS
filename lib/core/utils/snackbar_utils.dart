import 'package:flutter/material.dart';

class SnackBarUtils {
  /// Shows a SnackBar immediately, removing any existing SnackBar first
  static void showImmediate(
    BuildContext context, {
    required String message,
    Color? backgroundColor,
    Color? textColor,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    // Remove any existing SnackBar first
    ScaffoldMessenger.of(context).clearSnackBars();

    // Show the new SnackBar immediately
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: textColor ?? Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: backgroundColor ?? Colors.black87,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action: action,
      ),
    );
  }

  /// Shows a success message immediately
  static void showSuccess(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    showImmediate(
      context,
      message: message,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      duration: duration,
      action: action,
    );
  }

  /// Shows an error message immediately
  static void showError(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    showImmediate(
      context,
      message: message,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      duration: duration,
      action: action,
    );
  }

  /// Shows an info message immediately
  static void showInfo(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    showImmediate(
      context,
      message: message,
      backgroundColor: Colors.blue,
      textColor: Colors.white,
      duration: duration,
      action: action,
    );
  }

  /// Shows a warning message immediately
  static void showWarning(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    showImmediate(
      context,
      message: message,
      backgroundColor: Colors.orange,
      textColor: Colors.white,
      duration: duration,
      action: action,
    );
  }
}
