import 'dart:io';
import '../entities/recognized_text.dart';
import '../repositories/text_recognition_repository.dart';

class RecognizeTextUseCase {
  final TextRecognitionRepository _repository;

  RecognizeTextUseCase(this._repository);

  Future<RecognizedText> call(File imageFile) async {
    return await _repository.recognizeTextFromImage(imageFile);
  }
}
