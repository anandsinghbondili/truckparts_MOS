import 'dart:io';
import '../repositories/text_recognition_repository.dart';

class PickImageUseCase {
  final TextRecognitionRepository _repository;

  PickImageUseCase(this._repository);

  Future<File?> call() async {
    return await _repository.pickImageFromGallery();
  }
}
