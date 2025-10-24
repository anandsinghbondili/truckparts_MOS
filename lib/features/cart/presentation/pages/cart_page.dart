import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/services/app_context_service.dart';
import '../../../cart/data/services/cart_service.dart';
import '../../../cart/data/services/cart_api_service.dart';
import '../../../cart/data/services/cart_operations_service.dart';
import '../../../home/domain/entities/part.dart';
import '../../../home/data/services/parts_data_service.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final _cartApiService = GetIt.instance<CartApiService>();
  final _cartOperationsService = GetIt.instance<CartOperationsService>();
  bool _isLoading = false;
  String? _errorMessage;

  // Server-provided totals
  double? _serverSubTotal;
  double? _serverTaxAmount;
  double? _serverTotalAmount;

  // iOS edit mode tracking
  bool _isAnyItemBeingEdited = false;

  @override
  void initState() {
    super.initState();
    // Fetch cart details from server
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchCartDetails();
    });
  }

  /// Helper method to safely parse double values from JSON
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  Future<void> _removeFromCart(
    CartItem cartItem,
    CartService cartService,
  ) async {
    try {
      print('🗑️ Removing item from cart: ${cartItem.part.displayName}');

      // Call DeleteCart API
      final response = await _cartOperationsService.deleteFromCart(
        itemId: cartItem.part.id,
      );

      print('✅ Delete from cart response: $response');

      // Check if the deletion was successful and refresh cart totals
      if (response['success'] == true || response['Success'] == true) {
        print('🔄 Cart deletion successful, refreshing cart totals...');
        // Refresh cart totals only
        _refreshCartTotals();
      }

      // Update local cart service
      cartService.removeFromCart(cartItem.part.id);

      if (mounted) {
        SnackBarUtils.showSuccess(
          context,
          message: '${cartItem.part.displayName} removed from cart',
        );
      }
    } catch (e) {
      print('❌ Error removing from cart: $e');
      if (mounted) {
        ErrorHandler.handleError(
          context: context,
          error: e,
          customTitle: 'Remove Item Failed',
          customMessage:
              'Unable to remove this item from your cart. Please try again.',
          actionButtonText: 'Retry',
          onActionPressed: () => _removeFromCart(cartItem, cartService),
        );
      }
    }
  }

  Future<void> _fetchCartDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('🛒 Fetching cart details from server...');

      final response = await _cartApiService.getCartDetails();
      final cartResponse = CartDetailsResponse.fromJson(response);

      print('✅ Cart Response: ${cartResponse.toJson()}');
      print('   Success: ${cartResponse.success}');
      print('   Message: ${cartResponse.message}');
      print('   Items count: ${cartResponse.items?.length ?? 0}');

      if (cartResponse.success) {
        // Update local cart service with server data
        await _syncServerDataToLocalCart(cartResponse);

        // Cart loaded successfully - no message needed
      } else {
        // Check if the message indicates empty cart
        final message = cartResponse.message ?? '';
        if (message.toLowerCase().contains('cart data is empty') ||
            message.toLowerCase().contains('cart is empty')) {
          // Handle empty cart as normal state, not error
          print('📭 Cart is empty - treating as normal state');
          // Clear any existing error message
          setState(() {
            _errorMessage = null;
          });
        } else {
          // Handle other errors
          setState(() {
            _errorMessage = cartResponse.message ?? 'Failed to load cart';
          });
        }
      }
    } on CartApiException catch (e) {
      print('❌ Cart API Error: ${e.message}');
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      print('❌ Unexpected Error: $e');
      setState(() {
        _errorMessage = 'Failed to load cart. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Refresh only cart totals without refreshing the entire page
  Future<void> _refreshCartTotals() async {
    try {
      print('💰 Refreshing cart totals from server...');

      final response = await _cartApiService.getCartDetails();
      final cartResponse = CartDetailsResponse.fromJson(response);

      if (cartResponse.success) {
        // Update only the totals state variables
        setState(() {
          _serverSubTotal = cartResponse.subTotal;
          _serverTaxAmount = cartResponse.taxAmount;
          _serverTotalAmount = cartResponse.totalAmount;
        });

        print('✅ Cart totals refreshed:');
        print('   - SubTotal: $_serverSubTotal');
        print('   - TaxAmount: $_serverTaxAmount');
        print('   - TotalAmount: $_serverTotalAmount');
      } else {
        print('❌ Failed to refresh cart totals: ${cartResponse.message}');
      }
    } catch (e) {
      print('❌ Error refreshing cart totals: $e');
    }
  }

  /// Sync server cart data to local cart service
  Future<void> _syncServerDataToLocalCart(
    CartDetailsResponse cartResponse,
  ) async {
    try {
      final cartService = GetIt.instance<CartService>();

      // Store server-provided totals
      setState(() {
        _serverSubTotal = cartResponse.subTotal;
        _serverTaxAmount = cartResponse.taxAmount;
        _serverTotalAmount = cartResponse.totalAmount;
      });

      print('💰 Server Totals:');
      print('   - SubTotal: $_serverSubTotal');
      print('   - TaxAmount: $_serverTaxAmount');
      print('   - TotalAmount: $_serverTotalAmount');

      // Convert server items to local cart items
      final List<CartItem> serverCartItems = [];

      if (cartResponse.items != null && cartResponse.items!.isNotEmpty) {
        for (final serverItem in cartResponse.items!) {
          // Extract pricing data from server item's additionalData
          final additionalData = serverItem.additionalData ?? {};

          // Extract all pricing fields from API response
          final mrpValue = _parseDouble(
            additionalData['smrp'] ?? additionalData['SMRP'],
          );
          final netPriceValue = serverItem.unitPrice; // From 'price' field
          final subtotalValue = _parseDouble(
            additionalData['subtotal'] ?? additionalData['SubTotal'],
          );
          final taxAmountValue = _parseDouble(
            additionalData['taxamount'] ?? additionalData['TaxAmount'],
          );
          final totalAmountValue = _parseDouble(
            additionalData['totalamount'] ?? additionalData['TotalAmount'],
          );

          print('📦 Cart Item: ${serverItem.partNumber}');
          print('   - MRP (smrp): ₹$mrpValue');
          print('   - Net Price (price): ₹$netPriceValue');
          print('   - Quantity: ${serverItem.quantity}');
          print('   - Subtotal: ₹$subtotalValue');
          print('   - Tax Amount: ₹$taxAmountValue');
          print('   - Total Amount: ₹$totalAmountValue');

          // Get description from All Parts data
          final partsDataService = GetIt.instance<PartsDataService>();
          final allPartsItem = partsDataService.getPartById(serverItem.id);
          final descriptionFromAllParts =
              allPartsItem?.description ?? serverItem.description ?? '';

          // Convert server item to Part entity
          final part = Part(
            id: serverItem.id,
            category: serverItem.category ?? '',
            subCategory: '',
            vehicleMake: '',
            model: '',
            type: '',
            part: serverItem.partName ?? '',
            size: '',
            brand: serverItem.brand ?? '',
            item: serverItem.partNumber ?? '',
            price: netPriceValue, // Net price is the unit price
            mrp: mrpValue > 0 ? mrpValue : null, // MRP from smrp field
            netPrice: netPriceValue, // Net Price from price field
            description:
                descriptionFromAllParts, // ✅ Use description from All Parts data
          );

          // Create CartItem with exact server values (NO CALCULATIONS)
          final cartItem = CartItem(
            part: part,
            quantity: serverItem.quantity,
            unitPrice: netPriceValue, // Use net price as unit price
            subtotal: subtotalValue, // From API: price × quantity (WITHOUT tax)
            taxAmount: taxAmountValue, // From API: tax amount
            totalAmount: totalAmountValue, // From API: total WITH tax
          );

          serverCartItems.add(cartItem);

          print(
            '✅ Prepared cart item: ${part.displayName} (Qty: ${serverItem.quantity}, Unit: ${serverItem.unitPrice}, Total: ${cartItem.totalPrice})',
          );
        }

        // Replace entire cart with server data (avoids accumulation issues)
        await cartService.replaceCartWithServerData(serverCartItems);

        print(
          '🔄 Synced ${cartResponse.items!.length} items from server to local cart',
        );
      } else {
        // Clear cart if server has no items
        await cartService.clearCart();
        print('📭 No items in server cart');
      }
    } catch (e) {
      print('❌ Error syncing server data to local cart: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartService>(
      builder: (context, cartService, child) {
        // Debug print to check cart items and total
        debugPrint('Cart items count: ${cartService.cartItems.length}');
        debugPrint('Cart total amount: ${cartService.totalAmount}');
        for (var item in cartService.cartItems) {
          debugPrint(
            'Item: ${item.part.displayName}, Qty: ${item.quantity}, Unit: ${item.unitPrice}, Total: ${item.totalPrice}',
          );
        }

        return Scaffold(
          appBar: AppBar(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(AppRouter.home);
                }
              },
            ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shopping_cart, size: 24),
                const SizedBox(width: 8),
                const Text('Shopping Cart'),
              ],
            ),
            titleTextStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.home),
                onPressed: () => context.go(AppRouter.home),
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
          body: _isLoading
              ? _buildLoadingState()
              : _errorMessage != null
              ? _buildErrorState()
              : cartService.cartItems.isEmpty
              ? _buildEmptyCart()
              : _buildCartContent(cartService),
        );
      },
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
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
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
                  'Loading cart...',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Failed to load cart',
              style: const TextStyle(fontSize: 16, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchCartDetails,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Your Cart is Empty',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some parts to get started',
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
                Icon(Icons.shopping_bag_outlined, size: 18),
                SizedBox(width: 8),
                Text('Continue Shopping'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent(CartService cartService) {
    return Column(
      children: [
        // Cart Items List - Scrollable only
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cart Items
                ...cartService.cartItems.asMap().entries.map((entry) {
                  return _buildCartItemCard(
                    entry.value,
                    entry.key,
                    cartService,
                  );
                }),
                // Add bottom padding to ensure last item is fully visible
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),

        // Clean Divider
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          height: 1,
          color: AppTheme.borderColor.withOpacity(0.3),
        ),

        const SizedBox(height: 12),

        // Fixed Bottom Sections - No scrolling
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              // Delivery Address Section
              _buildDeliveryAddress(),

              const SizedBox(height: 10),

              // Clean Divider
              Container(
                height: 1,
                color: AppTheme.borderColor.withOpacity(0.3),
              ),

              const SizedBox(height: 10),

              // Bill Details Section
              _buildBillDetails(cartService),

              const SizedBox(height: 12),
            ],
          ),
        ),

        // Cart Footer
        _buildCartFooter(cartService),
      ],
    );
  }

  Widget _buildCartItemCard(
    CartItem cartItem,
    int index,
    CartService cartService,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: () => _showItemDetails(cartItem),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, AppTheme.backgroundColor.withOpacity(0.3)],
            ),
          ),
          child: Column(
            children: [
              // TOP SECTION: Image & Part Details (LEFT), Delete Button (RIGHT)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Image.asset(
                        'assets/logos/shortform.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Part Name/Number & Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Part Number/Name
                        Text(
                          cartItem.part.item,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                            letterSpacing: 0.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        // Part Description (single line with ellipsis)
                        if (cartItem.part.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            cartItem.part.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                              height: 1.2,
                            ),
                            maxLines: 1, // Single line only
                            overflow:
                                TextOverflow.ellipsis, // Ellipsis for long text
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Delete Button (no background) - Prevent event propagation to parent InkWell
                  GestureDetector(
                    onTap: () {
                      // Prevent the tap from propagating to the parent InkWell
                      _removeFromCart(cartItem, cartService);
                    },
                    behavior: HitTestBehavior.opaque,
                    child: IconButton(
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: AppTheme.errorColor,
                        size: 22,
                      ),
                      onPressed: () => _removeFromCart(cartItem, cartService),
                      tooltip: 'Remove from cart',
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),
              Divider(height: 1, color: AppTheme.borderColor.withOpacity(0.5)),
              const SizedBox(height: 10),

              // BOTTOM SECTION: Quantity (LEFT), Net Price & Total (RIGHT)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Quantity Selector - Prevent event propagation to parent InkWell
                  GestureDetector(
                    onTap: () {
                      // Prevent the tap from propagating to the parent InkWell
                      // This allows quantity selector to work without opening dialog
                    },
                    behavior: HitTestBehavior.opaque,
                    child: _buildQuantitySelector(cartItem, index, cartService),
                  ),

                  const SizedBox(width: 12),

                  // Net Price & Total
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Unit Price (Net Price + Tax) * Qty
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Unit Price: ',
                              style: TextStyle(
                                fontSize: 11, // Reduced from 12
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Flexible(
                              child: RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text:
                                          PriceFormatter.formatPriceWithCurrency(
                                            cartItem.unitPriceWithTax,
                                          ),
                                      style: const TextStyle(
                                        fontSize: 13, // Reduced from 15
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF00A000),
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' * ',
                                      style: const TextStyle(
                                        fontSize: 13, // Reduced from 15
                                        fontWeight: FontWeight.bold,
                                        color: Color(
                                          0xFF666666,
                                        ), // Dark gray color
                                      ),
                                    ),
                                    TextSpan(
                                      text: '${cartItem.quantity}',
                                      style: const TextStyle(
                                        fontSize: 13, // Reduced from 15
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF00A000),
                                      ),
                                    ),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Total (no background)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Total: ',
                              style: TextStyle(
                                fontSize: 12, // Reduced from 13
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                PriceFormatter.formatPriceWithCurrency(
                                  cartItem.totalPrice,
                                ),
                                style: const TextStyle(
                                  fontSize: 14, // Reduced from 18
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF00A000),
                                  letterSpacing: 0.5,
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showItemDetails(CartItem cartItem) async {
    // ✅ Remove focus from any active input fields to prevent keyboard flash
    // Use multiple methods to ensure focus is completely removed
    FocusScope.of(context).unfocus();
    FocusManager.instance.primaryFocus?.unfocus();

    // ✅ Add a small delay to ensure focus is properly removed
    await Future.delayed(const Duration(milliseconds: 150));

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => CartItemDetailsDialog(
          part: cartItem.part,
          initialQuantity: cartItem.quantity,
          onQuantityChanged: (newQuantity) {
            // Update cart quantity when dialog quantity changes
            final cartService = Provider.of<CartService>(
              context,
              listen: false,
            );
            cartService.updateQuantity(cartItem.part.id, newQuantity);
          },
          onCartUpdated: _refreshCartTotals, // Refresh cart totals after update
        ),
      );
    }
  }

  Widget _buildDeliveryAddress() {
    final appContext = GetIt.instance<AppContextService>();
    final deliveryAddress = appContext.deliveryAddress;

    // Debug: Print address data
    print('📍 Cart Page - Delivery Address:');
    print('   - Formatted: $deliveryAddress');
    print('   - Raw data: ${appContext.customerAddress}');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {}, // Tappable for ripple effect
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10), // Reduced from 12
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Delivery Address',
                style: TextStyle(
                  fontSize: 15, // Reduced from 16
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6), // Reduced from 8
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 16, // Reduced from 18
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 6), // Reduced from 8
                  Expanded(
                    child: Text(
                      deliveryAddress,
                      style: const TextStyle(
                        fontSize: 13, // Reduced from 14
                        color: AppTheme.textSecondary,
                        height: 1.3, // Reduced from 1.4
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBillDetails(CartService cartService) {
    // Use server-provided totals if available, otherwise fallback to local calculation
    final subtotal = _serverSubTotal ?? cartService.totalAmount;
    final tax =
        _serverTaxAmount ?? 0.0; // Use server tax, no fallback calculation
    final total = _serverTotalAmount ?? (subtotal + tax);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {}, // Tappable for ripple effect
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10), // Reduced from 12
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bill Details',
                style: TextStyle(
                  fontSize: 15, // Reduced from 16
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8), // Reduced from 12
              _buildBillRow('Sub Total', subtotal),
              const SizedBox(height: 6), // Reduced from 8
              _buildBillRow('Taxes', tax),
              const Divider(height: 16), // Reduced from 24
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Amount',
                    style: TextStyle(
                      fontSize: 15, // Reduced from 16
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    PriceFormatter.formatPriceWithCurrency(total),
                    style: const TextStyle(
                      fontSize: 16, // Reduced from 18
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00A000), // Darker, more vibrant green
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBillRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
          ), // Reduced from 14
        ),
        Text(
          PriceFormatter.formatPriceWithCurrency(amount),
          style: const TextStyle(
            fontSize: 13, // Reduced from 14
            color: Color(0xFF00A000), // Darker, more vibrant green
            fontWeight: FontWeight.w600, // Made bolder
          ),
        ),
      ],
    );
  }

  Widget _buildQuantitySelector(
    CartItem cartItem,
    int index,
    CartService cartService,
  ) {
    return _CartQuantitySelector(
      cartItem: cartItem,
      cartService: cartService,
      cartOperationsService: _cartOperationsService,
      onQuantityChanged: () {
        // Consumer will automatically rebuild when CartService notifies listeners
        // No need to call setState() here
      },
      onCartUpdated:
          _refreshCartTotals, // Refresh cart totals after successful update
      onEditModeChanged: _onEditModeChanged, // Pass edit mode callback
    );
  }

  Widget _buildCartFooter(CartService cartService) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Action Buttons - Conditional based on edit mode
          if (_isAnyItemBeingEdited) ...[
            // Edit Mode - Cancel and OK buttons
            Row(
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
          ] else ...[
            // Normal Mode - Empty Cart and Place Order buttons
            Row(
              children: [
                // Empty Cart Button
                Expanded(
                  flex: 2,
                  child: OutlinedButton(
                    onPressed: cartService.cartItems.isEmpty
                        ? null
                        : () => _showEmptyCartDialog(cartService),
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
                        Icon(Icons.delete_outlined, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Empty Cart',
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

                // Place Order Button
                Expanded(
                  flex: 3,
                  child: ElevatedButton(
                    onPressed: cartService.cartItems.isEmpty
                        ? null
                        : () => _placeOrder(cartService),
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
                        Icon(Icons.shopping_cart_checkout_outlined, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Place Order',
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
        ],
      ),
    );
  }

  void _showEmptyCartDialog(CartService cartService) async {
    // ✅ Remove focus from any active input fields to prevent keyboard flash
    // Use multiple methods to ensure focus is completely removed
    FocusScope.of(context).unfocus();
    FocusManager.instance.primaryFocus?.unfocus();

    // ✅ Add a small delay to ensure focus is properly removed
    await Future.delayed(const Duration(milliseconds: 150));

    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Empty Cart?'),
            content: const Text('Remove all items from cart?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  cartService.clearCart();
                  Navigator.of(context).pop();
                  SnackBarUtils.showSuccess(
                    context,
                    message: 'Cart cleared successfully',
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: AppTheme.errorColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Empty Cart'),
              ),
            ],
          );
        },
      );
    }
  }

  void _placeOrder(CartService cartService) {
    try {
      if (cartService.cartItems.isEmpty) {
        SnackBarUtils.showError(context, message: 'Your cart is empty');
        return;
      }

      final orderData = {
        'items': cartService.cartItems
            .map(
              (item) => {
                'partId': item.part.id,
                'partName': item.part.displayName,
                'quantity': item.quantity,
                'unitPrice': item.unitPrice,
                'totalPrice': item.totalPrice,
                'brand': item.part.brand,
                'size': item.part.size,
              },
            )
            .toList(),
        'grandTotal': _serverTotalAmount ?? cartService.totalAmount,
        'subTotal': _serverSubTotal ?? cartService.totalAmount,
        'taxAmount': _serverTaxAmount ?? 0.0,
        'itemCount': cartService.itemCount,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Debug print to check data
      debugPrint('Order data: $orderData');

      context.go(AppRouter.otpConfirmation, extra: orderData);
    } catch (e) {
      debugPrint('Error in _placeOrder: $e');
      ErrorHandler.handleError(
        context: context,
        error: e,
        customTitle: 'Order Failed',
        customMessage:
            'We couldn\'t process your order. Please try again or contact support.',
        actionButtonText: 'Try Again',
        onActionPressed: () => _placeOrder(cartService),
      );
    }
  }

  // Global edit mode management for iOS
  void _onEditModeChanged(bool isEditing) {
    setState(() {
      _isAnyItemBeingEdited = isEditing;
    });
  }

  void _globalCancelEditing() {
    // This will be called when user cancels editing from the global buttons
    // Remove focus from any active input fields
    FocusScope.of(context).unfocus();
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _isAnyItemBeingEdited = false;
    });
  }

  void _globalConfirmEditing() {
    // This will be called when user confirms editing from the global buttons
    // Remove focus from any active input fields
    FocusScope.of(context).unfocus();
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _isAnyItemBeingEdited = false;
    });
  }
}

