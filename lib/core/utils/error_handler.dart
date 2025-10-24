import 'package:flutter/material.dart';
import '../widgets/error_dialog.dart';
import 'error_message_mapper.dart';

/// Centralized error handler for showing user-friendly error dialogs
class ErrorHandler {
  /// Handle and display error with user-friendly dialog
  static Future<void> handleError({
    required BuildContext context,
    required dynamic error,
    String? customTitle,
    String? customMessage,
    String? actionButtonText,
    VoidCallback? onActionPressed,
    bool logError = true,
  }) async {
    // Log error for debugging (console only, not shown to user)
    if (logError) {
      debugPrint('❌ Error occurred: $error');
      if (error is Error) {
        debugPrint('Stack trace: ${error.stackTrace}');
      }
    }

    // Get user-friendly messages
    final title = customTitle ?? ErrorMessageMapper.getErrorTitle(error);
    final message =
        customMessage ?? ErrorMessageMapper.getUserFriendlyMessage(error);

    // Show error dialog
    await ErrorDialog.show(
      context: context,
      title: title,
      message: message,
      actionButtonText: actionButtonText,
      onActionPressed: onActionPressed,
    );
  }

  /// Quick method for API errors with retry action
  static Future<void> handleApiError({
    required BuildContext context,
    required dynamic error,
    required VoidCallback onRetry,
  }) async {
    await handleError(
      context: context,
      error: error,
      actionButtonText: 'Retry',
      onActionPressed: onRetry,
    );
  }

  /// Quick method for network errors
  static Future<void> handleNetworkError({
    required BuildContext context,
    required VoidCallback onRetry,
  }) async {
    await ErrorDialog.show(
      context: context,
      title: 'Connection Error',
      message:
          'Unable to connect to the server. Please check your internet connection and try again.',
      actionButtonText: 'Retry',
      onActionPressed: onRetry,
    );
  }

  /// Quick method for session expired errors
  static Future<void> handleSessionExpired({
    required BuildContext context,
    required VoidCallback onLogin,
  }) async {
    await ErrorDialog.show(
      context: context,
      title: 'Session Expired',
      message: 'Your session has expired. Please login again to continue.',
      actionButtonText: 'Login',
      onActionPressed: onLogin,
    );
  }
}
