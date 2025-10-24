import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/capture_image_usecase.dart';
import '../../domain/usecases/pick_image_usecase.dart';
import '../../domain/usecases/recognize_text_usecase.dart';
import '../../domain/usecases/request_permissions_usecase.dart';
import 'text_scanner_event.dart';
import 'text_scanner_state.dart';

class TextScannerBloc extends Bloc<TextScannerEvent, TextScannerState> {
  final CaptureImageUseCase _captureImageUseCase;
  final PickImageUseCase _pickImageUseCase;
  final RecognizeTextUseCase _recognizeTextUseCase;
  final RequestPermissionsUseCase _requestPermissionsUseCase;

  TextScannerBloc({
    required CaptureImageUseCase captureImageUseCase,
    required PickImageUseCase pickImageUseCase,
    required RecognizeTextUseCase recognizeTextUseCase,
    required RequestPermissionsUseCase requestPermissionsUseCase,
  }) : _captureImageUseCase = captureImageUseCase,
       _pickImageUseCase = pickImageUseCase,
       _recognizeTextUseCase = recognizeTextUseCase,
       _requestPermissionsUseCase = requestPermissionsUseCase,
       super(TextScannerInitial()) {
    on<CaptureImageEvent>(_onCaptureImage);
    on<PickImageEvent>(_onPickImage);
    on<RecognizeTextEvent>(_onRecognizeText);
    on<ClearResultEvent>(_onClearResult);
    on<RequestPermissionsEvent>(_onRequestPermissions);
  }

  Future<void> _onCaptureImage(
    CaptureImageEvent event,
    Emitter<TextScannerState> emit,
  ) async {
    emit(TextScannerLoading());

    try {
      final imageFile = await _captureImageUseCase();
      if (imageFile != null) {
        add(RecognizeTextEvent(imageFile.path));
      } else {
        emit(const TextScannerError('Failed to capture image'));
      }
    } catch (e) {
      emit(TextScannerError('Failed to capture image: $e'));
    }
  }

  Future<void> _onPickImage(
    PickImageEvent event,
    Emitter<TextScannerState> emit,
  ) async {
    emit(TextScannerLoading());

    try {
      final imageFile = await _pickImageUseCase();
      if (imageFile != null) {
        add(RecognizeTextEvent(imageFile.path));
      } else {
        emit(const TextScannerError('Failed to pick image'));
      }
    } catch (e) {
      emit(TextScannerError('Failed to pick image: $e'));
    }
  }

  Future<void> _onRecognizeText(
    RecognizeTextEvent event,
    Emitter<TextScannerState> emit,
  ) async {
    emit(TextScannerLoading());

    try {
      final imageFile = File(event.imagePath);
      final recognizedText = await _recognizeTextUseCase(imageFile);
      emit(TextScannerSuccess(recognizedText));
    } catch (e) {
      emit(TextScannerError('Failed to recognize text: $e'));
    }
  }

  void _onClearResult(ClearResultEvent event, Emitter<TextScannerState> emit) {
    emit(TextScannerInitial());
  }

  Future<void> _onRequestPermissions(
    RequestPermissionsEvent event,
    Emitter<TextScannerState> emit,
  ) async {
    try {
      final granted = await _requestPermissionsUseCase();
      if (!granted) {
        emit(
          const TextScannerPermissionDenied(
            'Camera and storage permissions are required',
          ),
        );
      }
    } catch (e) {
      emit(TextScannerError('Failed to request permissions: $e'));
    }
  }
}
