import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/price_formatter.dart';
import '../../features/home/domain/entities/part.dart';

class AutocompleteSearchBar extends StatefulWidget {
  final TextEditingController searchController;
  final List<Part> allParts;
  final Function(String) onSearchSubmitted;
  final Function(Part) onSuggestionSelected;
  final String hintText;
  final bool showClearButton;

  const AutocompleteSearchBar({
    super.key,
    required this.searchController,
    required this.allParts,
    required this.onSearchSubmitted,
    required this.onSuggestionSelected,
    this.hintText = 'Search parts by name, ID, category, brand...',
    this.showClearButton = true,
  });

  @override
  State<AutocompleteSearchBar> createState() => _AutocompleteSearchBarState();
}

class _AutocompleteSearchBarState extends State<AutocompleteSearchBar> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  final FocusNode _focusNode = FocusNode();
  List<Part> _suggestions = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    widget.searchController.addListener(_onSearchChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.searchController.removeListener(_onSearchChanged);
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = widget.searchController.text.trim();

    if (query.isEmpty) {
      _removeOverlay();
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    // Get matching suggestions
    final suggestions = _getMatchingSuggestions(query);

    setState(() {
      _suggestions = suggestions;
      _showSuggestions = suggestions.isNotEmpty;
    });

    if (_showSuggestions) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      // Delay to allow tap on suggestions
      Future.delayed(const Duration(milliseconds: 200), () {
        _removeOverlay();
      });
    }
  }

  List<Part> _getMatchingSuggestions(String query) {
    final lowerQuery = query.toLowerCase();

    // Filter parts that match the query
    final matches = widget.allParts.where((part) {
      return (part.item.toLowerCase().contains(lowerQuery)) ||
          (part.id.toLowerCase().contains(lowerQuery)) ||
          (part.brand.toLowerCase().contains(lowerQuery)) ||
          (part.category.toLowerCase().contains(lowerQuery)) ||
          (part.description.toLowerCase().contains(lowerQuery)) ||
          (part.vehicleMake.toLowerCase().contains(lowerQuery)) ||
          (part.model.toLowerCase().contains(lowerQuery)) ||
          (part.size.toLowerCase().contains(lowerQuery));
    }).toList();

    // Limit to 10 suggestions
    return matches.take(10).toList();
  }

  void _showOverlay() {
    _removeOverlay();

    // Get the full width and subtract the horizontal padding (16px on each side)
    final searchBarWidth = _getSearchBarWidth();
    final textFieldWidth = searchBarWidth - 32; // Subtract horizontal padding

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: textFieldWidth,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(
            16,
            60,
          ), // 16px from left for padding, 60px below
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: textFieldWidth,
              constraints: const BoxConstraints(maxHeight: 300),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                shrinkWrap: true,
                itemCount: _suggestions.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final suggestion = _suggestions[index];
                  return _buildSuggestionItem(suggestion);
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  double _getSearchBarWidth() {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    return renderBox?.size.width ?? 300;
  }

  Widget _buildSuggestionItem(Part part) {
    return InkWell(
      onTap: () {
        _removeOverlay();
        widget.onSuggestionSelected(part);
        _focusNode.unfocus();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Part Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Part Name
                  Text(
                    part.item,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Brand
                  if (part.brand.isNotEmpty)
                    Text(
                      part.brand,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Price
            Text(
              PriceFormatter.formatPriceWithCurrency(part.price),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00A000), // Darker, more vibrant green
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: widget.searchController,
          focusNode: _focusNode,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixIcon: Icon(Icons.search, color: AppTheme.primaryColor),
            suffixIcon:
                widget.showClearButton &&
                    widget.searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      widget.searchController.clear();
                      _removeOverlay();
                    },
                  )
                : null,
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.borderColor, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              _removeOverlay();
              widget.onSearchSubmitted(value.trim());
              _focusNode.unfocus();
            }
          },
        ),
      ),
    );
  }
}