class _CartQuantitySelector extends StatefulWidget {
  final CartItem cartItem;
  final CartService cartService;
  final CartOperationsService cartOperationsService;
  final VoidCallback onQuantityChanged;
  final VoidCallback? onCartUpdated;
  final Function(bool)? onEditModeChanged; // Callback for edit mode changes

  const _CartQuantitySelector({
    required this.cartItem,
    required this.cartService,
    required this.cartOperationsService,
    required this.onQuantityChanged,
    this.onCartUpdated,
    this.onEditModeChanged,
  });

  @override
  State<_CartQuantitySelector> createState() => _CartQuantitySelectorState();
}

class _CartQuantitySelectorState extends State<_CartQuantitySelector> {
  late TextEditingController _quantityController;
  late int _quantity;
  FocusNode? _focusNode;
  bool _isEditing = false; // Track if user is editing quantity
  int _editingQuantity = 0; // Store quantity being edited

  @override
  void initState() {
    super.initState();
    _quantity = widget.cartItem.quantity;
    _quantityController = TextEditingController(text: _quantity.toString());
    _focusNode = FocusNode();

    // Listen for focus changes to handle quantity updates
    _focusNode!.addListener(() {
      if (!_focusNode!.hasFocus) {
        // User finished editing, validate and update quantity
        final int? parsedQuantity = int.tryParse(_quantityController.text);
        if (parsedQuantity != null && parsedQuantity >= 1) {
          _updateQuantity(parsedQuantity);
        } else {
          // Reset to current quantity if invalid
          _quantityController.text = _quantity.toString();
        }
      }
    });
  }

