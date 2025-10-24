import '../repositories/text_recognition_repository.dart';

class RequestPermissionsUseCase {
  final TextRecognitionRepository _repository;

  RequestPermissionsUseCase(this._repository);

  Future<bool> call() async {
    return await _repository.requestPermissions();
  }
}
