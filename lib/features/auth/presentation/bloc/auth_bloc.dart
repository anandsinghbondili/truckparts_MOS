import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(const AuthInitial()) {
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<LoginRequested>(_onLoginRequested);
    on<ForgotPasswordRequested>(_onForgotPasswordRequested);
    on<ResetPasswordRequested>(_onResetPasswordRequested);
    on<VerifyOtpRequested>(_onVerifyOtpRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<RefreshTokenRequested>(_onRefreshTokenRequested);
    on<UserProfileRequested>(_onUserProfileRequested);
  }

  String _getFailureMessage(Failure failure) {
    if (failure is ServerFailure) return failure.message;
    if (failure is NetworkFailure) return failure.message;
    if (failure is CacheFailure) return failure.message;
    if (failure is ValidationFailure) return failure.message;
    if (failure is AuthenticationFailure) return failure.message;
    if (failure is AuthorizationFailure) return failure.message;
    return 'Unknown error occurred';
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final isAuthenticatedResult = await authRepository.isAuthenticated();

    if (isAuthenticatedResult.isFailure) {
      emit(const Unauthenticated());
      return;
    }

    final isAuthenticated = isAuthenticatedResult.data!;
    if (isAuthenticated) {
      final userResult = await authRepository.getUserProfile();
      if (userResult.isFailure) {
        emit(const Unauthenticated());
        return;
      }

      final user = userResult.data!;
      final tokensResult = await authRepository.getStoredTokens();
      if (tokensResult.isFailure) {
        emit(const Unauthenticated());
        return;
      }

      final tokens = tokensResult.data;
      if (tokens != null) {
        emit(Authenticated(user: user, tokens: tokens));
      } else {
        emit(const Unauthenticated());
      }
    } else {
      emit(const Unauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final loginResult = await authRepository.login(
      phoneNumber: event.phoneNumber,
      password: event.password,
      rememberMe: event.rememberMe,
    );

    if (loginResult.isFailure) {
      emit(AuthError(message: _getFailureMessage(loginResult.failure!)));
      return;
    }

    final tokens = loginResult.data!;
    final userResult = await authRepository.getUserProfile();
    if (userResult.isFailure) {
      emit(AuthError(message: _getFailureMessage(userResult.failure!)));
      return;
    }

    final user = userResult.data!;
    emit(Authenticated(user: user, tokens: tokens));
  }

  Future<void> _onForgotPasswordRequested(
    ForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final forgotPasswordResult = await authRepository.forgotPassword(
      phoneNumber: event.phoneNumber,
    );

    if (forgotPasswordResult.isFailure) {
      emit(
        AuthError(message: _getFailureMessage(forgotPasswordResult.failure!)),
      );
      return;
    }

    emit(ForgotPasswordSuccess(phoneNumber: event.phoneNumber));
  }

  Future<void> _onResetPasswordRequested(
    ResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final resetPasswordResult = await authRepository.resetPassword(
      phoneNumber: event.phoneNumber,
      otp: event.otp,
      newPassword: event.newPassword,
    );

    if (resetPasswordResult.isFailure) {
      emit(
        AuthError(message: _getFailureMessage(resetPasswordResult.failure!)),
      );
      return;
    }

    emit(const ResetPasswordSuccess());
  }

  Future<void> _onVerifyOtpRequested(
    VerifyOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final verifyOtpResult = await authRepository.verifyOtp(
      phoneNumber: event.phoneNumber,
      otp: event.otp,
    );

    if (verifyOtpResult.isFailure) {
      emit(AuthError(message: _getFailureMessage(verifyOtpResult.failure!)));
      return;
    }

    emit(OtpVerificationSuccess(phoneNumber: event.phoneNumber));
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final logoutResult = await authRepository.logout();

    if (logoutResult.isFailure) {
      emit(AuthError(message: _getFailureMessage(logoutResult.failure!)));
      return;
    }

    // Emit both LogoutSuccess and Unauthenticated to ensure proper state
    emit(const LogoutSuccess());
    // Immediately emit Unauthenticated to clear auth state
    emit(const Unauthenticated());
  }

  Future<void> _onRefreshTokenRequested(
    RefreshTokenRequested event,
    Emitter<AuthState> emit,
  ) async {
    final tokensResult = await authRepository.getStoredTokens();

    if (tokensResult.isFailure) {
      emit(AuthError(message: _getFailureMessage(tokensResult.failure!)));
      return;
    }

    final tokens = tokensResult.data;
    if (tokens != null) {
      final refreshResult = await authRepository.refreshToken(
        refreshToken: tokens.refreshToken,
      );

      if (refreshResult.isFailure) {
        emit(AuthError(message: _getFailureMessage(refreshResult.failure!)));
        return;
      }

      final newTokens = refreshResult.data!;
      // Update the current state with new tokens
      if (state is Authenticated) {
        final currentState = state as Authenticated;
        emit(Authenticated(user: currentState.user, tokens: newTokens));
      }
    }
  }

  Future<void> _onUserProfileRequested(
    UserProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    final userResult = await authRepository.getUserProfile();

    if (userResult.isFailure) {
      emit(AuthError(message: _getFailureMessage(userResult.failure!)));
      return;
    }

    final user = userResult.data!;
    if (state is Authenticated) {
      final currentState = state as Authenticated;
      emit(Authenticated(user: user, tokens: currentState.tokens));
    }
  }
}
