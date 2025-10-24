import 'package:dio/dio.dart';
import '../../../../core/services/api_service_base.dart';

/// Service for Password Reset API
///
/// Handles OTP request and password reset functionality using app context
class PasswordResetService extends ApiServiceBase {
  PasswordResetService({required super.dio, required super.appContext});

  /// Request OTP for password reset
  ///
  /// API: GET /api/Mobileapp/ResetPwd?MobileNo={{UserID}}
  ///
  /// Uses app context UserID (mobile number) for the request.
  /// This will send an OTP to the registered mobile number.
  ///
  /// Returns the API response containing OTP details
  Future<Map<String, dynamic>> requestOtp(String mobileNumber) async {
    try {
      print(
        '🔐 PasswordResetService: Requesting OTP for mobile: $mobileNumber',
      );

      // Build the URL using app context base URL
      final baseUrl = appContext.apiBaseUrl;
      final endpoint = '/api/Mobileapp/ResetPwd';
      final fullUrl = '$baseUrl$endpoint';

      print('🌐 Password Reset URL: $fullUrl');
      print('📱 Mobile Number: $mobileNumber');

      final response = await dio.get(
        fullUrl,
        queryParameters: {'MobileNo': mobileNumber},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response data: ${response.data}');

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw PasswordResetException(
          'Failed to request OTP: ${response.statusCode}',
          response.statusCode,
        );
      }
    } on DioException catch (e) {
      print('❌ PasswordResetService: DioException: ${e.message}');
      print('❌ Response: ${e.response?.data}');
      throw _handleDioException(e);
    } catch (e) {
      print('❌ PasswordResetService: Unexpected error: ${e.toString()}');
      throw PasswordResetException('Unexpected error: ${e.toString()}');
    }
  }

  /// Request OTP using app context UserID
  ///
  /// This method uses the UserID from app context if available,
  /// otherwise uses the provided mobile number
  Future<Map<String, dynamic>> requestOtpWithContext({
    String? mobileNumber,
  }) async {
    // Use app context UserID if available and no mobile number provided
    final phoneNumber =
        mobileNumber ?? (appContext.isInitialized ? appContext.userId : null);

    if (phoneNumber == null || phoneNumber.isEmpty) {
      throw PasswordResetException(
        'Mobile number is required. Please provide a mobile number or login first.',
      );
    }

    return await requestOtp(phoneNumber);
  }

  /// Verify OTP for password reset
  ///
  /// API: GET /api/Mobileapp/verifySMS?MobileNo={{UserID}}&Otp=####
  ///
  /// Verifies the OTP entered by the user against the OTP sent to their mobile.
  ///
  /// [mobileNumber] - User's mobile number
  /// [otp] - OTP code entered by user
  ///
  /// Returns the API response containing verification result
  Future<Map<String, dynamic>> verifyOtp({
    required String mobileNumber,
    required String otp,
  }) async {
    try {
      print('🔐 PasswordResetService: Verifying OTP for mobile: $mobileNumber');

      // Build the URL using app context base URL
      final baseUrl = appContext.apiBaseUrl;
      final endpoint = '/api/Mobileapp/verifySMS';
      final fullUrl = '$baseUrl$endpoint';

      print('🌐 Verify OTP URL: $fullUrl');
      print('📱 Mobile Number: $mobileNumber');
      print('🔢 OTP: $otp');

      final response = await dio.get(
        fullUrl,
        queryParameters: {'MobileNo': mobileNumber, 'Otp': otp},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response data: ${response.data}');

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw PasswordResetException(
          'Failed to verify OTP: ${response.statusCode}',
          response.statusCode,
        );
      }
    } on DioException catch (e) {
      print('❌ PasswordResetService: DioException: ${e.message}');
      print('❌ Response: ${e.response?.data}');
      throw _handleDioException(e);
    } catch (e) {
      print('❌ PasswordResetService: Unexpected error: ${e.toString()}');
      throw PasswordResetException('Unexpected error: ${e.toString()}');
    }
  }

  /// Handle Dio exceptions
  PasswordResetException _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return PasswordResetException(
          'Connection timeout. Please check your internet connection.',
          e.response?.statusCode,
        );
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['message'] ?? 'Request failed';
        return PasswordResetException(message, statusCode);
      case DioExceptionType.cancel:
        return PasswordResetException('Request cancelled');
      default:
        return PasswordResetException(
          'Network error: ${e.message}',
          e.response?.statusCode,
        );
    }
  }
}

/// Custom exception for password reset operations
class PasswordResetException implements Exception {
  final String message;
  final int? statusCode;

  PasswordResetException(this.message, [this.statusCode]);

  @override
  String toString() => 'PasswordResetException: $message';
}

/// Response model for password reset API
class PasswordResetResponse {
  final bool success;
  final String? message;
  final String? otp; // Some APIs return OTP in response (for testing)
  final Map<String, dynamic>? data;

  PasswordResetResponse({
    required this.success,
    this.message,
    this.otp,
    this.data,
  });

  factory PasswordResetResponse.fromJson(Map<String, dynamic> json) {
    return PasswordResetResponse(
      success: json['success'] ?? json['Success'] ?? false,
      message: json['message'] ?? json['Message'],
      otp: json['otp'] ?? json['OTP'],
      data: json['data'] ?? json['Data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'success': success, 'message': message, 'otp': otp, 'data': data};
  }
}
