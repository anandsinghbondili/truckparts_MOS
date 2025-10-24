import 'package:equatable/equatable.dart';

class RecognizedText extends Equatable {
  final String text;
  final String? imagePath;
  final DateTime timestamp;

  const RecognizedText({
    required this.text,
    this.imagePath,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [text, imagePath, timestamp];

  RecognizedText copyWith({
    String? text,
    String? imagePath,
    DateTime? timestamp,
  }) {
    return RecognizedText(
      text: text ?? this.text,
      imagePath: imagePath ?? this.imagePath,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
