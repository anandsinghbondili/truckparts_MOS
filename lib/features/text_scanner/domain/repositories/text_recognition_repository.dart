import 'dart:io';
import '../entities/recognized_text.dart';

abstract class TextRecognitionRepository {
  Future<RecognizedText> recognizeTextFromImage(File imageFile);
  Future<File?> captureImageFromCamera();
  Future<File?> pickImageFromGallery();
  Future<bool> requestPermissions();
}
