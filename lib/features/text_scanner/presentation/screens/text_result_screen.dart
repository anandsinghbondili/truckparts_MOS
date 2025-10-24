import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/recognized_text.dart';
import '../../domain/entities/text_match.dart';
import '../../data/services/text_match_service.dart';
import '../../../../core/router/app_router.dart';

class TextResultScreen extends StatefulWidget {
  final RecognizedText recognizedText;

  const TextResultScreen({super.key, required this.recognizedText});

  @override
  State<TextResultScreen> createState() => _TextResultScreenState();
}

class _TextResultScreenState extends State<TextResultScreen> {
  late List<TextMatch> _matches;
  late TextMatchService _matchService;

  @override
  void initState() {
    super.initState();
    _matchService = TextMatchService();
    _matches = _matchService.processTextMatches(widget.recognizedText.text);
  }

  List<TextMatch> _getMatchesByType(MatchType type) {
    return _matches.where((match) => match.matchType == type).toList();
  }

  Widget _buildMatchSection(
    BuildContext context,
    String title,
    List<TextMatch> matches,
    IconData icon,
    Color color,
    String callToAction,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${matches.length}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Match Pills
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: matches.map((match) {
            return _buildMatchPill(context, match, color);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMatchPill(BuildContext context, TextMatch match, Color color) {
    final isClickable = match.matchType != MatchType.none;

    return GestureDetector(
      onTap: isClickable ? () => _navigateToSearch(match) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getIconForMatchType(match.matchType),
              size: 18,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              match.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (match.confidence != null &&
                match.matchType == MatchType.partial)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${(match.confidence! * 100).toInt()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForMatchType(MatchType matchType) {
    switch (matchType) {
      case MatchType.exact:
        return Icons.check_circle;
      case MatchType.partial:
        return Icons.search;
      case MatchType.none:
        return Icons.cancel;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (didPop) {
          // Navigation was successful, do nothing
          return;
        }
        // If pop was prevented, handle it manually
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/text-scanner');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Scanned Parts',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              // Use GoRouter's pop to go back to previous screen
              if (context.canPop()) {
                context.pop();
              } else {
                // Fallback: navigate to text scanner if no previous route
                context.go('/text-scanner');
              }
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: () => _copyToClipboard(context),
              tooltip: 'Copy Text',
            ),
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => _shareText(context),
              tooltip: 'Share Text',
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image preview if available (reduced size)
              if (widget.recognizedText.imagePath != null)
                Container(
                  height: 120,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withOpacity(0.3),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/logos/truckparts_logo.png', // Placeholder
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Theme.of(context).colorScheme.surface,
                          child: Icon(
                            Icons.image,
                            size: 48,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.5),
                          ),
                        );
                      },
                    ),
                  ),
                ),

              // Match Pills Section with Categorized Organization
              if (_matches.isNotEmpty) ...[
                Text(
                  'Detected Parts',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),

                // Parts Found Section (Exact Matches)
                if (_getMatchesByType(MatchType.exact).isNotEmpty) ...[
                  _buildMatchSection(
                    context,
                    'Parts Found',
                    _getMatchesByType(MatchType.exact),
                    Icons.check_circle,
                    const Color(0xFF10B981), // Green
                    'Tap to view this part',
                  ),
                  const SizedBox(height: 20),
                ],

                // Possible Matches Section (Partial Matches)
                if (_getMatchesByType(MatchType.partial).isNotEmpty) ...[
                  _buildMatchSection(
                    context,
                    'Possible Matches',
                    _getMatchesByType(MatchType.partial),
                    Icons.warning_amber,
                    const Color(0xFFFACC15), // Orange
                    'Tap to search for this part',
                  ),
                  const SizedBox(height: 20),
                ],

                // Not Recognized Section (No Matches)
                if (_getMatchesByType(MatchType.none).isNotEmpty) ...[
                  _buildMatchSection(
                    context,
                    'Not Recognized',
                    _getMatchesByType(MatchType.none),
                    Icons.cancel,
                    const Color(0xFFEF4444), // Red
                    'Not in database',
                  ),
                  const SizedBox(height: 20),
                ],
              ],

              // Scanned Text Display
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.1),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.text_fields,
                              color: Theme.of(context).primaryColor,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Scanned Text',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).primaryColor,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      // Content
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: SelectableText(
                          widget.recognizedText.text,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                fontSize: 16,
                                height: 1.6,
                                fontWeight: FontWeight.w400,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Add bottom padding to prevent overflow
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToSearch(TextMatch match) {
    final searchQuery = <String, dynamic>{
      'query': match.text,
      'vehicleMake': null,
      'vehicleModel': null,
      'category': null,
      'subCategory': null,
      'type': null,
      'size': null,
    };

    // Add specific filtering based on match type
    if (match.matchType == MatchType.exact) {
      // For exact matches, we can be more specific
      searchQuery['exactMatch'] = true;
    } else if (match.matchType == MatchType.partial) {
      // For partial matches, use fuzzy search
      searchQuery['partialMatch'] = true;
    }

    context.go(AppRouter.searchResults, extra: searchQuery);
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: widget.recognizedText.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Text copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareText(BuildContext context) {
    Share.share(
      widget.recognizedText.text,
      subject: 'Extracted Text from Truck Parts - MOS',
    );
  }
}
