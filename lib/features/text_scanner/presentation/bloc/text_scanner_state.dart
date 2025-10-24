import 'package:equatable/equatable.dart';
import '../../domain/entities/recognized_text.dart';

abstract class TextScannerState extends Equatable {
  const TextScannerState();

  @override
  List<Object?> get props => [];
}

class TextScannerInitial extends TextScannerState {}

class TextScannerLoading extends TextScannerState {}

class TextScannerSuccess extends TextScannerState {
  final RecognizedText recognizedText;

  const TextScannerSuccess(this.recognizedText);

  @override
  List<Object?> get props => [recognizedText];
}

class TextScannerError extends TextScannerState {
  final String message;

  const TextScannerError(this.message);

  @override
  List<Object?> get props => [message];
}

class TextScannerPermissionDenied extends TextScannerState {
  final String message;

  const TextScannerPermissionDenied(this.message);

  @override
  List<Object?> get props => [message];
}
