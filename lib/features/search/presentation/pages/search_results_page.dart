import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/navigation_utils.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/router/app_router.dart';
import '../../../../features/home/domain/entities/part.dart';
import '../../../../features/home/data/services/parts_service.dart';
import '../../../cart/data/services/cart_service.dart';
import '../../../home/presentation/widgets/filter_buttons_section.dart';
import '../../../home/presentation/widgets/vehicle_selection_dialog.dart';
import '../../../home/presentation/widgets/category_selection_dialog.dart';
import '../../../home/presentation/widgets/type_size_selection_dialog.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../text_scanner/domain/entities/text_match.dart';
import '../../../text_scanner/presentation/widgets/match_pill.dart';

class SearchResultsPage extends StatefulWidget {
  final Map<String, dynamic> searchQuery;

  const SearchResultsPage({super.key, required this.searchQuery});

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  List<String> _activeFilters = [];
  List<Part> _searchResults = [];

  // Filter state variables
  String? _selectedVehicleMake;
  String? _selectedVehicleModel;
  String? _selectedCategory;
  String? _selectedSubCategory;
  String? _selectedType;
  String? _selectedSize;
  String? _validationError;

  // Global edit mode tracking
  bool _isAnyItemBeingEdited = false;

  // ✅ NEW: Filter completion tracking (same as home_page)
  bool _isVehicleMakeSelected = false;
  bool _isVehicleModelSelected = false;
  bool _isSubCategorySelected = false;
  bool _isTypeSelected = false;
  bool _isSizeSelected = false;

  // ✅ NEW: Empty filter lists indicators
  bool _isTypeEmpty = false;
  bool _isSizeEmpty = false;

  @override
  void initState() {
    super.initState();
    _loadSearchResults();
    _buildActiveFilters();
    _updateFilterCompletionStatus(); // ✅ NEW: Initialize filter state
  }

  // ✅ NEW: Check if a filter should be enabled
  bool _isFilterEnabled(String filterName) {
    switch (filterName) {
      case 'vehicleModel':
        return _isVehicleMakeSelected;
      case 'subCategory':
        return _isVehicleModelSelected;
      case 'type':
        return _isSubCategorySelected;
      case 'size':
        return _isTypeSelected;
      default:
        return true;
    }
  }

  // ✅ NEW: Check if all filters are complete
  bool _areFiltersComplete() {
    return _isVehicleMakeSelected &&
        _isVehicleModelSelected &&
        _isSubCategorySelected &&
        _isTypeSelected &&
        _isSizeSelected;
  }

  // ✅ NEW: Update filter completion status
  void _updateFilterCompletionStatus() {
    print('🔍 Filter State Update (Search Results):');
    print(
      '   - Make: $_selectedVehicleMake (enabled: $_isVehicleMakeSelected)',
    );
    print(
      '   - Model: $_selectedVehicleModel (enabled: $_isVehicleModelSelected)',
    );
    print(
      '   - Part: $_selectedSubCategory (enabled: $_isSubCategorySelected)',
    );
    print('   - Type: $_selectedType (enabled: $_isTypeSelected)');
    print('   - Size: $_selectedSize (enabled: $_isSizeSelected)');
    print('   - Complete: ${_areFiltersComplete()}');

    setState(() {
      _isVehicleMakeSelected = _selectedVehicleMake != null;
      _isVehicleModelSelected = _selectedVehicleModel != null;
      _isSubCategorySelected = _selectedSubCategory != null;
      _isTypeSelected = _selectedType != null || _isTypeEmpty;
      _isSizeSelected = _selectedSize != null || _isSizeEmpty;
    });
  }

  // ✅ NEW: Reset dependent filters when a filter changes
  void _resetDependentFilters(String changedFilter) {
    switch (changedFilter) {
      case 'make':
        _selectedVehicleModel = null;
        _selectedSubCategory = null;
        _selectedType = null;
        _selectedSize = null;
        _isTypeEmpty = false;
        _isSizeEmpty = false;
        break;
      case 'model':
        _selectedSubCategory = null;
        _selectedType = null;
        _selectedSize = null;
        _isTypeEmpty = false;
        _isSizeEmpty = false;
        break;
      case 'part':
        _selectedType = null;
        _selectedSize = null;
        _isTypeEmpty = false;
        _isSizeEmpty = false;
        break;
      case 'type':
        _selectedSize = null;
        _isSizeEmpty = false;
        break;
    }
  }

