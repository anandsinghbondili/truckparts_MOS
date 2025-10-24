import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart'
    as mlkit;
import '../../domain/entities/recognized_text.dart';

class TextRecognitionService {
  final mlkit.TextRecognizer _textRecognizer = mlkit.TextRecognizer();

  Future<RecognizedText> recognizeTextFromImage(File imageFile) async {
    try {
      final inputImage = mlkit.InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      return RecognizedText(
        text: recognizedText.text,
        imagePath: imageFile.path,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to recognize text: $e');
    }
  }

  void dispose() {
    _textRecognizer.close();
  }
}
