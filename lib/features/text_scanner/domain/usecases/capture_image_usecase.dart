import 'dart:io';
import '../repositories/text_recognition_repository.dart';

class CaptureImageUseCase {
  final TextRecognitionRepository _repository;

  CaptureImageUseCase(this._repository);

  Future<File?> call() async {
    return await _repository.captureImageFromCamera();
  }
}
