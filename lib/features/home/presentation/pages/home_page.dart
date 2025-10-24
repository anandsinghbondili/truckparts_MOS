import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/data_loading_service.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../../../core/widgets/autocomplete_search_bar.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../cart/data/services/cart_service.dart';
import '../../../orders/data/services/order_service.dart';
import '../../data/services/item_details_by_customer_service.dart';
import '../../data/services/parts_data_service.dart';
import '../widgets/vehicle_selection_dialog.dart';
import '../widgets/category_selection_dialog.dart';
import '../widgets/type_size_selection_dialog.dart';
import '../widgets/promotional_banners_carousel.dart';
import '../widgets/filter_buttons_section.dart';
import '../widgets/promotional_video_section.dart';
import '../widgets/brands_section.dart';
import '../widgets/home_drawer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedVehicleMake;
  String? _selectedVehicleModel;
  String? _selectedCategory;
  String? _selectedSubCategory;
  String? _selectedType;
  String? _selectedSize;
  String? _validationError;

  // ✅ NEW: Filter completion tracking
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
    _updateFilterCompletionStatus();
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
    print('🔍 Filter State Update:');
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Refresh items data from API
  Future<void> _refreshItemsData() async {
    final loadingService = Provider.of<DataLoadingService>(
      context,
      listen: false,
    );

    try {
      // Get services from GetIt
      final itemDetailsService = GetIt.instance<ItemDetailsByCustomerService>();
      final partsDataService = GetIt.instance<PartsDataService>();

      print('');
      print(
        '╔════════════════════════════════════════════════════════════════╗',
      );
      print('║  🔄 HOME PAGE: Refreshing Items from API                     ║');
      print(
        '╚════════════════════════════════════════════════════════════════╝',
      );

      final refreshStartTime = DateTime.now();
      loadingService.startLoadingItems();
      print('🔄 REFRESH STARTED at: ${refreshStartTime.toIso8601String()}');
      print('');

      final apiStartTime = DateTime.now();
      print('🌐 Calling ItemDetailsbyCustomer API...');

      final items = await itemDetailsService.getItemsByCustomer();

      final apiEndTime = DateTime.now();
      final apiDuration = apiEndTime.difference(apiStartTime);
      print('📥 API Response received in ${apiDuration.inMilliseconds}ms');

      if (items.isNotEmpty) {
        partsDataService.storeParts(items);
        print('✅ Stored ${items.length} items in PartsDataService');
      }

      final refreshEndTime = DateTime.now();
      final totalDuration = refreshEndTime.difference(refreshStartTime);

      print('');
      print('=' * 70);
      print('✅ REFRESH COMPLETED SUCCESSFULLY!');
      print('   - Total items: ${items.length}');
      print(
        '   - API call time: ${apiDuration.inMilliseconds}ms (${(apiDuration.inMilliseconds / 1000).toStringAsFixed(2)}s)',
      );
      print(
        '   - Total refresh time: ${totalDuration.inMilliseconds}ms (${(totalDuration.inMilliseconds / 1000).toStringAsFixed(2)}s)',
      );
      print('=' * 70);
      print('✅ REFRESH ENDED at: ${refreshEndTime.toIso8601String()}');
      print('');

      loadingService.completeLoadingItems();

      if (mounted) {
        SnackBarUtils.showSuccess(
          context,
          message: 'Refreshed ${items.length} items successfully',
        );
      }
    } catch (e) {
      final refreshEndTime = DateTime.now();
      print('');
      print('=' * 70);
      print('❌ REFRESH FAILED: $e');
      print('=' * 70);
      print('✅ REFRESH ENDED at: ${refreshEndTime.toIso8601String()} (ERROR)');
      print('');

      loadingService.completeLoadingItems();

      if (mounted) {
        ErrorHandler.handleApiError(
          context: context,
          error: e,
          onRetry: _refreshItemsData,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataLoadingService>(
      builder: (context, loadingService, child) {
        return Stack(
          children: [
            Scaffold(
              resizeToAvoidBottomInset:
                  false, // Prevent UI distortion when keyboard opens
              appBar: AppBar(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                toolbarHeight: 56, // Standard AppBar height
                leading: Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.menu_outlined),
                    iconSize: 24, // Standard icon size
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                ),
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // const Icon(Icons.local_shipping, size: 24),
                    const SizedBox(width: 8),
                    const Text('Truck Parts - MOS'),
                  ],
                ),
                titleTextStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                actions: [
                  // Refresh button
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _refreshItemsData,
                    tooltip: 'Refresh Items',
                  ),
                  // Company Logo - Properly sized
                  Image.asset(
                    'assets/logos/shortform.png',
                    fit: BoxFit.contain,
                    width: 100, // Adjusted for better proportion
                    height: 32, // Better proportion to AppBar height
                  ),
                ],
              ),
              drawer: HomeDrawer(
                onLogoutPressed: () => _showLogoutDialog(context),
              ),
              body: GestureDetector(
                onTap: () {
                  // Dismiss keyboard when tapping outside search field
                  FocusScope.of(context).unfocus();
                },
                child: Column(
                  children: [
                    // Global Search Bar with Autocomplete
                    AutocompleteSearchBar(
                      searchController: _searchController,
                      allParts: GetIt.instance<PartsDataService>().allParts,
                      onSearchSubmitted: (_) => _performGlobalSearch(),
                      onSuggestionSelected: (part) {
                        _searchController.text = part.item;
                        _performGlobalSearch();
                      },
                    ),

                    // Promotional Banners Carousel - Flexible height
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: PromotionalBannersCarousel(),
                      ),
                    ),

                    // Filter Section - Fixed
                    Column(
                      children: [
                        FilterButtonsSection(
                          selectedVehicleMake: _selectedVehicleMake,
                          selectedVehicleModel: _selectedVehicleModel,
                          selectedSubCategory: _selectedSubCategory,
                          selectedType: _selectedType,
                          selectedSize: _selectedSize,
                          // ✅ NEW: Pass filter state
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
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

                    // Promotional Video - Flexible height
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: PromotionalVideoSection(),
                      ),
                    ),

                    // Brands Section - Flexible height
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: BrandsSection(onBrandSelected: _filterByBrand),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Loading overlay - shown when items are being loaded
            if (loadingService.isLoadingItems)
              LoadingOverlay(message: loadingService.loadingMessage),
          ],
        );
      },
    );
  }

  void _showVehicleDialog() {
    print('🔍 Opening Vehicle Dialog with cascading filters:');
    print('   - Current Make: $_selectedVehicleMake');
    print('   - Current Model: $_selectedVehicleModel');

    String? previousMake = _selectedVehicleMake;

    VehicleSelectionDialog.show(
      context: context,
      selectedVehicleMake: _selectedVehicleMake,
      selectedVehicleModel: _selectedVehicleModel,
      onVehicleSelected: (make, model) {
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

    print('🔍 Opening Part Dialog with cascading filters:');
    print('   - Current Make: $_selectedVehicleMake');
    print('   - Current Model: $_selectedVehicleModel');

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (context) => CategorySelectionDialog(
        selectedSubCategory: _selectedSubCategory,
        onSubCategorySelected: (subCategory) {
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

    print('🔍 Opening Size Dialog with cascading filters:');
    print('   - Current Make: $_selectedVehicleMake');
    print('   - Current Model: $_selectedVehicleModel');
    print('   - Current Part: $_selectedSubCategory');

    TypeSizeSelectionDialog.show(
      context: context,
      selectedType: _selectedType,
      selectedSize: _selectedSize,
      onTypeSizeSelected: (type, size) {
        setState(() {
          _selectedType = type;
          _selectedSize = size;

          // ✅ NEW: Update empty flags for "Any" option
          _isTypeEmpty = type == 'Any';
          _isSizeEmpty = size == 'Any';

          _validationError = null;
          _updateFilterCompletionStatus();
        });
      },
      selectedVehicleMake: _selectedVehicleMake,
      selectedVehicleModel: _selectedVehicleModel,
      selectedSubCategory: _selectedSubCategory,
    );
  }

  void _performGlobalSearch() {
    // Global search - only uses the search text, ignores filters
    final searchQuery = {
      'query': _searchController.text.trim(),
      'vehicleMake': null,
      'vehicleModel': null,
      'category': null,
      'subCategory': null,
      'type': null,
      'size': null,
    };

    // Navigate to search results with only the search query
    context.go(AppRouter.searchResults, extra: searchQuery);
  }

  void _performFilterSearch() {
    // ✅ NEW: Check if all filters are complete
    if (!_areFiltersComplete()) {
      setState(() {
        _validationError = 'Please complete all filter selections';
      });
      SnackBarUtils.showWarning(
        context,
        message: 'Please select: Vehicle Make → Model → Part → Type → Size',
      );
      return;
    }

    // Clear validation error
    setState(() {
      _validationError = null;
    });

    // Filter-based search
    final searchQuery = {
      'query': null,
      'vehicleMake': _selectedVehicleMake,
      'vehicleModel': _selectedVehicleModel,
      'category': _selectedCategory,
      'subCategory': _selectedSubCategory,
      'type': _selectedType,
      'size': _selectedSize,
    };

    // Navigate to search results with filters
    context.go(AppRouter.searchResults, extra: searchQuery);
  }

  void _resetFilters() {
    _resetAllFilters();
    _searchController.clear();
  }

  void _filterByBrand(String brandName) {
    // Prepare search query with brand filter
    final searchQuery = {
      'query': '', // Empty search query
      'vehicleMake': null,
      'vehicleModel': null,
      'category': null,
      'subCategory': null,
      'type': null,
      'size': null,
      'brand': brandName, // Add brand filter
    };

    // Navigate to search results with brand filter
    context.go(AppRouter.searchResults, extra: searchQuery);
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              // Properly handle logout with AuthBloc
              _performLogout(context);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Future<void> _performLogout(BuildContext context) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    // Trigger logout event
    context.read<AuthBloc>().add(LogoutRequested());

    // Wait a bit for logout to complete
    await Future.delayed(const Duration(milliseconds: 500));

    // Clear cart data
    try {
      final cartService = context.read<CartService>();
      await cartService.clearCart();
      print('✅ Cart cleared on logout');
    } catch (e) {
      print('⚠️ Failed to clear cart on logout: $e');
    }

    // Clear order data
    try {
      final orderService = context.read<OrderService>();
      await orderService.clearOrders();
      print('✅ Orders cleared on logout');
    } catch (e) {
      print('⚠️ Failed to clear orders on logout: $e');
    }

    // Close loading dialog
    if (context.mounted) {
      Navigator.of(context).pop();
    }

    // Navigate to login page
    if (context.mounted) {
      context.go(AppRouter.login);
    }
  }
}
