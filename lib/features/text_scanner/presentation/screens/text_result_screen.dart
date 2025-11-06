import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/recognized_text.dart';
import '../../domain/entities/text_match.dart';
import '../../data/services/text_match_service.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../home/domain/entities/part.dart';
import '../../../home/data/models/part_model.dart';
import '../bloc/text_scanner_bloc.dart';
import '../bloc/text_scanner_event.dart';
import '../bloc/text_scanner_state.dart';

class TextResultScreen extends StatefulWidget {
  final RecognizedText recognizedText;

  const TextResultScreen({super.key, required this.recognizedText});

  @override
  State<TextResultScreen> createState() => _TextResultScreenState();
}

class _TextResultScreenState extends State<TextResultScreen> {
  List<TextMatch> _matches = [];
  late TextMatchService _matchService;
  bool _isLoadingMatches = true;

  @override
  void initState() {
    super.initState();
    _matchService = TextMatchService();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    try {
      final matches = await _matchService.processTextMatches(
        widget.recognizedText.text,
      );
      if (mounted) {
        setState(() {
          _matches = matches;
          _isLoadingMatches = false;
        });
      }
    } catch (e) {
      print('❌ Error loading matches: $e');
      if (mounted) {
        setState(() {
          _matches = [];
          _isLoadingMatches = false;
        });
      }
    }
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
    // Only exact matches (green pills) are clickable, partial matches (yellow) are not
    final isClickable = match.matchType == MatchType.exact;

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
            Flexible(
              child: Text(
                match.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
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
    return BlocListener<TextScannerBloc, TextScannerState>(
      listener: (context, state) {
        if (state is TextScannerSuccess) {
          // Navigate to new result screen with new scanned text
          context.push('/text-result', extra: state.recognizedText);
        } else if (state is TextScannerError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
      child: PopScope(
        canPop: true,
        onPopInvoked: (didPop) {
          if (didPop) {
            // Navigation was successful, do nothing
            return;
          }
          // Navigate directly to Home page when back button is pressed
          context.go(AppRouter.home);
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
                // Navigate directly to Home page
                context.go(AppRouter.home);
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
          body: _isLoadingMatches
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
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
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
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
                        if (_getMatchesByType(
                          MatchType.partial,
                        ).isNotEmpty) ...[
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

                      // Scanned Text Display with Intelligence
                      _buildIntelligentScannedTextSection(context),

                      // Add bottom padding for buttons
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
          // Bottom Navigation Buttons
          bottomNavigationBar: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Back Button - Navigate directly to Home page
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.go(AppRouter.home);
                      },
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Re-Scan Button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _rescan(context),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Re-Scan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _rescan(BuildContext context) {
    // Show dialog to choose between camera and gallery
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Re-Scan'),
        content: const Text('Choose an option to scan again'),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<TextScannerBloc>().add(PickImageEvent());
            },
            icon: const Icon(Icons.photo_library),
            label: const Text('Gallery'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<TextScannerBloc>().add(CaptureImageEvent());
            },
            icon: const Icon(Icons.camera_alt),
            label: const Text('Camera'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntelligentScannedTextSection(BuildContext context) {
    final organizedText = _organizeScannedText();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.surface,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
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
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            // Scrollable Content with Intelligence
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: organizedText.isEmpty
                    ? SelectableText(
                        widget.recognizedText.text,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 16,
                          height: 1.6,
                          fontWeight: FontWeight.w400,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: organizedText,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _organizeScannedText() {
    if (_matches.isEmpty) {
      return [];
    }

    final organizedSections = <Widget>[];
    final exactMatches = _getMatchesByType(MatchType.exact);
    final partialMatches = _getMatchesByType(MatchType.partial);
    final noMatches = _getMatchesByType(MatchType.none);

    // Group exact matches by brand or category
    final exactGroups = <String, List<TextMatch>>{};
    for (final match in exactMatches) {
      if (match.partData != null) {
        final brand = match.partData!['Brand']?.toString() ?? 'Unknown';
        final category = match.partData!['category']?.toString() ?? 'Other';
        final key = '$brand - $category';
        exactGroups.putIfAbsent(key, () => []).add(match);
      }
    }

    // Group partial matches by similarity
    final partialGroups = <String, List<TextMatch>>{};
    for (final match in partialMatches) {
      final firstChar = match.text.isNotEmpty
          ? match.text[0].toUpperCase()
          : 'Other';
      partialGroups.putIfAbsent(firstChar, () => []).add(match);
    }

    // Build organized sections
    if (exactGroups.isNotEmpty) {
      organizedSections.add(
        _buildTextSection(
          context,
          'Identified Parts',
          exactGroups.entries
              .map((entry) {
                return entry.value.map((m) => m.text).join(', ');
              })
              .join('\n'),
          Icons.check_circle,
          const Color(0xFF10B981),
        ),
      );
    }

    if (partialGroups.isNotEmpty) {
      organizedSections.add(
        _buildTextSection(
          context,
          'Possible Parts',
          partialGroups.entries
              .map((entry) {
                return entry.value.map((m) => m.text).join(', ');
              })
              .join('\n'),
          Icons.warning_amber,
          const Color(0xFFFACC15),
        ),
      );
    }

    if (noMatches.isNotEmpty) {
      organizedSections.add(
        _buildTextSection(
          context,
          'Other Text',
          noMatches.map((m) => m.text).join(', '),
          Icons.text_fields,
          Colors.grey,
        ),
      );
    }

    // Add remaining text that wasn't matched
    final matchedTexts = _matches.map((m) => m.text.toUpperCase()).toSet();
    final allText = widget.recognizedText.text
        .split(RegExp(r'[\s,\n\r\t;|]+'))
        .where(
          (t) => t.trim().isNotEmpty && !matchedTexts.contains(t.toUpperCase()),
        )
        .join(' ');

    if (allText.trim().isNotEmpty) {
      organizedSections.add(
        _buildTextSection(
          context,
          'Additional Text',
          allText,
          Icons.description,
          Colors.blueGrey,
        ),
      );
    }

    return organizedSections;
  }

  Widget _buildTextSection(
    BuildContext context,
    String title,
    String content,
    IconData icon,
    Color color,
  ) {
    // Split content into readable chunks (by lines, commas, or spaces)
    final textChunks = _formatTextIntoReadableSections(content);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: textChunks.map((chunk) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 6, right: 8),
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Expanded(
                        child: SelectableText(
                          chunk.trim(),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontSize: 14,
                                height: 1.6,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _formatTextIntoReadableSections(String text) {
    if (text.trim().isEmpty) return [];

    // Split by newlines first
    final lines = text
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();
    if (lines.length > 1) {
      return lines;
    }

    // If no newlines, split by commas
    final commaSplit = text
        .split(',')
        .where((part) => part.trim().isNotEmpty)
        .toList();
    if (commaSplit.length > 1) {
      return commaSplit;
    }

    // If single long text, split by spaces into chunks of reasonable length
    final words = text
        .split(' ')
        .where((word) => word.trim().isNotEmpty)
        .toList();
    if (words.length <= 5) {
      return [text];
    }

    // Group words into chunks of 5-7 words
    final chunks = <String>[];
    for (int i = 0; i < words.length; i += 6) {
      final end = (i + 6 < words.length) ? i + 6 : words.length;
      chunks.add(words.sublist(i, end).join(' '));
    }

    return chunks;
  }

  void _navigateToSearch(TextMatch match) {
    // For exact matches, show item details dialog instead of navigating to search
    if (match.matchType == MatchType.exact && match.partData != null) {
      _showItemDetailsDialog(match);
      return;
    }

    // For partial and no matches, navigate to search results
    final searchQuery = <String, dynamic>{
      'query': match.text,
      'vehicleMake': null,
      'vehicleModel': null,
      'category': null,
      'subCategory': null,
      'type': null,
      'size': null,
    };

    if (match.matchType == MatchType.partial) {
      // For partial matches, use fuzzy search
      searchQuery['partialMatch'] = true;
    }

    context.go(AppRouter.searchResults, extra: searchQuery);
  }

  void _showItemDetailsDialog(TextMatch match) {
    if (match.partData == null) return;

    try {
      // Convert JSON data to Part entity
      final part = PartModel.fromApiJson(match.partData!);

      showDialog(
        context: context,
        builder: (context) => _ItemDetailsDialog(
          part: part,
          onAddToCart: (part, quantity) {
            // Only show message, no API functionality
            if (mounted) {
              SnackBarUtils.showSuccess(
                context,
                message: 'Part: ${part.item} (Qty: $quantity) added to cart',
              );
            }
          },
        ),
      );
    } catch (e) {
      print('❌ Error showing item details dialog: $e');
      if (mounted) {
        SnackBarUtils.showError(
          context,
          message: 'Unable to display item details',
        );
      }
    }
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

/// Item Details Dialog for exact matches
class _ItemDetailsDialog extends StatefulWidget {
  final Part part;
  final Function(Part, int) onAddToCart;

  const _ItemDetailsDialog({required this.part, required this.onAddToCart});

  @override
  State<_ItemDetailsDialog> createState() => _ItemDetailsDialogState();
}

class _ItemDetailsDialogState extends State<_ItemDetailsDialog> {
  int _quantity = 1;
  late TextEditingController _quantityController;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: _quantity.toString());
    _focusNode = FocusNode();

    // Listen for focus changes to handle quantity updates
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        final int? parsedQuantity = int.tryParse(_quantityController.text);
        if (parsedQuantity != null &&
            parsedQuantity >= 1 &&
            parsedQuantity <= 999) {
          _updateQuantity(parsedQuantity);
        } else {
          _quantityController.text = _quantity.toString();
        }
      }
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _updateQuantity(int newQuantity) {
    if (newQuantity >= 1 && newQuantity <= 999) {
      setState(() {
        _quantity = newQuantity;
        _quantityController.text = _quantity.toString();
      });
    }
  }

  void _updateQuantityByDelta(int delta) {
    final newQuantity = (_quantity + delta).clamp(1, 999);
    _updateQuantity(newQuantity);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with Close button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Item Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Company Logo
                    Center(
                      child: Container(
                        width: double.infinity,
                        height: 100,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: Image.asset(
                          'assets/logos/shortform.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Item Information
                    _buildInfoRow('Part Number', widget.part.item),
                    if (widget.part.description.isNotEmpty)
                      _buildInfoRow('Description', widget.part.description),
                    if (widget.part.brand.isNotEmpty)
                      _buildInfoRow('Brand', widget.part.brand),
                    if (widget.part.vehicleMake.isNotEmpty)
                      _buildInfoRow('Vehicle Make', widget.part.vehicleMake),
                    if (widget.part.model.isNotEmpty)
                      _buildInfoRow('Vehicle Model', widget.part.model),
                    if (widget.part.category.isNotEmpty)
                      _buildInfoRow('Category', widget.part.category),
                    if (widget.part.subCategory.isNotEmpty)
                      _buildInfoRow('Sub Category', widget.part.subCategory),
                    if (widget.part.type.isNotEmpty)
                      _buildInfoRow('Type', widget.part.type),
                    if (widget.part.size.isNotEmpty)
                      _buildInfoRow('Size', widget.part.size),
                  ],
                ),
              ),
            ),

            // Bottom Action Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                border: Border(top: BorderSide(color: AppTheme.borderColor)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Quantity and Pricing Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quantity Selector with Label Above (LEFT SIDE)
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Quantity',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              height: 40,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppTheme.borderColor,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Decrease Button
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _quantity > 1
                                          ? () => _updateQuantityByDelta(-1)
                                          : null,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(7),
                                        bottomLeft: Radius.circular(7),
                                      ),
                                      child: Container(
                                        width: 36,
                                        height: 40,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: _quantity > 1
                                              ? AppTheme.primaryColor
                                                    .withOpacity(0.05)
                                              : Colors.grey.withOpacity(0.05),
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(7),
                                            bottomLeft: Radius.circular(7),
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.remove,
                                          size: 16,
                                          color: _quantity > 1
                                              ? AppTheme.primaryColor
                                              : AppTheme.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Quantity Input Field
                                  SizedBox(
                                    width: 50,
                                    height: 40,
                                    child: TextField(
                                      controller: _quantityController,
                                      focusNode: _focusNode,
                                      textAlign: TextAlign.center,
                                      keyboardType: TextInputType.number,
                                      textInputAction: TextInputAction.done,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                      ),
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(
                                          borderSide: BorderSide.none,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide.none,
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide.none,
                                        ),
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      onSubmitted: (value) {
                                        final int? parsedQuantity =
                                            int.tryParse(value);
                                        if (parsedQuantity != null &&
                                            parsedQuantity >= 1 &&
                                            parsedQuantity <= 999) {
                                          _updateQuantity(parsedQuantity);
                                        } else {
                                          _quantityController.text = _quantity
                                              .toString();
                                        }
                                        _focusNode.unfocus();
                                      },
                                      onTap: () {
                                        _quantityController
                                            .selection = TextSelection(
                                          baseOffset: 0,
                                          extentOffset:
                                              _quantityController.text.length,
                                        );
                                      },
                                    ),
                                  ),

                                  // Increase Button
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => _updateQuantityByDelta(1),
                                      borderRadius: const BorderRadius.only(
                                        topRight: Radius.circular(7),
                                        bottomRight: Radius.circular(7),
                                      ),
                                      child: Container(
                                        width: 36,
                                        height: 40,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor
                                              .withOpacity(0.05),
                                          borderRadius: const BorderRadius.only(
                                            topRight: Radius.circular(7),
                                            bottomRight: Radius.circular(7),
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.add,
                                          size: 16,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 16),

                      // MRP and Net Price (RIGHT SIDE)
                      if (widget.part.mrp != null)
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // MRP
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'MRP',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    PriceFormatter.formatPriceWithCurrency(
                                      widget.part.mrp,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Net Price
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Net Price',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    PriceFormatter.formatPriceWithCurrency(
                                      widget.part.netPrice ?? widget.part.mrp,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF00A000),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Action Buttons - Cancel and Add to Cart
                  Row(
                    children: [
                      // Cancel Button
                      Expanded(
                        flex: 2,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.errorColor,
                            side: BorderSide(color: AppTheme.errorColor),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.close_outlined, size: 18),
                              SizedBox(width: 6),
                              Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Add to Cart Button
                      Expanded(
                        flex: 3,
                        child: ElevatedButton(
                          onPressed: () {
                            widget.onAddToCart(widget.part, _quantity);
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.shopping_cart_outlined, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Add to Cart',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
