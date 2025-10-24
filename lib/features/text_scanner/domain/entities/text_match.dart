import 'package:equatable/equatable.dart';

enum MatchType { exact, partial, none }

class TextMatch extends Equatable {
  final String text;
  final MatchType matchType;
  final String? matchedPart;
  final double? confidence;

  const TextMatch({
    required this.text,
    required this.matchType,
    this.matchedPart,
    this.confidence,
  });

  @override
  List<Object?> get props => [text, matchType, matchedPart, confidence];

  TextMatch copyWith({
    String? text,
    MatchType? matchType,
    String? matchedPart,
    double? confidence,
  }) {
    return TextMatch(
      text: text ?? this.text,
      matchType: matchType ?? this.matchType,
      matchedPart: matchedPart ?? this.matchedPart,
      confidence: confidence ?? this.confidence,
    );
  }
}
