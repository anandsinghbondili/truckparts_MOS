import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/auth_tokens.dart';
import '../../domain/entities/user.dart';
import '../models/auth_tokens_model.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthTokens> login({
    required String phoneNumber,
    required String password,
  });

  Future<void> forgotPassword({required String phoneNumber});

  Future<void> resetPassword({
    required String phoneNumber,
    required String otp,
    required String newPassword,
  });

  Future<void> verifyOtp({required String phoneNumber, required String otp});

  Future<AuthTokens> refreshToken({required String refreshToken});

  Future<User> getUserProfile();

  Future<void> logout();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<AuthTokens> login({
    required String phoneNumber,
    required String password,
  }) async {
    try {
      final response = await apiClient.login({
        'phone_number': phoneNumber,
        'password': password,
      });

      if (response.response.statusCode == 200) {
        final data = response.data['data'];
        return AuthTokensModel.fromJson(data).toEntity();
      } else {
        throw DioException(
          requestOptions: response.response.requestOptions,
          response: response.response,
          message: response.data['message'] ?? 'Login failed',
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<void> forgotPassword({required String phoneNumber}) async {
    try {
      final response = await apiClient.forgotPassword({
        'phone_number': phoneNumber,
      });

      if (response.response.statusCode != 200) {
        throw DioException(
          requestOptions: response.response.requestOptions,
          response: response.response,
          message: response.data['message'] ?? 'Failed to send OTP',
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<void> resetPassword({
    required String phoneNumber,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final response = await apiClient.resetPassword({
        'phone_number': phoneNumber,
        'otp': otp,
        'new_password': newPassword,
      });

      if (response.response.statusCode != 200) {
        throw DioException(
          requestOptions: response.response.requestOptions,
          response: response.response,
          message: response.data['message'] ?? 'Password reset failed',
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<void> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    try {
      final response = await apiClient.verifyOtp({
        'phone_number': phoneNumber,
        'otp': otp,
      });

      if (response.response.statusCode != 200) {
        throw DioException(
          requestOptions: response.response.requestOptions,
          response: response.response,
          message: response.data['message'] ?? 'OTP verification failed',
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<AuthTokens> refreshToken({required String refreshToken}) async {
    try {
      final response = await apiClient.refreshToken({
        'refresh_token': refreshToken,
      });

      if (response.response.statusCode == 200) {
        final data = response.data['data'];
        return AuthTokensModel.fromJson(data).toEntity();
      } else {
        throw DioException(
          requestOptions: response.response.requestOptions,
          response: response.response,
          message: response.data['message'] ?? 'Token refresh failed',
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<User> getUserProfile() async {
    try {
      final response = await apiClient.getUserProfile();

      if (response.response.statusCode == 200) {
        final data = response.data['data'];
        return UserModel.fromJson(data).toEntity();
      } else {
        throw DioException(
          requestOptions: response.response.requestOptions,
          response: response.response,
          message: response.data['message'] ?? 'Failed to get user profile',
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      final response = await apiClient.logout();

      if (response.response.statusCode != 200) {
        throw DioException(
          requestOptions: response.response.requestOptions,
          response: response.response,
          message: response.data['message'] ?? 'Logout failed',
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Exception _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception(
          'Connection timeout. Please check your internet connection.',
        );
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['message'] ?? 'Server error occurred';
        if (statusCode == 401) {
          return Exception('Authentication failed. Please login again.');
        } else if (statusCode == 403) {
          return Exception('Access denied. You do not have permission.');
        } else if (statusCode == 404) {
          return Exception('Resource not found.');
        } else if (statusCode == 500) {
          return Exception('Internal server error. Please try again later.');
        }
        return Exception(message);
      case DioExceptionType.cancel:
        return Exception('Request was cancelled.');
      case DioExceptionType.connectionError:
        return Exception('No internet connection. Please check your network.');
      default:
        return Exception('An unexpected error occurred. Please try again.');
    }
  }
}
