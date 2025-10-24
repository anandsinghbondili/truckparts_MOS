import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../../../core/widgets/autocomplete_search_bar.dart';
import '../../data/models/item_model.dart';
import '../../../home/data/services/parts_data_service.dart';
import '../../../home/data/services/item_details_by_customer_service.dart';
import '../../../home/domain/entities/part.dart';
import '../../../cart/data/services/cart_operations_service.dart';

/// Items page for testing performance of loading all items
/// This page fetches all items from the API and displays them in a list
class ItemsPage extends StatefulWidget {
  const ItemsPage({super.key});

  @override
  State<ItemsPage> createState() => _ItemsPageState();
}

class _ItemsPageState extends State<ItemsPage> {
  final PartsDataService _partsDataService = GetIt.instance<PartsDataService>();
  List<ItemModel> _allItems = [];
  List<ItemModel> _filteredItems = [];
  bool _isLoading = false;
  String? _error;
  int _totalItems = 0;
  DateTime? _loadStartTime;
  DateTime? _loadEndTime;

  // Cart operations
  final CartOperationsService _cartOperationsService =
      GetIt.instance<CartOperationsService>();

  // Quantity tracking for each item
  final Map<String, int> _itemQuantities = {};

  // Search functionality
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Defer loading to after the first frame to avoid context issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadItems();
    });
    // Listen to search query changes
    _searchController.addListener(_filterItems);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterItems() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredItems = _allItems;
      } else {
        _filteredItems = _allItems.where((item) {
          // Search across all fields
          return (item.name?.toLowerCase().contains(query) ?? false) ||
              (item.description?.toLowerCase().contains(query) ?? false) ||
              (item.id?.toLowerCase().contains(query) ?? false) ||
              (item.category?.toLowerCase().contains(query) ?? false) ||
              (item.subCategory?.toLowerCase().contains(query) ?? false) ||
              (item.brand?.toLowerCase().contains(query) ?? false) ||
              (item.model?.toLowerCase().contains(query) ?? false) ||
              (item.size?.toLowerCase().contains(query) ?? false) ||
              (item.vehicleMake?.toLowerCase().contains(query) ?? false) ||
              (item.vehicleModel?.toLowerCase().contains(query) ?? false) ||
              (item.partType?.toLowerCase().contains(query) ?? false);
        }).toList();
      }
    });
  }

  Future<void> _loadItems() async {
    final loadingStartTime = DateTime.now();

    setState(() {
      _isLoading = true;
      _error = null;
      _loadStartTime = loadingStartTime;
    });

    try {
      print('');
      print(
        '╔════════════════════════════════════════════════════════════════╗',
      );
      print('║  📦 ITEMS PAGE: Loading Items from Cache                     ║');
      print(
        '╚════════════════════════════════════════════════════════════════╝',
      );
      print('🔄 LOADING STARTED at: ${loadingStartTime.toIso8601String()}');
      print('');

      final dataStartTime = DateTime.now();
      print('📂 Fetching from PartsDataService cache...');

      // Get parts from the cached data service
      final parts = _partsDataService.getAllParts();

      final dataEndTime = DateTime.now();
      final dataFetchDuration = dataEndTime.difference(dataStartTime);
      print(
        '   ✅ Retrieved ${parts.length} parts from cache in ${dataFetchDuration.inMilliseconds}ms',
      );

      final conversionStartTime = DateTime.now();
      print('🔄 Converting Part entities to ItemModel...');

      // Convert Part entities to ItemModel
      final items = parts.map((part) => _partToItemModel(part)).toList();

      final conversionEndTime = DateTime.now();
      final conversionDuration = conversionEndTime.difference(
        conversionStartTime,
      );
      print(
        '   ✅ Converted ${items.length} items in ${conversionDuration.inMilliseconds}ms',
      );

      _loadEndTime = DateTime.now();
      final totalDuration = _loadEndTime!.difference(loadingStartTime);

      setState(() {
        _allItems = items;
        _filteredItems = items;
        _totalItems = items.length;
        _isLoading = false;
      });

      print('');
      print('=' * 70);
      print('✅ ITEMS PAGE: Loading Completed Successfully!');
      print('   - Total items: ${items.length}');
      print('   - Cache fetch time: ${dataFetchDuration.inMilliseconds}ms');
      print('   - Conversion time: ${conversionDuration.inMilliseconds}ms');
      print(
        '   - Total loading time: ${totalDuration.inMilliseconds}ms (${(totalDuration.inMilliseconds / 1000).toStringAsFixed(2)}s)',
      );
      print('=' * 70);
      print('✅ LOADING ENDED at: ${_loadEndTime!.toIso8601String()}');
      print('');

      if (mounted) {
        SnackBarUtils.showSuccess(
          context,
          message:
              'Loaded ${items.length} items in ${(totalDuration.inMilliseconds / 1000).toStringAsFixed(2)}s',
        );
      }
    } catch (e) {
      final loadingEndTime = DateTime.now();
      final errorDuration = loadingEndTime.difference(loadingStartTime);

      setState(() {
        _isLoading = false;
      });

      print('');
      print('=' * 70);
      print('❌ ITEMS PAGE: Loading Failed!');
      print('   - Error: $e');
      print(
        '   - Error occurred after: ${errorDuration.inMilliseconds}ms (${(errorDuration.inMilliseconds / 1000).toStringAsFixed(2)}s)',
      );
      print('=' * 70);
      print('✅ LOADING ENDED at: ${loadingEndTime.toIso8601String()} (ERROR)');
      print('');

      if (mounted) {
        ErrorHandler.handleApiError(
          context: context,
          error: e,
          onRetry: _loadItems,
        );
      }
    }
  }

  /// Refresh items data from API
  Future<void> _refreshItemsFromAPI() async {
    try {
      // Get service from GetIt
      final itemDetailsService = GetIt.instance<ItemDetailsByCustomerService>();

      print('');
      print(
        '╔════════════════════════════════════════════════════════════════╗',
      );
      print('║  🔄 ITEMS PAGE: Refreshing Items from API                    ║');
      print(
        '╚════════════════════════════════════════════════════════════════╝',
      );

      final refreshStartTime = DateTime.now();

      setState(() {
        _isLoading = true;
        _error = null;
      });

      print('🔄 REFRESH STARTED at: ${refreshStartTime.toIso8601String()}');
      print('');

      final apiStartTime = DateTime.now();
      print('🌐 Calling ItemDetailsbyCustomer API...');

      final items = await itemDetailsService.getItemsByCustomer();

      final apiEndTime = DateTime.now();
      final apiDuration = apiEndTime.difference(apiStartTime);
      print('📥 API Response received in ${apiDuration.inMilliseconds}ms');

      if (items.isNotEmpty) {
        _partsDataService.storeParts(items);
        print('✅ Stored ${items.length} items in PartsDataService');
      }

      // Reload from cache to update UI
      final parts = _partsDataService.getAllParts();
      final itemModels = parts.map((part) => _partToItemModel(part)).toList();

      final refreshEndTime = DateTime.now();
      final totalDuration = refreshEndTime.difference(refreshStartTime);

      setState(() {
        _allItems = itemModels;
        _filteredItems = itemModels;
        _totalItems = itemModels.length;
        _isLoading = false;
        _loadEndTime = refreshEndTime;
        _loadStartTime = refreshStartTime;
      });

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

      if (mounted) {
        SnackBarUtils.showSuccess(
          context,
          message: 'Refreshed ${items.length} items from API',
        );
      }
    } catch (e) {
      final refreshEndTime = DateTime.now();

      setState(() {
        _isLoading = false;
      });

      print('');
      print('=' * 70);
      print('❌ REFRESH FAILED: $e');
      print('=' * 70);
      print('✅ REFRESH ENDED at: ${refreshEndTime.toIso8601String()} (ERROR)');
      print('');

      if (mounted) {
        ErrorHandler.handleApiError(
          context: context,
          error: e,
          onRetry: _refreshItemsFromAPI,
        );
      }
    }
  }

  /// Convert Part entity to ItemModel
  ItemModel _partToItemModel(Part part) {
    return ItemModel(
      id: part.id,
      name: part.item,
      description: part.description,
      category: part.category.isEmpty ? null : part.category,
      subCategory: part.subCategory.isEmpty ? null : part.subCategory,
      brand: part.brand.isEmpty ? null : part.brand,
      model: part.model.isEmpty ? null : part.model,
      size: part.size.isEmpty ? null : part.size,
      price: part.price,
      imageUrl: part.imageUrl,
      vehicleMake: part.vehicleMake.isEmpty ? null : part.vehicleMake,
      vehicleModel: part.model.isEmpty ? null : part.model,
      partType: part.type.isEmpty ? null : part.type,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          resizeToAvoidBottomInset:
              false, // Prevent UI distortion when keyboard opens
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            title: const Text('All Items'),
            titleTextStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () => context.push(AppRouter.cart),
                tooltip: 'Cart',
              ),
              IconButton(
                icon: const Icon(Icons.home),
                onPressed: () => context.pop(),
                tooltip: 'Home',
              ),
              // Company Logo
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 12,
                ),
                child: Image.asset(
                  'assets/logos/shortform.png',
                  fit: BoxFit.contain,
                  height: 24,
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // Global Search Bar
              _buildSearchBar(),

              // Performance Stats Header
              _buildPerformanceStats(),

              // Items List
              Expanded(child: _buildItemsList()),
            ],
          ),
        ),

        // Loading overlay - shown when items are being loaded
        if (_isLoading)
          LoadingOverlay(message: 'Loading items. Please wait...'),
      ],
    );
  }

  Widget _buildSearchBar() {
    // Convert ItemModel list to Part list for autocomplete
    final parts = _allItems
        .map(
          (item) => Part(
            id: item.id ?? '',
            category: item.category ?? '',
            subCategory: item.subCategory ?? '',
            vehicleMake: item.vehicleMake ?? '',
            model: item.model ?? '',
            type: item.partType ?? '',
            part: item.name ?? '',
            size: item.size ?? '',
            brand: item.brand ?? '',
            item: item.name ?? '',
            price: item.price ?? 0.0,
            description: item.description ?? '',
          ),
        )
        .toList();

    return AutocompleteSearchBar(
      searchController: _searchController,
      allParts: parts,
      onSearchSubmitted: (_) {
        // Search is already handled by _filterItems listener
      },
      onSuggestionSelected: (part) {
        _searchController.text = part.item;
        // Filter will trigger automatically via listener
      },
    );
  }

  Widget _buildPerformanceStats() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.primaryColor.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard(
                'Total Items',
                _totalItems.toString(),
                Icons.inventory_2,
                AppTheme.primaryColor,
              ),
              _buildStatCard(
                'Filtered Items',
                _filteredItems.length.toString(),
                Icons.filter_list,
                AppTheme.successColor,
              ),
              _buildStatCard(
                'Load Time',
                _loadEndTime != null && _loadStartTime != null
                    ? '${(_loadEndTime!.difference(_loadStartTime!).inMilliseconds / 1000).toStringAsFixed(2)}s'
                    : '-',
                Icons.timer,
                AppTheme.successColor,
              ),
              _buildStatCard(
                'Status',
                _isLoading
                    ? 'Loading...'
                    : _error != null
                    ? 'Error'
                    : 'Success',
                _isLoading
                    ? Icons.hourglass_empty
                    : _error != null
                    ? Icons.error
                    : Icons.check_circle,
                _isLoading
                    ? AppTheme.warningColor
                    : _error != null
                    ? AppTheme.errorColor
                    : AppTheme.successColor,
              ),
            ],
          ),
          if (_loadEndTime != null && _loadStartTime != null) ...[
            const SizedBox(height: 8),
            Text(
              'Loaded on ${_loadEndTime!.toString().substring(0, 19)}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildItemsList() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_filteredItems.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshItemsFromAPI,
      color: AppTheme.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredItems.length,
        itemBuilder: (context, index) {
          final item = _filteredItems[index];
          return _buildItemCard(item, index);
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 300),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.primaryColor,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 300),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Text(
                  'Loading items. Please wait...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 300),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Text(
                  'Testing API performance',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No items found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'The API returned an empty list',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.normal,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refreshItemsFromAPI,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(ItemModel item, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {}, // Tappable for ripple effect
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item Header
              Row(
                children: [
                  // Item Index
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Item Name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name ?? 'Unnamed Item',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            item.description!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Price
                  if (item.price != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        PriceFormatter.formatPriceWithCurrency(item.price),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(
                            0xFF00A000,
                          ), // Darker, more vibrant green
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              // Part Details - 2 Column Layout
              _build2ColumnDataGrid(item),
              const SizedBox(height: 12),

              // Add to Cart Section
              _buildAddToCartSection(item),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddToCartSection(ItemModel item) {
    final itemId = item.id ?? '';
    final currentQuantity = _itemQuantities[itemId] ?? 1;

    return Row(
      children: [
        // Quantity Selector
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.borderColor),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Decrease Button
              InkWell(
                onTap: currentQuantity > 1
                    ? () => _updateQuantity(itemId, currentQuantity - 1)
                    : null,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: currentQuantity > 1
                        ? AppTheme.primaryColor.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                  child: Icon(
                    Icons.remove_outlined,
                    size: 16,
                    color: currentQuantity > 1
                        ? AppTheme.primaryColor
                        : Colors.grey,
                  ),
                ),
              ),
              // Quantity Display
              Container(
                width: 40,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  border: Border.symmetric(
                    vertical: BorderSide(color: AppTheme.borderColor),
                  ),
                ),
                child: Center(
                  child: Text(
                    currentQuantity.toString(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              // Increase Button
              InkWell(
                onTap: () => _updateQuantity(itemId, currentQuantity + 1),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Icon(
                    Icons.add_outlined,
                    size: 16,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        // Add to Cart Button
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _addToCart(item),
            icon: const Icon(Icons.shopping_cart, size: 18),
            label: const Text('Add to Cart'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _updateQuantity(String itemId, int newQuantity) {
    setState(() {
      _itemQuantities[itemId] = newQuantity;
    });
  }

  Future<void> _addToCart(ItemModel item) async {
    if (item.id == null || item.name == null) {
      SnackBarUtils.showError(
        context,
        message: 'Item information is incomplete',
      );
      return;
    }

    final itemId = item.id!;
    final itemName = item.name!;
    final quantity = _itemQuantities[itemId] ?? 1;

    try {
      print('🛒 Adding item to cart: $itemName (Qty: $quantity)');

      final response = await _cartOperationsService.addToCart(
        itemId: itemId,
        itemName: itemName,
        quantity: quantity,
      );

      print('✅ Add to cart response: $response');

      if (mounted) {
        SnackBarUtils.showSuccess(
          context,
          message: 'Added $itemName (Qty: $quantity) to cart',
        );
      }
    } catch (e) {
      print('❌ Error adding to cart: $e');
      if (mounted) {
        ErrorHandler.handleError(
          context: context,
          error: e,
          customTitle: 'Add to Cart Failed',
          customMessage:
              'Unable to add this item to your cart. Please try again.',
          actionButtonText: 'Retry',
          onActionPressed: () => _addToCart(item),
        );
      }
    }
  }

  Widget _build2ColumnDataGrid(ItemModel item) {
    // Define all fields to display in 2-column grid
    final fields = [
      {'label': 'Item ID', 'value': item.id ?? 'null'},
      {'label': 'Vehicle Make', 'value': item.vehicleMake ?? 'null'},
      {'label': 'Model', 'value': item.model ?? 'null'},
      {'label': 'Category', 'value': item.category ?? 'null'},
      {'label': 'Sub Category', 'value': item.subCategory ?? 'null'},
      {'label': 'Type', 'value': item.partType ?? 'null'},
      {'label': 'Part', 'value': 'null'}, // Not in ItemModel
      {'label': 'Size', 'value': item.size ?? 'null'},
      {'label': 'Brand', 'value': item.brand ?? 'null'},
      {
        'label': 'List Price',
        'value': item.price != null ? '₹${item.price}' : 'null',
      },
      {'label': 'Net Price', 'value': 'null'}, // Not in ItemModel
      {'label': 'Operating Unit', 'value': item.unit ?? 'null'},
    ];

    return Column(
      children: [
        // Item Name and Description (Full Width)
        _buildFullWidthField('Item Name', item.name ?? 'null'),
        const SizedBox(height: 6),
        _buildFullWidthField('Description', item.description ?? 'null'),
        const SizedBox(height: 8),

        // 2-Column Grid for other fields
        ...List.generate((fields.length / 2).ceil(), (rowIndex) {
          final leftIndex = rowIndex * 2;
          final rightIndex = leftIndex + 1;

          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column
                Expanded(
                  child: _buildCompactField(
                    fields[leftIndex]['label']!,
                    fields[leftIndex]['value']!,
                  ),
                ),
                const SizedBox(width: 6),
                // Right Column
                if (rightIndex < fields.length)
                  Expanded(
                    child: _buildCompactField(
                      fields[rightIndex]['label']!,
                      fields[rightIndex]['value']!,
                    ),
                  )
                else
                  const Expanded(child: SizedBox()),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildFullWidthField(String label, String value) {
    final isNull = value == 'null';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isNull
                    ? Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withOpacity(0.5)
                    : Theme.of(context).colorScheme.onSurface,
                fontStyle: isNull ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ],
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildCompactField(String label, String value) {
    final isNull = value == 'null';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppTheme.borderColor.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isNull
                    ? Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withOpacity(0.5)
                    : Theme.of(context).colorScheme.onSurface,
                fontStyle: isNull ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
