import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/auth_tokens.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Result<AuthTokens>> login({
    required String phoneNumber,
    required String password,
    bool rememberMe = false,
  }) async {
    // Bypass login for test credentials
    if (phoneNumber == '9988776655' && password == 'welcome123') {
      final testTokens = AuthTokens(
        accessToken: 'test_access_token_12345',
        refreshToken: 'test_refresh_token_67890',
        expiresIn: 3600,
      );
      await localDataSource.saveTokens(testTokens);

      // Also save a test user
      final testUser = User(
        id: 'test_user_123',
        name: 'Test User',
        email: 'test@truckparts.com',
        phoneNumber: phoneNumber,
        profileImage: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await localDataSource.saveUser(testUser);

      return Result.success(testTokens);
    }

    if (await networkInfo.isConnected) {
      try {
        final tokens = await remoteDataSource.login(
          phoneNumber: phoneNumber,
          password: password,
        );

        await localDataSource.saveTokens(tokens);
        return Result.success(tokens);
      } catch (e) {
        return Result.failure(ServerFailure(message: e.toString()));
      }
    } else {
      return const Result.failure(
        NetworkFailure(message: 'No internet connection'),
      );
    }
  }

  @override
  Future<Result<void>> forgotPassword({required String phoneNumber}) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.forgotPassword(phoneNumber: phoneNumber);
        return const Result.success(null);
      } catch (e) {
        return Result.failure(ServerFailure(message: e.toString()));
      }
    } else {
      return const Result.failure(
        NetworkFailure(message: 'No internet connection'),
      );
    }
  }

  @override
  Future<Result<void>> resetPassword({
    required String phoneNumber,
    required String otp,
    required String newPassword,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.resetPassword(
          phoneNumber: phoneNumber,
          otp: otp,
          newPassword: newPassword,
        );
        return const Result.success(null);
      } catch (e) {
        return Result.failure(ServerFailure(message: e.toString()));
      }
    } else {
      return const Result.failure(
        NetworkFailure(message: 'No internet connection'),
      );
    }
  }

  @override
  Future<Result<void>> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.verifyOtp(phoneNumber: phoneNumber, otp: otp);
        return const Result.success(null);
      } catch (e) {
        return Result.failure(ServerFailure(message: e.toString()));
      }
    } else {
      return const Result.failure(
        NetworkFailure(message: 'No internet connection'),
      );
    }
  }

  @override
  Future<Result<AuthTokens>> refreshToken({
    required String refreshToken,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final tokens = await remoteDataSource.refreshToken(
          refreshToken: refreshToken,
        );

        await localDataSource.saveTokens(tokens);
        return Result.success(tokens);
      } catch (e) {
        return Result.failure(ServerFailure(message: e.toString()));
      }
    } else {
      return const Result.failure(
        NetworkFailure(message: 'No internet connection'),
      );
    }
  }

  @override
  Future<Result<User>> getUserProfile() async {
    // First try to get user from local storage (for bypassed login)
    try {
      final user = await localDataSource.getUser();
      if (user != null) {
        return Result.success(user);
      }
    } catch (e) {
      // Continue to try remote if local fails
    }

    // If no local user, try to get from remote (for real API calls)
    if (await networkInfo.isConnected) {
      try {
        final user = await remoteDataSource.getUserProfile();
        await localDataSource.saveUser(user);
        return Result.success(user);
      } catch (e) {
        // If API fails, check if we have any local user data
        try {
          final localUser = await localDataSource.getUser();
          if (localUser != null) {
            return Result.success(localUser);
          }
        } catch (localError) {
          // Ignore local errors
        }
        return Result.failure(ServerFailure(message: e.toString()));
      }
    } else {
      return const Result.failure(CacheFailure(message: 'No user data found'));
    }
  }

  @override
  Future<Result<void>> logout() async {
    print('🔓 Starting logout process...');

    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.logout();
        print('✅ Remote logout successful');
      } catch (e) {
        // Continue with local logout even if remote logout fails
        print('⚠️ Remote logout failed: $e, continuing with local logout');
      }
    }

    try {
      // Clear all auth-related data
      await localDataSource.clearTokens();
      await localDataSource.clearUser();

      print('✅ Logout complete: All tokens and user data cleared');
      return const Result.success(null);
    } catch (e) {
      print('❌ Logout error: $e');
      return Result.failure(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<bool>> isAuthenticated() async {
    try {
      final isAuth = await localDataSource.isAuthenticated();
      return Result.success(isAuth);
    } catch (e) {
      return Result.failure(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> saveTokens(AuthTokens tokens) async {
    try {
      await localDataSource.saveTokens(tokens);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<AuthTokens?>> getStoredTokens() async {
    try {
      final tokens = await localDataSource.getTokens();
      return Result.success(tokens);
    } catch (e) {
      return Result.failure(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> clearTokens() async {
    try {
      await localDataSource.clearTokens();
      return const Result.success(null);
    } catch (e) {
      return Result.failure(CacheFailure(message: e.toString()));
    }
  }
}
