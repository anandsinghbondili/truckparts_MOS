/// Maps technical error messages to user-friendly messages
class ErrorMessageMapper {
  /// Convert technical error to user-friendly message
  static String getUserFriendlyMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Network errors
    if (errorString.contains('socket') ||
        errorString.contains('network') ||
        errorString.contains('connection')) {
      return 'Unable to connect to the server. Please check your internet connection and try again.';
    }

    // Timeout errors
    if (errorString.contains('timeout') || errorString.contains('timed out')) {
      return 'The request is taking too long. Please check your internet connection and try again.';
    }

    // 401 Unauthorized
    if (errorString.contains('401') || errorString.contains('unauthorized')) {
      return 'Your session has expired. Please login again to continue.';
    }

    // 403 Forbidden
    if (errorString.contains('403') || errorString.contains('forbidden')) {
      return 'You don\'t have permission to access this resource. Please contact support.';
    }

    // 404 Not Found
    if (errorString.contains('404') || errorString.contains('not found')) {
      return 'The requested information could not be found. Please try again later.';
    }

    // 500 Server errors
    if (errorString.contains('500') ||
        errorString.contains('internal server error') ||
        errorString.contains('server error')) {
      return 'Something went wrong on our end. Please try again in a few moments.';
    }

    // 503 Service Unavailable
    if (errorString.contains('503') ||
        errorString.contains('service unavailable')) {
      return 'The service is temporarily unavailable. Please try again in a few moments.';
    }

    // Invalid response/parsing errors
    if (errorString.contains('json') ||
        errorString.contains('parse') ||
        errorString.contains('format')) {
      return 'We received an unexpected response from the server. Please try again.';
    }

    // Empty data errors
    if (errorString.contains('empty') ||
        errorString.contains('no data') ||
        errorString.contains('null')) {
      return 'No data available at the moment. Please try again later.';
    }

    // Login specific errors
    if (errorString.contains('invalid credentials') ||
        errorString.contains('wrong password') ||
        errorString.contains('incorrect password')) {
      return 'Invalid mobile number or password. Please check your credentials and try again.';
    }

    // Cart errors
    if (errorString.contains('cart')) {
      return 'Unable to update your cart. Please try again.';
    }

    // Order errors
    if (errorString.contains('order')) {
      return 'Unable to process your order. Please try again or contact support.';
    }

    // Generic fallback
    return 'An unexpected error occurred. Please try again or contact support if the problem persists.';
  }

  /// Get title for error dialog based on error type
  static String getErrorTitle(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Connection Error';
    }

    if (errorString.contains('timeout')) {
      return 'Request Timeout';
    }

    if (errorString.contains('401') || errorString.contains('unauthorized')) {
      return 'Session Expired';
    }

    if (errorString.contains('403') || errorString.contains('forbidden')) {
      return 'Access Denied';
    }

    if (errorString.contains('500') || errorString.contains('server error')) {
      return 'Server Error';
    }

    if (errorString.contains('login') || errorString.contains('credentials')) {
      return 'Login Failed';
    }

    if (errorString.contains('cart')) {
      return 'Cart Error';
    }

    if (errorString.contains('order')) {
      return 'Order Error';
    }

    return 'Error';
  }
}
