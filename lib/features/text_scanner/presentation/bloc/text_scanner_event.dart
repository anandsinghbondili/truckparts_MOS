import 'package:equatable/equatable.dart';

abstract class TextScannerEvent extends Equatable {
  const TextScannerEvent();

  @override
  List<Object?> get props => [];
}

class CaptureImageEvent extends TextScannerEvent {}

class PickImageEvent extends TextScannerEvent {}

class RecognizeTextEvent extends TextScannerEvent {
  final String imagePath;

  const RecognizeTextEvent(this.imagePath);

  @override
  List<Object?> get props => [imagePath];
}

class ClearResultEvent extends TextScannerEvent {}

class RequestPermissionsEvent extends TextScannerEvent {}
