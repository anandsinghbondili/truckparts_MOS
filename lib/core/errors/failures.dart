import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  const Failure([List properties = const <dynamic>[]]);

  @override
  List<Object?> get props => [];
}

// General failures
class ServerFailure extends Failure {
  final String message;
  final int? statusCode;

  const ServerFailure({required this.message, this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

class NetworkFailure extends Failure {
  final String message;

  const NetworkFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

class CacheFailure extends Failure {
  final String message;

  const CacheFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

class ValidationFailure extends Failure {
  final String message;

  const ValidationFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

class AuthenticationFailure extends Failure {
  final String message;

  const AuthenticationFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

class AuthorizationFailure extends Failure {
  final String message;

  const AuthorizationFailure({required this.message});

  @override
  List<Object?> get props => [message];
}
