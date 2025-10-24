import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';
import 'dart:convert';

import '../../../home/domain/entities/part.dart';
import 'cart_operations_service.dart';

class CartItem {
  final Part part;
  int quantity;
  final double unitPrice;
  final double subtotal; // From API: price × quantity (WITHOUT tax)
  final double taxAmount; // From API: tax amount for this item
  final double totalAmount; // From API: total WITH tax (subtotal + taxAmount)

  CartItem({
    required this.part,
    required this.quantity,
    required this.unitPrice,
    this.subtotal = 0.0,
    this.taxAmount = 0.0,
    this.totalAmount = 0.0,
  });

  // Calculate total price including tax: (Net Price + Tax) × Quantity
  double get totalPrice {
    if (totalAmount > 0) {
      // Use server-calculated total if available
      return totalAmount;
    }
    // Calculate: (Net Price + Tax) × Quantity
    final unitPriceWithTax =
        unitPrice + (taxAmount / quantity.clamp(1, double.infinity));
    return unitPriceWithTax * quantity;
  }

  // Get unit price including tax (Net Price + Tax)
  double get unitPriceWithTax {
    if (quantity > 0 && taxAmount > 0) {
      return unitPrice + (taxAmount / quantity);
    }
    return unitPrice;
  }

  Map<String, dynamic> toJson() {
    return {
      'part': {
        'id': part.id,
        'category': part.category,
        'subCategory': part.subCategory,
        'vehicleMake': part.vehicleMake,
        'model': part.model,
        'type': part.type,
        'part': part.part,
        'size': part.size,
        'brand': part.brand,
        'item': part.item,
        'price': part.price,
        'mrp': part.mrp,
        'netPrice': part.netPrice,
        'description': part.description,
      },
      'quantity': quantity,
      'unitPrice': unitPrice,
      'subtotal': subtotal,
      'taxAmount': taxAmount,
      'totalAmount': totalAmount,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final partJson = json['part'] as Map<String, dynamic>;
    final part = Part(
      id: partJson['id'] ?? '',
      category: partJson['category'] ?? '',
      subCategory: partJson['subCategory'] ?? '',
      vehicleMake: partJson['vehicleMake'] ?? '',
      model: partJson['model'] ?? '',
      type: partJson['type'] ?? '',
      part: partJson['part'] ?? '',
      size: partJson['size'] ?? '',
      brand: partJson['brand'] ?? '',
      item: partJson['item'] ?? '',
      price: (partJson['price'] as num?)?.toDouble(),
      mrp: (partJson['mrp'] as num?)?.toDouble(),
      netPrice: (partJson['netPrice'] as num?)?.toDouble(),
      description: partJson['description'] ?? '',
    );

    return CartItem(
      part: part,
      quantity: json['quantity'] ?? 1,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class CartService extends ChangeNotifier {
  static const String _cartKey = 'cart_items';
  List<CartItem> _cartItems = [];

  List<CartItem> get cartItems => _cartItems;
  int get itemCount => _cartItems.fold(0, (sum, item) => sum + item.quantity);
  double get totalAmount =>
      _cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);

  Future<void> loadCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString(_cartKey);

      if (cartJson != null) {
        final List<dynamic> cartList = json.decode(cartJson);
        _cartItems = cartList.map((item) => CartItem.fromJson(item)).toList();
      } else {
        _cartItems = [];
      }
      notifyListeners();
    } catch (e) {
      _cartItems = [];
      notifyListeners();
    }
  }

  Future<void> addToCart(Part part, int quantity) async {
    try {
      print('🛒 CartService: Adding to cart - ${part.item} (qty: $quantity)');

      // Check if item already exists in cart for smart merge logic
      final existingIndex = _cartItems.indexWhere(
        (item) => item.part.id == part.id,
      );

      bool shouldUpdateServer = true;
      int serverQuantity = quantity;

      if (existingIndex != -1) {
        // Smart merge logic: Update only if cart quantity < new quantity
        final oldItem = _cartItems[existingIndex];
        final cartQuantity = oldItem.quantity;
        final newQuantity = quantity;

        print('🔄 Smart Cart Merge: Item ${part.item}');
        print('   - Cart quantity: $cartQuantity');
        print('   - New quantity: $newQuantity');

        if (cartQuantity < newQuantity) {
          // Update to new quantity (business rule: update only if cart_qty < new_qty)
          print('   ✅ Updating quantity: $cartQuantity → $newQuantity');
          serverQuantity = newQuantity;
        } else {
          // Keep existing quantity (cart_qty >= new_qty)
          print(
            '   ⏭️ Keeping existing quantity: $cartQuantity (cart_qty >= new_qty)',
          );
          shouldUpdateServer = false;
        }
      }

      // Call SaveCartData API to save to server (only if needed)
      if (shouldUpdateServer) {
        final cartOpsService = GetIt.instance<CartOperationsService>();
        final response = await cartOpsService.addToCart(
          itemId: part.id,
          itemName: part.item,
          quantity: serverQuantity,
        );

        print(
          '✅ Item added to server cart: ${response['message'] ?? 'Success'}',
        );
      } else {
        print('⏭️ Skipping server update - keeping existing quantity');
      }

      // Update local cart for immediate UI update
      if (existingIndex != -1) {
        final oldItem = _cartItems[existingIndex];
        final cartQuantity = oldItem.quantity;
        final newQuantity = quantity;

        if (cartQuantity < newQuantity) {
          // Update to new quantity
          final unitPrice = oldItem.unitPrice;
          final taxPerUnit = oldItem.quantity > 0
              ? oldItem.taxAmount / oldItem.quantity
              : 0.0;
          final unitPriceWithTax = unitPrice + taxPerUnit;
          final calculatedSubtotal = unitPrice * newQuantity;
          final calculatedTaxAmount = taxPerUnit * newQuantity;
          final calculatedTotalAmount = unitPriceWithTax * newQuantity;

          _cartItems[existingIndex] = CartItem(
            part: oldItem.part,
            quantity: newQuantity,
            unitPrice: unitPrice,
            subtotal: calculatedSubtotal,
            taxAmount: calculatedTaxAmount, // Maintain tax proportionally
            totalAmount: calculatedTotalAmount, // Total with tax
          );
        }
        // If cart_qty >= new_qty, do nothing (keep existing)
      } else {
        // Add new item to cart with calculated values
        final unitPrice = part.netPrice ?? part.price ?? 0.0;
        final calculatedSubtotal = unitPrice * quantity;
        // For new items, we don't have tax info yet, so use unitPrice as total
        final calculatedTotalAmount = unitPrice * quantity;

        _cartItems.add(
          CartItem(
            part: part,
            quantity: quantity,
            unitPrice: unitPrice,
            subtotal: calculatedSubtotal,
            taxAmount: 0.0, // Tax will be calculated by server
            totalAmount:
                calculatedTotalAmount, // For new items, same as subtotal until server sync
          ),
        );
      }

      await _saveCart();
      notifyListeners();

      print('✅ CartService: Cart updated successfully');
    } catch (e) {
      print('❌ CartService: Failed to add to cart: $e');
      rethrow; // Re-throw to allow UI to handle the error
    }
  }

  Future<void> updateQuantity(String partId, int newQuantity) async {
    try {
      debugPrint(
        'CartService: updateQuantity called - partId: $partId, newQuantity: $newQuantity',
      );
      final index = _cartItems.indexWhere((item) => item.part.id == partId);
      debugPrint('CartService: found item at index: $index');

      if (index != -1) {
        if (newQuantity <= 0) {
          debugPrint('CartService: removing item from cart');
          _cartItems.removeAt(index);
        } else {
          debugPrint(
            'CartService: updating quantity from ${_cartItems[index].quantity} to $newQuantity',
          );

          // Update quantity and recalculate temporary totals
          final oldItem = _cartItems[index];
          final unitPrice = oldItem.unitPrice;
          final taxPerUnit = oldItem.quantity > 0
              ? oldItem.taxAmount / oldItem.quantity
              : 0.0;
          final unitPriceWithTax = unitPrice + taxPerUnit;
          final calculatedSubtotal = unitPrice * newQuantity;
          final calculatedTaxAmount = taxPerUnit * newQuantity;
          final calculatedTotalAmount = unitPriceWithTax * newQuantity;

          _cartItems[index] = CartItem(
            part: oldItem.part,
            quantity: newQuantity,
            unitPrice: unitPrice,
            subtotal: calculatedSubtotal,
            taxAmount: calculatedTaxAmount, // Maintain tax proportionally
            totalAmount: calculatedTotalAmount, // Total with tax
          );

          debugPrint(
            'CartService: new totalPrice: ${_cartItems[index].totalPrice}',
          );
        }
        await _saveCart();
        debugPrint(
          'CartService: calling notifyListeners, new totalAmount: $totalAmount',
        );
        notifyListeners();
      } else {
        debugPrint('CartService: item not found with partId: $partId');
      }
    } catch (e) {
      debugPrint('CartService: error in updateQuantity: $e');
    }
  }

  Future<void> removeFromCart(String partId) async {
    try {
      _cartItems.removeWhere((item) => item.part.id == partId);
      await _saveCart();
      notifyListeners();
    } catch (e) {
      // Handle error
    }
  }

  /// Clear cart by deleting all items from server and local storage
  ///
  /// This method:
  /// 1. Calls DeleteCart API for each item
  /// 2. Clears local cart after successful deletion
  Future<void> clearCart() async {
    try {
      print('🛒 CartService: Clearing cart...');
      print('   - Total items: ${_cartItems.length}');

      if (_cartItems.isEmpty) {
        print('   ℹ️  Cart is already empty');
        return;
      }

      // Get CartOperationsService to delete items from server
      try {
        final cartOpsService = GetIt.instance<CartOperationsService>();

        // Convert CartItems to format expected by emptyCart API
        // We need to pass item IDs for the API call
        final itemsToDelete = _cartItems.map((cartItem) {
          return {
            'itemid': cartItem.part.id,
            'id': cartItem.part.id,
            'ItemId': cartItem.part.id,
          };
        }).toList();

        print(
          '   🌐 Calling DeleteCart API for ${itemsToDelete.length} items...',
        );

        // Call API to delete all items from server
        final result = await cartOpsService.emptyCart(cartItems: itemsToDelete);

        print('   📡 API Response: ${result['message']}');
        print('   ✅ Deleted from server: ${result['deletedCount']} items');

        if (result['failedCount'] > 0) {
          print('   ⚠️  Failed to delete: ${result['failedCount']} items');
          // You might want to only clear successfully deleted items
          // For now, we'll clear all locally even if some API calls failed
        }
      } catch (e) {
        print('   ⚠️  API deletion failed: $e');
        print('   ℹ️  Continuing to clear local cart...');
        // Continue to clear local cart even if API fails
      }

      // Clear local cart
      _cartItems.clear();
      await _saveCart();
      notifyListeners();

      print('   ✅ Local cart cleared');
    } catch (e) {
      print('   ❌ Error clearing cart: $e');
      // Handle error but still try to clear local cart
      _cartItems.clear();
      await _saveCart();
      notifyListeners();
    }
  }

  /// Replace entire cart with server data (for syncing)
  /// This method sets the cart items directly without adding to existing quantities
  Future<void> replaceCartWithServerData(List<CartItem> serverItems) async {
    try {
      _cartItems = serverItems;
      await _saveCart();
      notifyListeners();
    } catch (e) {
      debugPrint('CartService: error in replaceCartWithServerData: $e');
    }
  }

  Future<void> _saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = json.encode(
        _cartItems.map((item) => item.toJson()).toList(),
      );
      await prefs.setString(_cartKey, cartJson);
    } catch (e) {
      // Handle error
    }
  }
}