  // ✅ NEW: Reset all filters
  void _resetAllFilters() {
    setState(() {
      _selectedVehicleMake = null;
      _selectedVehicleModel = null;
      _selectedSubCategory = null;
      _selectedType = null;
      _selectedSize = null;
      _isTypeEmpty = false;
      _isSizeEmpty = false;
      _validationError = null;
      _updateFilterCompletionStatus();
    });
    SnackBarUtils.showInfo(context, message: 'All filters reset');
  }

  // Check if search was triggered by brand selection
  bool get _isBrandSearch =>
      widget.searchQuery['brand'] != null &&
      widget.searchQuery['brand'].toString().isNotEmpty;

  Future<void> _loadSearchResults() async {
    try {
      print('');
      print('═══════════════════════════════════════════════════════');
      print('🔄 LOADING SEARCH RESULTS');
      print('═══════════════════════════════════════════════════════');
      print('📥 Search Query Parameters:');
      print('   - query: ${widget.searchQuery['query']}');
      print('   - vehicleMake: ${widget.searchQuery['vehicleMake']}');
      print('   - vehicleModel: ${widget.searchQuery['vehicleModel']}');
      print('   - category: ${widget.searchQuery['category']}');
      print('   - subCategory: ${widget.searchQuery['subCategory']}');
      print('   - type: ${widget.searchQuery['type']}');
      print('   - size: ${widget.searchQuery['size']}');
      print('   - brand: ${widget.searchQuery['brand']}');
      print('');
      print('🌐 Calling PartsService.searchParts()...');

      final results = await PartsService.searchParts(
        query: widget.searchQuery['query'] as String?,
        vehicleMake: widget.searchQuery['vehicleMake'] as String?,
        vehicleModel: widget.searchQuery['vehicleModel'] as String?,
        category: widget.searchQuery['category'] as String?,
        subCategory: widget.searchQuery['subCategory'] as String?,
        type: widget.searchQuery['type'] as String?,
        size: widget.searchQuery['size'] as String?,
        brand: widget.searchQuery['brand'] as String?,
      );

      print('✅ Search completed successfully!');
      print('   - Results count: ${results.length}');
      if (results.isNotEmpty) {
        print('   - First result: ${results.first.item}');
      }
      print('═══════════════════════════════════════════════════════');
      print('');

      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      print('');
      print('❌ SEARCH FAILED');
      print('   Error: $e');
      print('═══════════════════════════════════════════════════════');
      print('');

      setState(() {
        _searchResults = [];
      });

      if (mounted) {
        ErrorHandler.handleError(
          context: context,
          error: e,
          customTitle: 'Search Failed',
          customMessage: 'Unable to load search results. Please try again.',
          actionButtonText: 'Retry',
          onActionPressed: _loadSearchResults,
        );
      }
    }
  }

