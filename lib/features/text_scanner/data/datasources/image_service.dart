import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';

class ImageService {
  final ImagePicker _imagePicker = ImagePicker();
  List<CameraDescription>? _cameras;

  Future<List<CameraDescription>> getCameras() async {
    if (_cameras == null) {
      _cameras = await availableCameras();
    }
    return _cameras!;
  }

  Future<File?> captureImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to capture image: $e');
    }
  }

  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }
}
