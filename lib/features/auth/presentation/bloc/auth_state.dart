import 'package:equatable/equatable.dart';

import '../../domain/entities/user.dart';
import '../../domain/entities/auth_tokens.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class Authenticated extends AuthState {
  final User user;
  final AuthTokens tokens;

  const Authenticated({required this.user, required this.tokens});

  @override
  List<Object> get props => [user, tokens];
}

class Unauthenticated extends AuthState {
  const Unauthenticated();
}

class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object> get props => [message];
}

class ForgotPasswordSuccess extends AuthState {
  final String phoneNumber;

  const ForgotPasswordSuccess({required this.phoneNumber});

  @override
  List<Object> get props => [phoneNumber];
}

class ResetPasswordSuccess extends AuthState {
  const ResetPasswordSuccess();
}

class OtpVerificationSuccess extends AuthState {
  final String phoneNumber;

  const OtpVerificationSuccess({required this.phoneNumber});

  @override
  List<Object> get props => [phoneNumber];
}

class LogoutSuccess extends AuthState {
  const LogoutSuccess();
}
