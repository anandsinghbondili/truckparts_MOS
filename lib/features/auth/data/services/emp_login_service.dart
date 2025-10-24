import 'package:dio/dio.dart';

import '../../../../core/config/environment.dart';

/// Service for handling Employee Login API integration
/// URL: {{protocol}}://{{serverIp}}:{{port}}/api/Mobileapp/GetEmpLogin?MobileNo={{MobileNo}}&Password={{Password}}
/// Base URL uses Environment configuration
class EmpLoginService {
  final Dio _dio;
  final EnvironmentConfig _environment = EnvironmentConfig.current;

  EmpLoginService({Dio? dio}) : _dio = dio ?? Dio();

  /// Base URL for the Employee Login API (from environment config)
  String get _baseUrl => _environment.baseUrl;

  /// Login with mobile number and password
  ///
  /// [mobileNo] - Employee mobile number
  /// [password] - Employee password
  ///
  /// Returns a [Map<String, dynamic>] containing the API response
  Future<Map<String, dynamic>> login({
    required String mobileNo,
    required String password,
  }) async {
    try {
      print('🔐 EmpLoginService: Attempting login for mobile: $mobileNo');

      // Build the full URL with parameters
      final queryParams = {'MobileNo': mobileNo, 'Password': password};
      final fullUrl =
          '$_baseUrl/api/Mobileapp/GetEmpLogin?${Uri(queryParameters: queryParams).query}';

      print('🌐 EmpLoginService: Full GET URL: $fullUrl');
      print('📋 EmpLoginService: Query Parameters: $queryParams');
      print('📋 EmpLoginService: Base URL: $_baseUrl');
      print('📋 EmpLoginService: Endpoint: /api/Mobileapp/GetEmpLogin');
      print(
        '📋 EmpLoginService: Request Headers: {Content-Type: application/json, Accept: application/json}',
      );

      final response = await _dio.get(
        '$_baseUrl/api/Mobileapp/GetEmpLogin',
        queryParameters: queryParams,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      print('📡 EmpLoginService: Response status: ${response.statusCode}');
      print('📡 EmpLoginService: Response headers: ${response.headers}');
      print('📡 EmpLoginService: Response data: ${response.data}');
      print('📡 EmpLoginService: Request URL: ${response.requestOptions.uri}');
      print(
        '📡 EmpLoginService: Request method: ${response.requestOptions.method}',
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw EmpLoginException(
          'Login failed with status code: ${response.statusCode}',
          response.statusCode,
        );
      }
    } on DioException catch (e) {
      print('❌ EmpLoginService: DioException: ${e.message}');
      print('❌ EmpLoginService: Response: ${e.response?.data}');
      throw _handleDioException(e);
    } catch (e) {
      print('❌ EmpLoginService: Unexpected error: ${e.toString()}');
      throw EmpLoginException('Unexpected error: ${e.toString()}');
    }
  }

  /// Test method to verify API connectivity and response format
  /// Note: This test requires valid credentials to be passed as parameters
  Future<void> testApiConnection({
    required String mobileNo,
    required String password,
  }) async {
    try {
      print('🧪 EmpLoginService: Testing API connection on port 3032...');
      final response = await _dio.get(
        '$_baseUrl/api/Mobileapp/GetEmpLogin',
        queryParameters: {'MobileNo': mobileNo, 'Password': password},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );
      print('🧪 EmpLoginService: Test response status: ${response.statusCode}');
      print('🧪 EmpLoginService: Test response data: ${response.data}');
    } catch (e) {
      print('🧪 EmpLoginService: Test failed: $e');
    }
  }

  /// Handle Dio exceptions and convert them to EmpLoginException
  EmpLoginException _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return EmpLoginException(
          'Connection timeout. Please check your internet connection.',
        );
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message =
            e.response?.data?['message'] ??
            e.response?.data?['error'] ??
            'Server error occurred';

        if (statusCode == 401) {
          return EmpLoginException(
            'Invalid mobile number or password.',
            statusCode,
          );
        } else if (statusCode == 403) {
          return EmpLoginException(
            'Access denied. You do not have permission.',
            statusCode,
          );
        } else if (statusCode == 404) {
          return EmpLoginException('Login endpoint not found.', statusCode);
        } else if (statusCode == 500) {
          return EmpLoginException(
            'Internal server error. Please try again later.',
            statusCode,
          );
        }
        return EmpLoginException(message, statusCode);
      case DioExceptionType.cancel:
        return EmpLoginException('Request was cancelled.');
      case DioExceptionType.connectionError:
        return EmpLoginException(
          'No internet connection. Please check your network.',
        );
      default:
        return EmpLoginException(
          'An unexpected error occurred. Please try again.',
        );
    }
  }
}

/// Custom exception for Employee Login API errors
class EmpLoginException implements Exception {
  final String message;
  final int? statusCode;

  EmpLoginException(this.message, [this.statusCode]);

  @override
  String toString() => 'EmpLoginException: $message';
}

/// Response model for Employee Login API
/// Example API response structure:
/// {
///   "success": true,
///   "message": "You have Successfully sign in",
///   "parameters": {
///     "mobile": "{{MobileNo}}",
///     "password": "{{Password}}",
///     "AcOwner": "{{AcOwner}}",
///     "empname": "{{EmployeeName}}",
///     "empid": "{{EmployeeId}}",
///     "rolesid": "{{RoleIds}}",
///     "rolesname": "{{RoleNames}}",
///     "tokenid": "{{TokenId}}",
///     "apptype": "{{AppType}}"
///   }
/// }
class EmpLoginResponse {
  final bool success;
  final String? message;
  final Map<String, dynamic>? parameters;
  final String? token;
  final String? refreshToken;
  final int? expiresIn;

  EmpLoginResponse({
    required this.success,
    this.message,
    this.parameters,
    this.token,
    this.refreshToken,
    this.expiresIn,
  });

  factory EmpLoginResponse.fromJson(Map<String, dynamic> json) {
    return EmpLoginResponse(
      success: json['success'] ?? json['Success'] ?? false,
      message: json['message'] ?? json['Message'],
      parameters: json['parameters'] ?? json['Parameters'],
      // Extract token from parameters if available
      token: json['parameters']?['tokenid'] ?? json['Parameters']?['tokenid'],
      refreshToken: json['refreshToken'] ?? json['RefreshToken'],
      expiresIn:
          json['expiresIn'] ?? json['ExpiresIn'] ?? 3600, // Default 1 hour
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'parameters': parameters,
      'token': token,
      'refreshToken': refreshToken,
      'expiresIn': expiresIn,
    };
  }
}
