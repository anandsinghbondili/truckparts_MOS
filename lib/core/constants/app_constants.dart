class AppConstants {
  // API Configuration
  static const String baseUrl = 'https://api.truckparts.com';
  static const String apiVersion = '/v1';
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  static const String themeKey = 'theme_mode';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Cart
  static const int maxCartItems = 100;

  // Currency
  static const String currencySymbol = '₹';
  static const String currencyCode = 'INR';

  // Validation
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const String phoneNumberRegex = r'^[6-9]\d{9}$';

  // App Info
  static const String appName = 'Truck Parts - MOS';
  static const String appVersion = '1.0.0';
}
