import 'package:equatable/equatable.dart';

enum MatchType { exact, partial, none }

class TextMatch extends Equatable {
  final String text;
  final MatchType matchType;
  final String? matchedPart;
  final double? confidence;
  final Map<String, dynamic>? partData; // Store full part data from JSON

  const TextMatch({
    required this.text,
    required this.matchType,
    this.matchedPart,
    this.confidence,
    this.partData,
  });

  @override
  List<Object?> get props => [text, matchType, matchedPart, confidence, partData];

  TextMatch copyWith({
    String? text,
    MatchType? matchType,
    String? matchedPart,
    double? confidence,
    Map<String, dynamic>? partData,
  }) {
    return TextMatch(
      text: text ?? this.text,
      matchType: matchType ?? this.matchType,
      matchedPart: matchedPart ?? this.matchedPart,
      confidence: confidence ?? this.confidence,
      partData: partData ?? this.partData,
    );
  }
}
