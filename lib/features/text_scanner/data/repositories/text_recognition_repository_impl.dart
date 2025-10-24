import 'dart:io';
import '../../domain/entities/recognized_text.dart';
import '../../domain/repositories/text_recognition_repository.dart';
import '../datasources/image_service.dart';
import '../datasources/permission_service.dart';
import '../datasources/text_recognition_service.dart';

class TextRecognitionRepositoryImpl implements TextRecognitionRepository {
  final ImageService _imageService;
  final PermissionService _permissionService;
  final TextRecognitionService _textRecognitionService;

  TextRecognitionRepositoryImpl({
    required ImageService imageService,
    required PermissionService permissionService,
    required TextRecognitionService textRecognitionService,
  }) : _imageService = imageService,
       _permissionService = permissionService,
       _textRecognitionService = textRecognitionService;

  @override
  Future<RecognizedText> recognizeTextFromImage(File imageFile) async {
    return await _textRecognitionService.recognizeTextFromImage(imageFile);
  }

  @override
  Future<File?> captureImageFromCamera() async {
    return await _imageService.captureImageFromCamera();
  }

  @override
  Future<File?> pickImageFromGallery() async {
    return await _imageService.pickImageFromGallery();
  }

  @override
  Future<bool> requestPermissions() async {
    return await _permissionService.requestPermissions();
  }
}
