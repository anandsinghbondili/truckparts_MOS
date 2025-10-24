import '../../../../core/errors/failures.dart';
import '../entities/auth_tokens.dart';
import '../entities/user.dart';

// Temporary Result class until dartz is available
class Result<T> {
  final T? data;
  final Failure? failure;

  const Result.success(this.data) : failure = null;
  const Result.failure(this.failure) : data = null;

  bool get isSuccess => failure == null;
  bool get isFailure => failure != null;
}

abstract class AuthRepository {
  Future<Result<AuthTokens>> login({
    required String phoneNumber,
    required String password,
    bool rememberMe = false,
  });

  Future<Result<void>> forgotPassword({required String phoneNumber});

  Future<Result<void>> resetPassword({
    required String phoneNumber,
    required String otp,
    required String newPassword,
  });

  Future<Result<void>> verifyOtp({
    required String phoneNumber,
    required String otp,
  });

  Future<Result<AuthTokens>> refreshToken({required String refreshToken});

  Future<Result<User>> getUserProfile();

  Future<Result<void>> logout();

  Future<Result<bool>> isAuthenticated();

  Future<Result<void>> saveTokens(AuthTokens tokens);

  Future<Result<AuthTokens?>> getStoredTokens();

  Future<Result<void>> clearTokens();
}
