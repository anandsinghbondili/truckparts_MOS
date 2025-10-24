import 'dart:math';
import 'package:get_it/get_it.dart';
import '../../domain/entities/text_match.dart';
import '../../../home/data/services/parts_data_service.dart';

class TextMatchService {
  final PartsDataService _partsDataService = GetIt.instance<PartsDataService>();

  List<TextMatch> processTextMatches(String extractedText) {
    final allParts = _partsDataService.allParts;
    final words = _extractWords(extractedText);
    final matches = <TextMatch>[];

    for (final word in words) {
      if (word.length < 3) continue; // Skip very short words

      final match = _findBestMatch(word, allParts);
      matches.add(match);
    }

    return matches;
  }

  List<String> _extractWords(String text) {
    // Clean and split text into words
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remove punctuation
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
  }

  TextMatch _findBestMatch(String word, List<dynamic> allParts) {
    String? bestMatch;
    double bestScore = 0.0;
    MatchType matchType = MatchType.none;

    for (final part in allParts) {
      final partName = part.item?.toString().toLowerCase() ?? '';
      final partNumber = part.part?.toString().toLowerCase() ?? '';
      final brand = part.brand?.toString().toLowerCase() ?? '';
      final subCategory = part.subCategory?.toString().toLowerCase() ?? '';

      // Check exact matches first
      if (partName == word ||
          partNumber == word ||
          brand == word ||
          subCategory == word) {
        return TextMatch(
          text: word,
          matchType: MatchType.exact,
          matchedPart: part.item?.toString(),
          confidence: 1.0,
        );
      }

      // Check partial matches
      final nameScore = _calculateSimilarity(word, partName);
      final numberScore = _calculateSimilarity(word, partNumber);
      final brandScore = _calculateSimilarity(word, brand);
      final subCategoryScore = _calculateSimilarity(word, subCategory);

      final maxScore = [
        nameScore,
        numberScore,
        brandScore,
        subCategoryScore,
      ].reduce(max);

      if (maxScore > bestScore && maxScore > 0.6) {
        bestScore = maxScore;
        bestMatch = part.item?.toString();
        matchType = MatchType.partial;
      }
    }

    return TextMatch(
      text: word,
      matchType: matchType,
      matchedPart: bestMatch,
      confidence: bestScore,
    );
  }

  double _calculateSimilarity(String word1, String word2) {
    if (word1.isEmpty || word2.isEmpty) return 0.0;

    // Check if one contains the other
    if (word1.contains(word2) || word2.contains(word1)) {
      return 0.8;
    }

    // Calculate Levenshtein distance
    final distance = _levenshteinDistance(word1, word2);
    final maxLength = [word1.length, word2.length].reduce(max);

    if (maxLength == 0) return 0.0;

    return 1.0 - (distance / maxLength);
  }

  int _levenshteinDistance(String s1, String s2) {
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    final matrix = List.generate(
      s1.length + 1,
      (i) => List.generate(s2.length + 1, (j) => 0),
    );

    for (int i = 0; i <= s1.length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= s2.length; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1, // deletion
          matrix[i][j - 1] + 1, // insertion
          matrix[i - 1][j - 1] + cost, // substitution
        ].reduce(min);
      }
    }

    return matrix[s1.length][s2.length];
  }
}
