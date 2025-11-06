import 'dart:convert';
import 'package:flutter/services.dart';
import '../../domain/entities/text_match.dart';

class TextMatchService {
  List<Map<String, dynamic>>? _cachedPartsData;

  /// Load parts data from assets/data/parts_data.json
  Future<void> _loadPartsData() async {
    if (_cachedPartsData != null) return;

    try {
      final String jsonString =
          await rootBundle.loadString('assets/data/parts_data.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      _cachedPartsData = (jsonData['parameters'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>() ??
          [];
      print(
          '✅ TextMatchService: Loaded ${_cachedPartsData!.length} parts from JSON');
    } catch (e) {
      print('❌ TextMatchService: Error loading parts data: $e');
      _cachedPartsData = [];
    }
  }

  /// Process extracted text and find exact matches against itemname in parts_data.json
  Future<List<TextMatch>> processTextMatches(String extractedText) async {
    await _loadPartsData();

    if (_cachedPartsData == null || _cachedPartsData!.isEmpty) {
      print('⚠️ TextMatchService: No parts data available');
      return [];
    }

    final matches = <TextMatch>[];
    final searchTerms = _extractSearchTerms(extractedText);

    // Find exact and partial matches against itemname field
    for (final term in searchTerms) {
      if (term.length < 2) continue; // Skip very short terms

      final exactMatches = _findExactMatches(term, _cachedPartsData!);

      if (exactMatches.isNotEmpty) {
        // Add all exact matches for this term
        matches.addAll(exactMatches);
      } else {
        // Try to find partial matches
        final partialMatches = _findPartialMatches(term, _cachedPartsData!);
        
        if (partialMatches.isNotEmpty) {
          // Add partial matches as yellow pills
          matches.addAll(partialMatches);
        } else {
          // No match found for this term
          matches.add(TextMatch(
            text: term,
            matchType: MatchType.none,
            matchedPart: null,
            confidence: 0.0,
          ));
        }
      }
    }

    // Remove duplicates based on text
    final uniqueMatches = <String, TextMatch>{};
    for (final match in matches) {
      final key = match.text.toLowerCase();
      if (!uniqueMatches.containsKey(key) ||
          match.matchType == MatchType.exact) {
        uniqueMatches[key] = match;
      }
    }

    return uniqueMatches.values.toList();
  }

  /// Extract search terms from extracted text
  List<String> _extractSearchTerms(String text) {
    // Clean text and extract potential part numbers/names
    final cleaned = text
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
        .toUpperCase(); // Convert to uppercase for matching

    // Split by common delimiters and newlines
    final terms = cleaned
        .split(RegExp(r'[\s,\n\r\t;|]+'))
        .map((term) => term.trim())
        .where((term) => term.isNotEmpty && term.length >= 2)
        .toList();

    // Also try the full text as a single term (for part numbers with spaces)
    if (cleaned.length >= 3 && !terms.contains(cleaned)) {
      terms.insert(0, cleaned);
    }

    return terms;
  }

  /// Find exact matches against itemname field
  List<TextMatch> _findExactMatches(
      String searchTerm, List<Map<String, dynamic>> partsData) {
    final matches = <TextMatch>[];
    final searchTermUpper = searchTerm.toUpperCase();

    for (final part in partsData) {
      final itemname = part['itemname']?.toString().toUpperCase() ?? '';

      // Exact match against itemname
      if (itemname == searchTermUpper) {
        matches.add(TextMatch(
          text: searchTerm,
          matchType: MatchType.exact,
          matchedPart: itemname,
          confidence: 1.0,
          partData: part, // Store full part data for dialog
        ));
      }
    }

    return matches;
  }

  /// Find partial matches against itemname field (contains, starts with, etc.)
  List<TextMatch> _findPartialMatches(
      String searchTerm, List<Map<String, dynamic>> partsData) {
    final matches = <TextMatch>[];
    final searchTermUpper = searchTerm.toUpperCase();
    final searchTermLength = searchTermUpper.length;

    // Limit to first 10 partial matches to avoid too many results
    int matchCount = 0;
    const maxMatches = 10;

    for (final part in partsData) {
      if (matchCount >= maxMatches) break;

      final itemname = part['itemname']?.toString().toUpperCase() ?? '';
      if (itemname.isEmpty) continue;

      double confidence = 0.0;
      bool isMatch = false;

      // Check if itemname contains the search term
      if (itemname.contains(searchTermUpper)) {
        // Calculate confidence based on how much of the search term matches
        final matchRatio = searchTermLength / itemname.length;
        confidence = (0.6 + (matchRatio * 0.3)).clamp(0.6, 0.9);
        isMatch = true;
      }
      // Check if search term contains itemname (reverse match)
      else if (searchTermUpper.contains(itemname) && itemname.length >= 3) {
        final matchRatio = itemname.length / searchTermLength;
        confidence = (0.6 + (matchRatio * 0.3)).clamp(0.6, 0.9);
        isMatch = true;
      }
      // Check if itemname starts with search term
      else if (itemname.startsWith(searchTermUpper) && searchTermLength >= 3) {
        confidence = 0.75;
        isMatch = true;
      }
      // Check if search term starts with itemname
      else if (searchTermUpper.startsWith(itemname) && itemname.length >= 3) {
        confidence = 0.75;
        isMatch = true;
      }

      if (isMatch) {
        matches.add(TextMatch(
          text: searchTerm,
          matchType: MatchType.partial,
          matchedPart: itemname,
          confidence: confidence,
          partData: part, // Store full part data for reference
        ));
        matchCount++;
      }
    }

    return matches;
  }

  /// Search parts by itemname for global search (returns matching parts)
  Future<List<Map<String, dynamic>>> searchParts(String query) async {
    await _loadPartsData();

    if (_cachedPartsData == null || _cachedPartsData!.isEmpty) {
      return [];
    }

    if (query.trim().isEmpty) {
      return [];
    }

    final queryUpper = query.trim().toUpperCase();
    final results = <Map<String, dynamic>>[];
    const maxResults = 20; // Limit results for dropdown

    for (final part in _cachedPartsData!) {
      if (results.length >= maxResults) break;

      final itemname = part['itemname']?.toString().toUpperCase() ?? '';
      
      // Check for exact match or contains match
      if (itemname.contains(queryUpper) || queryUpper.contains(itemname)) {
        results.add(part);
      }
    }

    return results;
  }

  // ============================================================================
  // COMMENTED OUT: Old API-based matching code with fuzzy matching
  // ============================================================================
  // This code was used for matching against PartsDataService (API-based data)
  // and included fuzzy matching with Levenshtein distance.
  // Keeping it commented for reference, but now using JSON-based exact matching.

  // import 'dart:math';
  // import 'package:get_it/get_it.dart';
  // import '../../../home/data/services/parts_data_service.dart';
  //
  // final PartsDataService _partsDataService = GetIt.instance<PartsDataService>();
  //
  // List<TextMatch> processTextMatches(String extractedText) {
  //   final allParts = _partsDataService.allParts;
  //   final words = _extractWords(extractedText);
  //   final matches = <TextMatch>[];
  //
  //   for (final word in words) {
  //     if (word.length < 3) continue; // Skip very short words
  //
  //     final match = _findBestMatch(word, allParts);
  //     matches.add(match);
  //   }
  //
  //   return matches;
  // }
  //
  // List<String> _extractWords(String text) {
  //   // Clean and split text into words
  //   return text
  //       .toLowerCase()
  //       .replaceAll(RegExp(r'[^\w\s]'), '') // Remove punctuation
  //       .split(RegExp(r'\s+'))
  //       .where((word) => word.isNotEmpty)
  //       .toList();
  // }
  //
  // TextMatch _findBestMatch(String word, List<dynamic> allParts) {
  //   String? bestMatch;
  //   double bestScore = 0.0;
  //   MatchType matchType = MatchType.none;
  //
  //   for (final part in allParts) {
  //     final partName = part.item?.toString().toLowerCase() ?? '';
  //     final partNumber = part.part?.toString().toLowerCase() ?? '';
  //     final brand = part.brand?.toString().toLowerCase() ?? '';
  //     final subCategory = part.subCategory?.toString().toLowerCase() ?? '';
  //
  //     // Check exact matches first
  //     if (partName == word ||
  //         partNumber == word ||
  //         brand == word ||
  //         subCategory == word) {
  //       return TextMatch(
  //         text: word,
  //         matchType: MatchType.exact,
  //         matchedPart: part.item?.toString(),
  //         confidence: 1.0,
  //       );
  //     }
  //
  //     // Check partial matches
  //     final nameScore = _calculateSimilarity(word, partName);
  //     final numberScore = _calculateSimilarity(word, partNumber);
  //     final brandScore = _calculateSimilarity(word, brand);
  //     final subCategoryScore = _calculateSimilarity(word, subCategory);
  //
  //     final maxScore = [
  //       nameScore,
  //       numberScore,
  //       brandScore,
  //       subCategoryScore,
  //     ].reduce(max);
  //
  //     if (maxScore > bestScore && maxScore > 0.6) {
  //       bestScore = maxScore;
  //       bestMatch = part.item?.toString();
  //       matchType = MatchType.partial;
  //     }
  //   }
  //
  //   return TextMatch(
  //     text: word,
  //     matchType: matchType,
  //     matchedPart: bestMatch,
  //     confidence: bestScore,
  //   );
  // }
  //
  // double _calculateSimilarity(String word1, String word2) {
  //   if (word1.isEmpty || word2.isEmpty) return 0.0;
  //
  //   // Check if one contains the other
  //   if (word1.contains(word2) || word2.contains(word1)) {
  //     return 0.8;
  //   }
  //
  //   // Calculate Levenshtein distance
  //   final distance = _levenshteinDistance(word1, word2);
  //   final maxLength = [word1.length, word2.length].reduce(max);
  //
  //   if (maxLength == 0) return 0.0;
  //
  //   return 1.0 - (distance / maxLength);
  // }
  //
  // int _levenshteinDistance(String s1, String s2) {
  //   if (s1.isEmpty) return s2.length;
  //   if (s2.isEmpty) return s1.length;
  //
  //   final matrix = List.generate(
  //     s1.length + 1,
  //     (i) => List.generate(s2.length + 1, (j) => 0),
  //   );
  //
  //   for (int i = 0; i <= s1.length; i++) {
  //     matrix[i][0] = i;
  //   }
  //   for (int j = 0; j <= s2.length; j++) {
  //     matrix[0][j] = j;
  //   }
  //
  //   for (int i = 1; i <= s1.length; i++) {
  //     for (int j = 1; j <= s2.length; j++) {
  //       final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
  //       matrix[i][j] = [
  //         matrix[i - 1][j] + 1, // deletion
  //         matrix[i][j - 1] + 1, // insertion
  //         matrix[i - 1][j - 1] + cost, // substitution
  //       ].reduce(min);
  //     }
  //   }
  //
  //   return matrix[s1.length][s2.length];
  // }
}