  @override
  void didUpdateWidget(_CartQuantitySelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync with external changes
    if (widget.cartItem.quantity != _quantity) {
      _quantity = widget.cartItem.quantity;
      _quantityController.text = _quantity.toString();
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _focusNode?.dispose();
    super.dispose();
  }

  void _updateQuantity(int newQuantity) async {
    debugPrint(
      '_CartQuantitySelector: _updateQuantity called with $newQuantity',
    );
    if (newQuantity >= 1) {
      setState(() {
        _quantity = newQuantity;
        _quantityController.text = _quantity.toString();
        _isEditing = false; // Exit edit mode
      });
      // Notify parent about edit mode change
      widget.onEditModeChanged?.call(false);

      // Update local cart service first
      debugPrint(
        '_CartQuantitySelector: calling cartService.updateQuantity for ${widget.cartItem.part.id}',
      );
      widget.cartService.updateQuantity(widget.cartItem.part.id, newQuantity);

      // Call CartUpdate API to sync with server
      try {
        print(
          '🛒 Updating cart quantity on server: ${widget.cartItem.part.id} -> $newQuantity',
        );

        final response = await widget.cartOperationsService.updateCartQuantity(
          itemId: widget.cartItem.part.id,
          quantity: newQuantity,
        );

        print('✅ Cart quantity update response: $response');

        // Check if the update was successful and refresh cart totals
        if (response['success'] == true || response['Success'] == true) {
          print('🔄 Cart update successful, refreshing cart totals...');
          // Call the parent widget's method to refresh cart totals only
          if (widget.onCartUpdated != null) {
            widget.onCartUpdated!();
          }
        }
      } catch (e) {
        print('❌ Error updating cart quantity on server: $e');
        // Note: We don't show error to user here as the local cart is already updated
        // The user can still see the updated quantity locally
      }

      // Consumer will automatically rebuild when CartService notifies listeners
    }
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
      _editingQuantity = _quantity;
    });
    _focusNode?.requestFocus();
    // Notify parent about edit mode change
    widget.onEditModeChanged?.call(true);
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _quantityController.text = _quantity.toString();
    });
    _focusNode?.unfocus();
    // Notify parent about edit mode change
    widget.onEditModeChanged?.call(false);
  }

  void _confirmEditing() {
    final int? parsedQuantity = int.tryParse(_quantityController.text);
    if (parsedQuantity != null && parsedQuantity >= 1) {
      _updateQuantity(parsedQuantity);
    } else {
      _cancelEditing();
    }
  }

  void _onQuantityTextChanged(String value) {
    // Don't update immediately on every keystroke to avoid conflicts
    // Only update when user finishes typing (onSubmitted)
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 36,
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.borderColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Minus Button
              SizedBox(
                width: 36,
                height: 36,
                child: IconButton(
                  icon: const Icon(Icons.remove_outlined, size: 16),
                  onPressed: _quantity > 1
                      ? () => _updateQuantity(_quantity - 1)
                      : null,
                  padding: const EdgeInsets.all(4),
                ),
              ),
              // Quantity Input Field
              SizedBox(
                width: 54,
                height: 36,
                child: TextField(
                  controller: _quantityController,
                  focusNode: _focusNode,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  textInputAction:
                      TextInputAction.done, // ✅ Ensures iOS shows "Done" button
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 2),
                  ),
                  onChanged: _onQuantityTextChanged,
                  onTap: () {
                    // Start editing mode when user taps on the field
                    if (!_isEditing) {
                      _startEditing();
                    }
                  },
                  onSubmitted: (value) {
                    final int? parsedQuantity = int.tryParse(value);
                    if (parsedQuantity != null && parsedQuantity >= 1) {
                      _updateQuantity(parsedQuantity);
                    } else {
                      // Reset to current quantity if invalid input
                      _quantityController.text = _quantity.toString();
                    }
                    // Unfocus after submission
                    _focusNode?.unfocus();
                  },
                ),
              ),
              // Plus Button
              SizedBox(
                width: 36,
                height: 36,
                child: IconButton(
                  icon: const Icon(Icons.add_outlined, size: 16),
                  onPressed: () => _updateQuantity(_quantity + 1),
                  padding: const EdgeInsets.all(4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Cart Item Details Dialog - With quantity controls
class CartItemDetailsDialog extends StatefulWidget {
  final Part part;
  final int initialQuantity;
  final Function(int) onQuantityChanged;
  final VoidCallback? onCartUpdated;

  const CartItemDetailsDialog({
    super.key,
    required this.part,
    required this.initialQuantity,
    required this.onQuantityChanged,
    this.onCartUpdated,
  });

  @override
  State<CartItemDetailsDialog> createState() => _CartItemDetailsDialogState();
}

class _CartItemDetailsDialogState extends State<CartItemDetailsDialog> {
  late int _quantity;
  late int
  _originalQuantity; // Store original quantity for cancel functionality
  Part? _detailedPart;
  bool _isLoadingDetails = true;
  String? _errorMessage;
  late TextEditingController _quantityController;
  late FocusNode _focusNode;
  late CartOperationsService _cartOperationsService;
  bool _isEditing = false; // Track if user is editing quantity
  int _editingQuantity = 0; // Store quantity being edited

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialQuantity;
    _originalQuantity =
        widget.initialQuantity; // Store original quantity for cancel
    _quantityController = TextEditingController(text: _quantity.toString());
    _focusNode = FocusNode();
    _cartOperationsService = GetIt.instance<CartOperationsService>();
    _fetchDetailedPartData();

    // Add focus listener for iOS-specific handling
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        print('🔧 CartItemDetailsDialog: Focus lost, validating quantity');
        // Validate and update quantity when focus is lost
        final int? parsedQuantity = int.tryParse(_quantityController.text);
        if (parsedQuantity != null &&
            parsedQuantity >= 1 &&
            parsedQuantity <= 999) {
          if (parsedQuantity != _quantity) {
            print(
              '🔧 CartItemDetailsDialog: Quantity changed on focus loss: $_quantity -> $parsedQuantity',
            );
            _updateQuantityDirect(parsedQuantity);
          }
        } else {
          // Reset to current quantity if invalid
          _quantityController.text = _quantity.toString();
        }
      }
    });
  }

  Future<void> _fetchDetailedPartData() async {
    try {
      setState(() {
        _isLoadingDetails = true;
        _errorMessage = null;
      });

      // Get detailed part data from cached parts
      final partsDataService = GetIt.instance<PartsDataService>();
      final detailedPart = partsDataService.getPartById(widget.part.id);

      setState(() {
        _detailedPart = detailedPart;
        _isLoadingDetails = false;
      });
    } catch (e) {
      print('❌ Error fetching detailed part data: $e');
      setState(() {
        _errorMessage = 'Failed to load detailed part information';
        _isLoadingDetails = false;
      });
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _updateQuantity(int delta) async {
    final newQuantity = (_quantity + delta).clamp(1, 999);
    print(
      '🔧 CartItemDetailsDialog: _updateQuantity called with delta: $delta, newQuantity: $newQuantity',
    );
    await _updateQuantityDirect(newQuantity);
  }

  Future<void> _updateQuantityDirect(int newQuantity) async {
    debugPrint(
      'CartItemDetailsDialog: _updateQuantityDirect called with new quantity: $newQuantity',
    );

    if (newQuantity >= 1) {
      setState(() {
        _quantity = newQuantity;
        _quantityController.text = _quantity.toString();
        _isEditing = false; // Exit edit mode
      });

      // Update local cart service first
      debugPrint(
        'CartItemDetailsDialog: calling cartService.updateQuantity for ${widget.part.id}',
      );

      // Get CartService from context
      final cartService = Provider.of<CartService>(context, listen: false);
      cartService.updateQuantity(widget.part.id, newQuantity);

      // Call CartUpdate API to sync with server
      try {
        print(
          '🛒 Updating cart quantity on server: ${widget.part.id} -> $newQuantity',
        );

        final response = await _cartOperationsService.updateCartQuantity(
          itemId: widget.part.id,
          quantity: newQuantity,
        );

        print('✅ Cart quantity update response: $response');

        // Check if the update was successful
        if (response['success'] == true || response['Success'] == true) {
          print('🔄 Cart update successful');
          // Notify parent of quantity change
          widget.onQuantityChanged(_quantity);
          // Refresh cart totals from server to update Bill Details
          widget.onCartUpdated?.call();
        }
      } catch (e) {
        print('❌ Error updating cart quantity on server: $e');
        // Note: We don't show error to user here as the local cart is already updated
        // The user can still see the updated quantity locally
        // Notify parent of quantity change even if server update fails
        widget.onQuantityChanged(_quantity);
        // Refresh cart totals from server to update Bill Details
        widget.onCartUpdated?.call();
      }
    }
  }

  void _cancelChanges() async {
    print(
      '🔧 CartItemDetailsDialog: Cancel button pressed, reverting to original quantity: $_originalQuantity',
    );

    // Revert to original quantity
    setState(() {
      _quantity = _originalQuantity;
      _quantityController.text = _quantity.toString();
    });

    // Update local cart service to original quantity
    final cartService = Provider.of<CartService>(context, listen: false);
    cartService.updateQuantity(widget.part.id, _originalQuantity);

    // Call CartUpdate API to sync with server
    try {
      print(
        '🛒 Reverting cart quantity on server: ${widget.part.id} -> $_originalQuantity',
      );

      final response = await _cartOperationsService.updateCartQuantity(
        itemId: widget.part.id,
        quantity: _originalQuantity,
      );

      print('✅ Cart quantity revert response: $response');

      // Check if the revert was successful
      if (response['success'] == true || response['Success'] == true) {
        print('🔄 Cart revert successful');
        // Notify parent of quantity change
        widget.onQuantityChanged(_quantity);
      }
    } catch (e) {
      print('❌ Error reverting cart quantity on server: $e');
      // Notify parent of quantity change even if server update fails
      widget.onQuantityChanged(_quantity);
    }

    // Close the dialog
    Navigator.of(context).pop();
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
      _editingQuantity = _quantity;
    });
    _focusNode.requestFocus();
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _quantityController.text = _quantity.toString();
    });
    _focusNode.unfocus();
  }

  void _confirmEditing() {
    final int? parsedQuantity = int.tryParse(_quantityController.text);
    if (parsedQuantity != null &&
        parsedQuantity >= 1 &&
        parsedQuantity <= 999) {
      _updateQuantityDirect(parsedQuantity);
    } else {
      _cancelEditing();
    }
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
              child: _isLoadingDetails
                  ? _buildLoadingState()
                  : _errorMessage != null
                  ? _buildErrorState()
                  : _buildContent(),
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
                                          ? () {
                                              print(
                                                '🔧 CartItemDetailsDialog: Decrease button tapped',
                                              );
                                              _updateQuantity(-1);
                                            }
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
                                  Container(
                                    width: 50,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      border: Border(
                                        left: BorderSide(
                                          color: AppTheme.borderColor,
                                          width: 1,
                                        ),
                                        right: BorderSide(
                                          color: AppTheme.borderColor,
                                          width: 1,
                                        ),
                                      ),
                                    ),
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
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 8,
                                        ),
                                      ),
                                      onTap: () {
                                        // Start editing mode when user taps on the field
                                        if (!_isEditing) {
                                          _startEditing();
                                        }
                                      },
                                      onSubmitted: (value) async {
                                        print(
                                          '🔧 CartItemDetailsDialog: onSubmitted called with value: $value',
                                        );
                                        final int? parsedQuantity =
                                            int.tryParse(value);
                                        if (parsedQuantity != null &&
                                            parsedQuantity >= 1 &&
                                            parsedQuantity <= 999) {
                                          print(
                                            '🔧 CartItemDetailsDialog: Valid quantity submitted: $parsedQuantity',
                                          );
                                          await _updateQuantityDirect(
                                            parsedQuantity,
                                          );
                                          // Unfocus after submission on iOS
                                          _focusNode.unfocus();
                                        } else {
                                          print(
                                            '🔧 CartItemDetailsDialog: Invalid quantity, resetting to: $_quantity',
                                          );
                                          _quantityController.text = _quantity
                                              .toString();
                                        }
                                      },
                                      onChanged: (value) {
                                        // Allow empty string during editing
                                        if (value.isEmpty) return;

                                        final int? parsedQuantity =
                                            int.tryParse(value);
                                        if (parsedQuantity != null &&
                                            parsedQuantity >= 1 &&
                                            parsedQuantity <= 999) {
                                          setState(() {
                                            _quantity = parsedQuantity;
                                          });
                                        }
                                      },
                                    ),
                                  ),

                                  // Increase Button
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        print(
                                          '🔧 CartItemDetailsDialog: Increase button tapped',
                                        );
                                        _updateQuantity(1);
                                      },
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
                      if ((_detailedPart?.mrp ?? widget.part.mrp) != null)
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
                                      _detailedPart?.mrp ?? widget.part.mrp,
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
                                      _detailedPart?.netPrice ??
                                          _detailedPart?.mrp ??
                                          widget.part.netPrice ??
                                          widget.part.mrp,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 13, // Reduced from 15
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

                  // Action Buttons - Cancel and Update Cart
                  Row(
                    children: [
                      // Cancel Button
                      Expanded(
                        flex: 2,
                        child: OutlinedButton(
                          onPressed: _cancelChanges,
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

                      // Update Cart Button
                      Expanded(
                        flex: 3,
                        child: ElevatedButton(
                          onPressed: () async {
                            // Sync current quantity with server before closing
                            await _updateQuantityDirect(_quantity);
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
                                'Update Cart',
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

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryColor),
            SizedBox(height: 16),
            Text(
              'Loading part details...',
              style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Failed to load part details',
              style: const TextStyle(fontSize: 16, color: AppTheme.errorColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchDetailedPartData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final partToDisplay = _detailedPart ?? widget.part;

    return SingleChildScrollView(
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
          _buildInfoRow('Part Number', partToDisplay.item),
          if (partToDisplay.description.isNotEmpty)
            _buildInfoRow('Description', partToDisplay.description),
          if (partToDisplay.brand.isNotEmpty)
            _buildInfoRow('Brand', partToDisplay.brand),
          if (partToDisplay.vehicleMake.isNotEmpty)
            _buildInfoRow('Vehicle Make', partToDisplay.vehicleMake),
          if (partToDisplay.model.isNotEmpty)
            _buildInfoRow('Vehicle Model', partToDisplay.model),
          if (partToDisplay.category.isNotEmpty)
            _buildInfoRow('Category', partToDisplay.category),
          if (partToDisplay.subCategory.isNotEmpty)
            _buildInfoRow('Sub Category', partToDisplay.subCategory),
          if (partToDisplay.part.isNotEmpty)
            _buildInfoRow('Part Name', partToDisplay.part),
          if (partToDisplay.type.isNotEmpty)
            _buildInfoRow('Type', partToDisplay.type),
          if (partToDisplay.size.isNotEmpty)
            _buildInfoRow('Size', partToDisplay.size),
        ],
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
