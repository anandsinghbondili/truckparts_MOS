import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class CheckAuthStatus extends AuthEvent {
  const CheckAuthStatus();
}

class LoginRequested extends AuthEvent {
  final String phoneNumber;
  final String password;
  final bool rememberMe;

  const LoginRequested({
    required this.phoneNumber,
    required this.password,
    this.rememberMe = false,
  });

  @override
  List<Object> get props => [phoneNumber, password, rememberMe];
}

class ForgotPasswordRequested extends AuthEvent {
  final String phoneNumber;

  const ForgotPasswordRequested({required this.phoneNumber});

  @override
  List<Object> get props => [phoneNumber];
}

class ResetPasswordRequested extends AuthEvent {
  final String phoneNumber;
  final String otp;
  final String newPassword;

  const ResetPasswordRequested({
    required this.phoneNumber,
    required this.otp,
    required this.newPassword,
  });

  @override
  List<Object> get props => [phoneNumber, otp, newPassword];
}

class VerifyOtpRequested extends AuthEvent {
  final String phoneNumber;
  final String otp;

  const VerifyOtpRequested({required this.phoneNumber, required this.otp});

  @override
  List<Object> get props => [phoneNumber, otp];
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

class RefreshTokenRequested extends AuthEvent {
  const RefreshTokenRequested();
}

class UserProfileRequested extends AuthEvent {
  const UserProfileRequested();
}
