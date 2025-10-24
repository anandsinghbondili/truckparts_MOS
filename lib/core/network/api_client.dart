import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

class ApiClient {
  final Dio _dio;

  ApiClient(this._dio);

  // Auth endpoints
  Future<HttpResponse<Map<String, dynamic>>> login(
    Map<String, dynamic> loginData,
  ) async {
    final response = await _dio.post('/auth/login', data: loginData);
    return HttpResponse(response.data as Map<String, dynamic>, response);
  }

  Future<HttpResponse<Map<String, dynamic>>> forgotPassword(
    Map<String, dynamic> forgotPasswordData,
  ) async {
    final response = await _dio.post(
      '/auth/forgot-password',
      data: forgotPasswordData,
    );
    return HttpResponse(response.data as Map<String, dynamic>, response);
  }

  Future<HttpResponse<Map<String, dynamic>>> resetPassword(
    Map<String, dynamic> resetPasswordData,
  ) async {
    final response = await _dio.post(
      '/auth/reset-password',
      data: resetPasswordData,
    );
    return HttpResponse(response.data as Map<String, dynamic>, response);
  }

  Future<HttpResponse<Map<String, dynamic>>> verifyOtp(
    Map<String, dynamic> otpData,
  ) async {
    final response = await _dio.post('/auth/verify-otp', data: otpData);
    return HttpResponse(response.data as Map<String, dynamic>, response);
  }

  Future<HttpResponse<Map<String, dynamic>>> refreshToken(
    Map<String, dynamic> refreshData,
  ) async {
    final response = await _dio.post('/auth/refresh-token', data: refreshData);
    return HttpResponse(response.data as Map<String, dynamic>, response);
  }

  // User endpoints
  Future<HttpResponse<Map<String, dynamic>>> getUserProfile() async {
    try {
      final response = await _dio.get('/user/profile');
      return HttpResponse(response.data as Map<String, dynamic>, response);
    } catch (e) {
      // For development, return a mock user profile
      final mockResponse = {
        'data': {
          'id': 'dev_user_123',
          'name': 'Development User',
          'email': 'dev@truckparts.com',
          'phone_number': '9988776655',
          'profile_image': null,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
      };
      throw Exception('API not available - using mock data');
    }
  }

  Future<HttpResponse<Map<String, dynamic>>> logout() async {
    try {
      final response = await _dio.post('/user/logout');
      return HttpResponse(response.data as Map<String, dynamic>, response);
    } catch (e) {
      // For development, return success even if API fails
      final mockResponse = {
        'data': {'message': 'Logged out successfully'},
      };
      throw Exception('API not available - logout successful');
    }
  }

  // Placeholder methods for future implementation
  Future<HttpResponse<Map<String, dynamic>>> getProducts({
    int page = 1,
    int limit = 20,
    String? search,
    String? vehicleMake,
    String? vehicleModel,
    String? category,
    String? size,
  }) async {
    // TODO: Implement when needed
    throw UnimplementedError('getProducts not implemented yet');
  }

  Future<HttpResponse<Map<String, dynamic>>> getCategories() async {
    // TODO: Implement when needed
    throw UnimplementedError('getCategories not implemented yet');
  }

  Future<HttpResponse<Map<String, dynamic>>> getBanners() async {
    // TODO: Implement when needed
    throw UnimplementedError('getBanners not implemented yet');
  }

  Future<HttpResponse<Map<String, dynamic>>> getCart() async {
    // TODO: Implement when needed
    throw UnimplementedError('getCart not implemented yet');
  }

  Future<HttpResponse<Map<String, dynamic>>> addToCart(
    Map<String, dynamic> cartItem,
  ) async {
    // TODO: Implement when needed
    throw UnimplementedError('addToCart not implemented yet');
  }

  Future<HttpResponse<Map<String, dynamic>>> getOrders({
    int page = 1,
    int limit = 20,
  }) async {
    // TODO: Implement when needed
    throw UnimplementedError('getOrders not implemented yet');
  }
}

class DioModule {
  static Dio createDio(SharedPreferences prefs) {
    final dio = Dio();

    dio.options = BaseOptions(
      baseUrl: AppConstants.baseUrl + AppConstants.apiVersion,
      connectTimeout: AppConstants.connectTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    // Add auth interceptor
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = prefs.getString(AppConstants.tokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            // Handle token refresh logic here
            final refreshToken = prefs.getString(AppConstants.refreshTokenKey);
            if (refreshToken != null) {
              try {
                final response = await dio.post(
                  '/auth/refresh-token',
                  data: {'refresh_token': refreshToken},
                );
                final newToken = response.data['data']['token'];
                prefs.setString(AppConstants.tokenKey, newToken);

                // Retry the original request
                error.requestOptions.headers['Authorization'] =
                    'Bearer $newToken';
                final retryResponse = await dio.fetch(error.requestOptions);
                handler.resolve(retryResponse);
                return;
              } catch (e) {
                // Refresh failed, redirect to login
                prefs.remove(AppConstants.tokenKey);
                prefs.remove(AppConstants.refreshTokenKey);
              }
            }
          }
          handler.next(error);
        },
      ),
    );

    return dio;
  }
}