  void _buildActiveFilters() {
    _activeFilters = [];
    // Separate pills for Make and Model
    if (widget.searchQuery['vehicleMake'] != null) {
      _activeFilters.add(widget.searchQuery['vehicleMake']!);
    }
    if (widget.searchQuery['vehicleModel'] != null) {
      _activeFilters.add(widget.searchQuery['vehicleModel']!);
    }
    if (widget.searchQuery['category'] != null) {
      _activeFilters.add(widget.searchQuery['category']);
    }
    if (widget.searchQuery['subCategory'] != null) {
      _activeFilters.add(widget.searchQuery['subCategory']);
    }
    if (widget.searchQuery['type'] != null) {
      _activeFilters.add(widget.searchQuery['type']);
    }
    if (widget.searchQuery['size'] != null) {
      _activeFilters.add(widget.searchQuery['size']);
    }
    if (widget.searchQuery['brand'] != null) {
      _activeFilters.add('Brand: ${widget.searchQuery['brand']}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset:
          true, // ✅ Allow resizing when keyboard opens to show buttons above keyboard
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              NavigationUtils.safePop(context, fallbackRoute: AppRouter.home),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search, size: 24),
            const SizedBox(width: 8),
            const Text('Search Results'),
          ],
        ),
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        actions: [
          Consumer<CartService>(
            builder: (context, cartService, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart, size: 26),
                    onPressed: () => context.push(AppRouter.cart),
                  ),
                  if (cartService.itemCount > 0)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Text(
                        '${cartService.itemCount}',
                        style: const TextStyle(
                          color: AppTheme.secondaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          // Company Logo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
            child: Image.asset(
              'assets/logos/shortform.png',
              fit: BoxFit.contain,
              height: 24,
            ),
          ),
        ],
      ),
      body: _buildKeyboardAwareBody(),
    );
  }

  Widget _buildKeyboardAwareBody() {
    return Column(
      children: [
        // Active Filter Pills
        if (_activeFilters.isNotEmpty) _buildActiveFiltersSection(),

        // Filter Section - Only show when brand search
        if (_isBrandSearch) _buildFilterSection(),

        // Search Results - Will automatically adjust when keyboard appears
        Expanded(
          child: _searchResults.isEmpty
              ? _buildEmptyState()
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.6,
                  ),
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final part = _searchResults[index];
                    return _ProductCard(
                      part: part,
                      onAddToCart: _addToCart,
                      onEditModeChanged: _onEditModeChanged,
                    );
                  },
                ),
        ),

        // Footer - Will automatically position above keyboard
        _buildKeyboardAwareFooter(),
      ],
    );
  }

  Widget _buildActiveFiltersSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: AppTheme.backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Active Filters:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              // Show the pill that triggered this search if it's from text scanner
              if (_isFromTextScanner()) _buildTextScannerPill(),
              // Show other active filters
              ..._activeFilters
                  .map((filter) => _buildFilterChip(filter))
                  .toList(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filter) {
    return Chip(
      label: Text(
        filter,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: AppTheme.primaryColor,
      labelPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.5), width: 1),
      shadowColor: AppTheme.primaryColor.withOpacity(0.3),
      elevation: 2,
    );
  }

  bool _isFromTextScanner() {
    return widget.searchQuery.containsKey('exactMatch') ||
        widget.searchQuery.containsKey('partialMatch');
  }

  Widget _buildTextScannerPill() {
    final query = widget.searchQuery['query'] as String? ?? '';
    final isExactMatch = widget.searchQuery['exactMatch'] == true;
    final isPartialMatch = widget.searchQuery['partialMatch'] == true;

    MatchType matchType;
    if (isExactMatch) {
      matchType = MatchType.exact;
    } else if (isPartialMatch) {
      matchType = MatchType.partial;
    } else {
      matchType = MatchType.none;
    }

    final textMatch = TextMatch(
      text: query,
      matchType: matchType,
      matchedPart: query,
      confidence: isPartialMatch ? 0.8 : 1.0,
    );

    return MatchPill(
      match: textMatch,
      onTap: null, // Non-clickable as it's already showing the results
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No parts found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search criteria',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.normal,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go(AppRouter.home),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.home_outlined, size: 18),
                SizedBox(width: 8),
                Text('Back to Home'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      color: AppTheme.backgroundColor,
      child: Column(
        children: [
          // Filter Buttons Section with integrated action buttons
          FilterButtonsSection(
            selectedVehicleMake: _selectedVehicleMake,
            selectedVehicleModel: _selectedVehicleModel,
            selectedSubCategory: _selectedSubCategory,
            selectedType: _selectedType,
            selectedSize: _selectedSize,
            // ✅ NEW: Pass filter state (same as home_page)
            isVehicleMakeSelected: _isVehicleMakeSelected,
            isVehicleModelSelected: _isVehicleModelSelected,
            isSubCategorySelected: _isSubCategorySelected,
            isTypeSelected: _isTypeSelected,
            isSizeSelected: _isSizeSelected,
            onVehicleSelected: _showVehicleDialog,
            onCategorySelected: _showCategoryDialog,
            onSizeSelected: _showSizeDialog,
            onSearch: _performFilterSearch,
            onReset: _resetFilters,
          ),

          // Validation Error Message
          if (_validationError != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                _validationError!,
                style: const TextStyle(
                  color: AppTheme.errorColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildKeyboardAwareFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: _isAnyItemBeingEdited
          ? _buildEditModeButtons()
          : Center(
              child: Image.asset(
                'assets/logos/truckparts_slogan.png',
                fit: BoxFit.contain,
                height: 40,
              ),
            ),
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: _isAnyItemBeingEdited
          ? _buildEditModeButtons()
          : Center(
              child: Image.asset(
                'assets/logos/truckparts_slogan.png',
                fit: BoxFit.contain,
                height: 40,
              ),
            ),
    );
  }

  Widget _buildEditModeButtons() {
    return Row(
      children: [
        // Cancel Button
        Expanded(
          flex: 2,
          child: OutlinedButton(
            onPressed: _globalCancelEditing,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
              side: BorderSide(color: AppTheme.errorColor),
              padding: const EdgeInsets.symmetric(vertical: 16),
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
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 12),

        // OK Button
        Expanded(
          flex: 3,
          child: ElevatedButton(
            onPressed: _globalConfirmEditing,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_outlined, size: 20),
                SizedBox(width: 8),
                Text(
                  'OK',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _addToCart(Part part, int quantity) async {
    final cartService = Provider.of<CartService>(context, listen: false);

    // Check if item already exists in cart for smart merge feedback
    final existingItemIndex = cartService.cartItems.indexWhere(
      (item) => item.part.id == part.id,
    );

    String message;
    if (existingItemIndex != -1) {
      final existingItem = cartService.cartItems[existingItemIndex];
      final cartQuantity = existingItem.quantity;
      if (cartQuantity < quantity) {
        message = '${part.displayName} quantity updated to $quantity';
      } else {
        message =
            '${part.displayName} quantity unchanged (cart has $cartQuantity)';
      }
    } else {
      message = '${part.displayName} added to cart';
    }

    await cartService.addToCart(part, quantity);

    SnackBarUtils.showSuccess(
      context,
      message: message,
      action: SnackBarAction(
        label: 'View Cart',
        textColor: Colors.white,
        onPressed: () => context.push(AppRouter.cart),
      ),
    );
  }

  // Global edit mode management
  void _onEditModeChanged(bool isEditing) {
    setState(() {
      _isAnyItemBeingEdited = isEditing;
    });
  }

  void _globalCancelEditing() {
    // Unfocus all inputs
    FocusScope.of(context).unfocus();
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _isAnyItemBeingEdited = false;
    });
  }

  void _globalConfirmEditing() {
    // Unfocus all inputs
    FocusScope.of(context).unfocus();
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _isAnyItemBeingEdited = false;
    });
  }

  // Filter methods
  void _showVehicleDialog() {
    print('');
    print('🚗 Opening Vehicle Dialog - Search Results Page');
    print('   Current State:');
    print('   - Selected Make: $_selectedVehicleMake');
    print('   - Selected Model: $_selectedVehicleModel');

    String? previousMake = _selectedVehicleMake;

    VehicleSelectionDialog.show(
      context: context,
      selectedVehicleMake: _selectedVehicleMake,
      selectedVehicleModel: _selectedVehicleModel,
      onVehicleSelected: (make, model) {
        print('');
        print('✅ Vehicle Selected:');
        print('   - Make: $make');
        print('   - Model: $model');

        setState(() {
          // ✅ NEW: Reset dependents if make changed
          if (make != previousMake) {
            print(
              '🔄 Vehicle Make changed from "$previousMake" to "$make" - Cascading reset',
            );
            _resetDependentFilters('make');
          } else if (model != _selectedVehicleModel) {
            print('🔄 Vehicle Model changed - Resetting dependent filters');
            _resetDependentFilters('model');
          }

          _selectedVehicleMake = make;
          _selectedVehicleModel = model;
          _validationError = null;
          _updateFilterCompletionStatus();
        });
      },
      selectedSubCategory: _selectedSubCategory,
      selectedSize: _selectedSize,
    );
  }

  void _showCategoryDialog() {
    // ✅ NEW: Check if Vehicle selection is complete
    if (!_isVehicleModelSelected) {
      setState(() {
        _validationError = 'Please select a Vehicle first';
      });
      SnackBarUtils.showWarning(
        context,
        message: 'Please select Vehicle Make and Model first',
      );
      return;
    }

    print('');
    print('📦 Opening Part Dialog - Search Results Page');
    print('   Current State:');
    print('   - Current Make: $_selectedVehicleMake');
    print('   - Current Model: $_selectedVehicleModel');

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (context) => CategorySelectionDialog(
        selectedSubCategory: _selectedSubCategory,
        onSubCategorySelected: (subCategory) {
          print('');
          print('✅ Part Selected:');
          print('   - SubCategory: $subCategory');

          setState(() {
            // ✅ NEW: Reset dependent filters if part changed
            if (subCategory != _selectedSubCategory) {
              print('🔄 Part changed - Resetting dependent filters');
              _resetDependentFilters('part');
            }

            _selectedSubCategory = subCategory;
            _selectedCategory = null;
            _validationError = null;
            _updateFilterCompletionStatus();
          });
        },
        selectedVehicleMake: _selectedVehicleMake,
        selectedVehicleModel: _selectedVehicleModel,
        selectedSize: _selectedSize,
      ),
    );
  }

  void _showSizeDialog() {
    // ✅ NEW: Check if Part selection is complete
    if (!_isSubCategorySelected) {
      setState(() {
        _validationError = 'Please select a Part first';
      });
      SnackBarUtils.showWarning(context, message: 'Please select a Part first');
      return;
    }

    print('');
    print('📏 Opening Type/Size Dialog - Search Results Page');
    print('   Current State:');
    print('   - Current Make: $_selectedVehicleMake');
    print('   - Current Model: $_selectedVehicleModel');
    print('   - Current Part: $_selectedSubCategory');

    TypeSizeSelectionDialog.show(
      context: context,
      selectedType: _selectedType,
      selectedSize: _selectedSize,
      onTypeSizeSelected: (type, size) {
        print('');
        print('✅ Type/Size Selected:');
        print('   - Type: $type');
        print('   - Size: $size');

        setState(() {
          _selectedType = type;
          _selectedSize = size;

          // ✅ NEW: Update empty flags for "Any" option
          _isTypeEmpty = type == 'Any';
          _isSizeEmpty = size == 'Any';

          _updateFilterCompletionStatus();
        });
      },
      selectedVehicleMake: _selectedVehicleMake,
      selectedVehicleModel: _selectedVehicleModel,
      selectedSubCategory: _selectedSubCategory,
    );
  }

  Future<void> _performFilterSearch() async {
    print('');
    print('═══════════════════════════════════════════════════════');
    print('🔍 SEARCH BUTTON CLICKED - Search Results Page');
    print('═══════════════════════════════════════════════════════');

    // ✅ NEW: Check if all filters are complete
    if (!_areFiltersComplete()) {
      setState(() {
        _validationError = 'Please complete all filter selections';
      });
      SnackBarUtils.showWarning(
        context,
        message: 'Please select: Vehicle Make → Model → Part → Type → Size',
      );
      print('❌ VALIDATION FAILED: Not all filters complete');
      return;
    }

    // Clear previous validation error
    setState(() {
      _validationError = null;
    });

    print('📋 Current Filter State:');
    print('   - Vehicle Make: $_selectedVehicleMake');
    print('   - Vehicle Model: $_selectedVehicleModel');
    print('   - SubCategory (Part): $_selectedSubCategory');
    print('   - Type: $_selectedType');
    print('   - Size: $_selectedSize');
    print('   - Existing Brand: ${widget.searchQuery['brand']}');
    print('');

    print('✅ VALIDATION PASSED - All filters complete');
    print('');

    try {
      print('🌐 Calling PartsService.searchParts() with filters...');

      // Search with combined filters
      final results = await PartsService.searchParts(
        query: null,
        vehicleMake: _selectedVehicleMake,
        vehicleModel: _selectedVehicleModel,
        category: _selectedCategory,
        subCategory: _selectedSubCategory,
        type: _selectedType,
        size: _selectedSize,
        brand: widget.searchQuery['brand'], // Keep existing brand filter
      );

      print('✅ Search completed successfully!');
      print('   - Results count: ${results.length}');
      if (results.isNotEmpty) {
        print('   - First result: ${results.first.item}');
      }

      // Update internal searchQuery for active filters
      widget.searchQuery['vehicleMake'] = _selectedVehicleMake;
      widget.searchQuery['vehicleModel'] = _selectedVehicleModel;
      widget.searchQuery['category'] = _selectedCategory;
      widget.searchQuery['subCategory'] = _selectedSubCategory;
      widget.searchQuery['type'] = _selectedType;
      widget.searchQuery['size'] = _selectedSize;

      // Rebuild active filters with new selections
      _buildActiveFilters();

      setState(() {
        _searchResults = results;
      });

      print('🔄 Updated search results and active filters on same page');
      print('═══════════════════════════════════════════════════════');
      print('');
    } catch (e) {
      print('❌ SEARCH FAILED');
      print('   Error: $e');
      print('═══════════════════════════════════════════════════════');
      print('');

      if (mounted) {
        ErrorHandler.handleError(
          context: context,
          error: e,
          customTitle: 'Search Failed',
          customMessage: 'Unable to apply filters. Please try again.',
          actionButtonText: 'Retry',
          onActionPressed: _performFilterSearch,
        );
      }
    }
  }

  Future<void> _resetFilters() async {
    print('');
    print('🔄 RESET BUTTON CLICKED - Search Results Page');
    print('   Clearing all filters except brand...');
    print('   - Preserving Brand: ${widget.searchQuery['brand']}');

    // Clear local filter selections
    _selectedVehicleMake = null;
    _selectedVehicleModel = null;
    _selectedCategory = null;
    _selectedSubCategory = null;
    _selectedType = null;
    _selectedSize = null;
    _validationError = null;
    _isTypeEmpty = false; // ✅ Reset empty indicator
    _isSizeEmpty = false; // ✅ Reset empty indicator

    // Update internal searchQuery to clear filters but keep brand
    widget.searchQuery['vehicleMake'] = null;
    widget.searchQuery['vehicleModel'] = null;
    widget.searchQuery['category'] = null;
    widget.searchQuery['subCategory'] = null;
    widget.searchQuery['type'] = null;
    widget.searchQuery['size'] = null;

    // Rebuild active filters
    _buildActiveFilters();

    // ✅ NEW: Update filter completion status
    _updateFilterCompletionStatus();

    print('🌐 Reloading with brand filter only...');

    setState(() {}); // Trigger rebuild

    // Reload search results with only brand filter
    await _loadSearchResults();

    print('✅ Filters reset, showing brand results only');
    print('');
  }
}

class _ProductCard extends StatefulWidget {
  final Part part;
  final Function(Part, int) onAddToCart;
  final Function(bool)? onEditModeChanged;

  const _ProductCard({
    required this.part,
    required this.onAddToCart,
    this.onEditModeChanged,
  });

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  int _quantity = 1;
  final TextEditingController _quantityController = TextEditingController();
  final FocusNode _quantityFocusNode = FocusNode();

  // Edit mode tracking
  bool _isEditing = false;
  int _editingQuantity = 0;

  @override
  void initState() {
    super.initState();
    _quantityController.text = _quantity.toString();

    // Listen for focus changes to handle quantity updates
    _quantityFocusNode.addListener(() {
      if (_quantityFocusNode.hasFocus) {
        // User started editing, enter edit mode
        if (!_isEditing) {
          setState(() {
            _isEditing = true;
            _editingQuantity = _quantity;
          });
          // Notify parent about edit mode change
          widget.onEditModeChanged?.call(true);
        }
      } else if (_isEditing) {
        // User finished editing, validate and update quantity
        final int? parsedQuantity = int.tryParse(_quantityController.text);
        if (parsedQuantity != null && parsedQuantity >= 1) {
          _updateQuantity(parsedQuantity);
        } else {
          // Reset to current quantity if invalid
          _quantityController.text = _quantity.toString();
        }
        setState(() {
          _isEditing = false;
        });
        // Notify parent about edit mode change
        widget.onEditModeChanged?.call(false);
      }
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _quantityFocusNode.dispose();
    super.dispose();
  }

  void _updateQuantity(int newQuantity) {
    if (newQuantity >= 1) {
      setState(() {
        _quantity = newQuantity;
        _quantityController.text = _quantity.toString();
      });
    }
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
      _editingQuantity = _quantity;
    });
    _quantityFocusNode.requestFocus();
    // Focus listener will handle notifying parent
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _quantity = _editingQuantity;
      _quantityController.text = _quantity.toString();
    });
    _quantityFocusNode.unfocus();
    // Focus listener will handle notifying parent
  }

  void _confirmEditing() {
    final int? parsedQuantity = int.tryParse(_quantityController.text);
    if (parsedQuantity != null &&
        parsedQuantity >= 1 &&
        parsedQuantity <= 999) {
      setState(() {
        _isEditing = false;
        _quantity = parsedQuantity;
        _quantityController.text = _quantity.toString();
      });
    } else {
      // Reset to current quantity if invalid
      setState(() {
        _isEditing = false;
        _quantityController.text = _quantity.toString();
      });
    }
    _quantityFocusNode.unfocus();
    // Focus listener will handle notifying parent
  }

  void _onQuantityTextChanged(String value) {
    // Allow empty string during editing
    if (value.isEmpty) return;

    final int? parsedQuantity = int.tryParse(value);
    if (parsedQuantity != null &&
        parsedQuantity >= 1 &&
        parsedQuantity <= 999) {
      setState(() {
        _quantity = parsedQuantity;
      });
    }
  }

  void _showItemDetails() {
    showDialog(
      context: context,
      builder: (context) => _ItemDetailsDialog(
        part: widget.part,
        onAddToCart: widget.onAddToCart,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: _showItemDetails,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image Placeholder
              Container(
                width: double.infinity,
                height: 70,
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Image.asset(
                    'assets/logos/shortform.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 4),

              // Product Details Section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Product Name - Limited to 1 line to prevent overflow
                    Text(
                      widget.part.item,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                    const SizedBox(height: 3),

                    // Brand - Limited to 1 line
                    if (widget.part.brand.isNotEmpty)
                      Text(
                        widget.part.brand,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                      ),
                    if (widget.part.brand.isNotEmpty) const SizedBox(height: 2),

                    // Size - Limited to 1 line
                    if (widget.part.size.isNotEmpty)
                      Text(
                        'Size: ${widget.part.size}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                      ),

                    const Spacer(),

                    // Pricing Section - MRP and Net Price
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // MRP (List Price)
                        if (widget.part.mrp != null)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'MRP:',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  PriceFormatter.formatPriceWithCurrency(
                                    widget.part.mrp,
                                  ),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                    // Strikethrough if net price exists and is different
                                    decoration:
                                        widget.part.netPrice != null &&
                                            widget.part.netPrice !=
                                                widget.part.mrp
                                        ? TextDecoration.lineThrough
                                        : null,
                                    decorationColor: AppTheme.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        if (widget.part.mrp != null) const SizedBox(height: 4),

                        // Net Price
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Net Price:',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Flexible(
                              child: Text(
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
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),

                        // Fallback - show price if no MRP at all
                        if (widget.part.mrp == null &&
                            widget.part.price != null)
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              PriceFormatter.formatPriceWithCurrency(
                                widget.part.price,
                              ),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF00A000),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),

              // Quantity Selector
              _buildQuantitySelector(),
              const SizedBox(height: 4),

              // Add to Cart Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => widget.onAddToCart(widget.part, _quantity),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Add to Cart',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Decrease Button
          SizedBox(
            width: 36,
            height: 36,
            child: IconButton(
              icon: const Icon(Icons.remove, size: 16),
              onPressed: _quantity > 1
                  ? () => _updateQuantity(_quantity - 1)
                  : null,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              color: _quantity > 1
                  ? AppTheme.primaryColor
                  : AppTheme.textSecondary,
            ),
          ),

          // Quantity Display/Input
          Expanded(
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: TextField(
                controller: _quantityController,
                focusNode: _quantityFocusNode,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                textInputAction:
                    TextInputAction.done, // ✅ Ensures iOS shows "Done" button
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide.none,
                  ),
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: _onQuantityTextChanged,
                onTap: () {
                  // Select all text when tapped for easy editing
                  _quantityController.selection = TextSelection(
                    baseOffset: 0,
                    extentOffset: _quantityController.text.length,
                  );
                },
                onSubmitted: (value) {
                  final int? parsedQuantity = int.tryParse(value);
                  if (parsedQuantity != null && parsedQuantity >= 1) {
                    _updateQuantity(parsedQuantity);
                  } else {
                    _quantityController.text = _quantity.toString();
                  }
                  // Unfocus after submission
                  _quantityFocusNode.unfocus();
                },
              ),
            ),
          ),

          // Increase Button
          SizedBox(
            width: 36,
            height: 36,
            child: IconButton(
              icon: const Icon(Icons.add, size: 16),
              onPressed: () => _updateQuantity(_quantity + 1),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Detailed Item Dialog with complete information
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
        // User finished editing, validate and update quantity
        final int? parsedQuantity = int.tryParse(_quantityController.text);
        if (parsedQuantity != null &&
            parsedQuantity >= 1 &&
            parsedQuantity <= 999) {
          _updateQuantity(parsedQuantity);
        } else {
          // Reset to current quantity if invalid
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
                                        // Select all text when tapped for easy editing
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
    if (value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimary,
                height: 1.4,
              ),
              softWrap: true,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
