import 'package:dio/dio.dart';
import '../../../../core/services/api_service_base.dart';
import '../../../../core/errors/failures.dart';

/// Service for cart operations like adding items and updating quantities
class CartOperationsService extends ApiServiceBase {
  CartOperationsService({required super.dio, required super.appContext});

  /// Add item to cart using SaveCartData API
  Future<Map<String, dynamic>> addToCart({
    required String itemId,
    required String itemName,
    required int quantity,
  }) async {
    if (!appContext.isInitialized) {
      throw CartOperationsException(
        'App context not initialized. Please login first.',
      );
    }

    try {
      print('🛒 CartOperationsService: Adding item to cart...');
      print('   - ItemID: $itemId');
      print('   - ItemName: $itemName');
      print('   - Quantity: $quantity');

      final baseUrl = appContext.apiBaseUrl;
      final endpoint = '/api/Mobileapp/SaveCartData';
      final fullUrl = '$baseUrl$endpoint';

      final requestBody = {
        'itemid': itemId,
        'item': itemName,
        'customer': appContext.customerId,
        'quantity': quantity.toString(),
        'phoneno': appContext.userId,
        'Tokenid': appContext.tokenId,
        'AcOwner': appContext.acOwner,
        'Date': DateTime.now().toIso8601String().split(
          'T',
        )[0], // Today's date in YYYY-MM-DD format
        'apptype': appContext.appType,
      };

      print('🌐 SaveCartData URL: $fullUrl');
      print('📋 Request Body: $requestBody');

      final response = await dio.post(
        fullUrl,
        data: requestBody,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      print('📡 SaveCartData Response status: ${response.statusCode}');
      print('📡 SaveCartData Response data: ${response.data}');

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw CartOperationsException(
          'Failed to add item to cart: ${response.statusCode}',
          response.statusCode,
        );
      }
    } on DioException catch (e) {
      print('❌ CartOperationsService: DioException: ${e.message}');
      print('❌ CartOperationsService: Response: ${e.response?.data}');
      throw _handleDioException(e);
    } catch (e) {
      print('❌ CartOperationsService: Unexpected error: ${e.toString()}');
      throw CartOperationsException('Unexpected error: ${e.toString()}');
    }
  }

  /// Update cart item quantity using CartUpdate API
  Future<Map<String, dynamic>> updateCartQuantity({
    required String itemId,
    required int quantity,
  }) async {
    if (!appContext.isInitialized) {
      throw CartOperationsException(
        'App context not initialized. Please login first.',
      );
    }

    try {
      print('🛒 CartOperationsService: Updating cart quantity...');
      print('   - ItemID: $itemId');
      print('   - Quantity: $quantity');

      final baseUrl = appContext.apiBaseUrl;
      final endpoint = '/api/Mobileapp/CartUpdate';
      final fullUrl = '$baseUrl$endpoint';

      final requestBody = {
        'itemid': itemId,
        'quantity': quantity.toString(),
        'Tokenid': appContext.tokenId,
        'AcOwner': appContext.acOwner,
        'apptype': appContext.appType,
      };

      print('🌐 CartUpdate URL: $fullUrl');
      print('📋 Request Body: $requestBody');

      final response = await dio.post(
        fullUrl,
        data: requestBody,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      print('📡 CartUpdate Response status: ${response.statusCode}');
      print('📡 CartUpdate Response data: ${response.data}');

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw CartOperationsException(
          'Failed to update cart quantity: ${response.statusCode}',
          response.statusCode,
        );
      }
    } on DioException catch (e) {
      print('❌ CartOperationsService: DioException: ${e.message}');
      print('❌ CartOperationsService: Response: ${e.response?.data}');
      throw _handleDioException(e);
    } catch (e) {
      print('❌ CartOperationsService: Unexpected error: ${e.toString()}');
      throw CartOperationsException('Unexpected error: ${e.toString()}');
    }
  }

  /// Delete item from cart using DeleteCart API
  Future<Map<String, dynamic>> deleteFromCart({required String itemId}) async {
    if (!appContext.isInitialized) {
      throw CartOperationsException(
        'App context not initialized. Please login first.',
      );
    }

    try {
      print('🛒 CartOperationsService: Deleting item from cart...');
      print('   - ItemID: $itemId');

      final baseUrl = appContext.apiBaseUrl;
      final endpoint = '/api/Mobileapp/DeleteCart';
      final fullUrl = '$baseUrl$endpoint';

      final queryParams = {
        'itemid': itemId,
        'AcOwner': appContext.acOwner,
        'TokenId': appContext.tokenId,
      };

      print('🌐 DeleteCart URL: $fullUrl');
      print('📋 Query Parameters: $queryParams');

      final response = await dio.get(
        fullUrl,
        queryParameters: queryParams,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      print('📡 DeleteCart Response status: ${response.statusCode}');
      print('📡 DeleteCart Response data: ${response.data}');

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw CartOperationsException(
          'Failed to delete item from cart: ${response.statusCode}',
          response.statusCode,
        );
      }
    } on DioException catch (e) {
      print('❌ CartOperationsService: DioException: ${e.message}');
      print('❌ CartOperationsService: Response: ${e.response?.data}');
      throw _handleDioException(e);
    } catch (e) {
      print('❌ CartOperationsService: Unexpected error: ${e.toString()}');
      throw CartOperationsException('Unexpected error: ${e.toString()}');
    }
  }

  /// Empty cart by deleting all items
  ///
  /// Calls the DeleteCart API for each item in the cart
  /// API: GET {{protocol}}://{{host}}:{{port}}/api/Mobileapp/DeleteCart?itemid={{itemid}}&AcOwner={{AcOwner}}&TokenId={{tokenID}}
  ///
  /// [cartItems] - List of cart items to delete
  ///
  /// Returns a map with deletion results
  Future<Map<String, dynamic>> emptyCart({
    required List<dynamic> cartItems,
  }) async {
    if (!appContext.isInitialized) {
      throw CartOperationsException(
        'App context not initialized. Please login first.',
      );
    }

    if (cartItems.isEmpty) {
      print('🛒 CartOperationsService: Cart is already empty');
      return {
        'success': true,
        'message': 'Cart is already empty',
        'deletedCount': 0,
      };
    }

    try {
      print('🛒 CartOperationsService: Emptying cart...');
      print('   - Total items to delete: ${cartItems.length}');

      int successCount = 0;
      int failureCount = 0;
      final List<String> failedItems = [];

      // Delete each item one by one
      for (var item in cartItems) {
        try {
          // Extract item ID - handle different cart item structures
          String? itemId;

          if (item is Map<String, dynamic>) {
            // From API response structure
            itemId =
                item['itemid']?.toString() ??
                item['id']?.toString() ??
                item['ItemId']?.toString();
          } else if (item.toString().contains('part')) {
            // From local CartItem structure - extract part.id
            final partData = item.toString();
            // This is a fallback - ideally pass proper item IDs
            print('⚠️ Warning: Could not extract itemId from: $partData');
          }

          if (itemId == null || itemId.isEmpty) {
            print('❌ Skipping item - no valid ID found');
            failureCount++;
            continue;
          }

          print('   🗑️  Deleting item: $itemId');

          final result = await deleteFromCart(itemId: itemId);

          if (result['success'] == true) {
            successCount++;
            print('   ✅ Deleted item: $itemId');
          } else {
            failureCount++;
            failedItems.add(itemId);
            print('   ❌ Failed to delete item: $itemId');
          }
        } catch (e) {
          failureCount++;
          print('   ❌ Error deleting item: $e');
        }
      }

      print('');
      print('🛒 Cart Empty Operation Complete:');
      print('   ✅ Successfully deleted: $successCount items');
      print('   ❌ Failed to delete: $failureCount items');
      if (failedItems.isNotEmpty) {
        print('   ⚠️  Failed items: ${failedItems.join(", ")}');
      }
      print('');

      return {
        'success': failureCount == 0,
        'message': failureCount == 0
            ? 'All $successCount items deleted successfully'
            : 'Deleted $successCount items, failed to delete $failureCount items',
        'deletedCount': successCount,
        'failedCount': failureCount,
        'failedItems': failedItems,
      };
    } catch (e) {
      print('❌ CartOperationsService: Failed to empty cart: ${e.toString()}');
      throw CartOperationsException('Failed to empty cart: ${e.toString()}');
    }
  }

  /// Handle Dio exceptions
  CartOperationsException _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return CartOperationsException(
          'Connection timeout. Please check your internet connection.',
          e.response?.statusCode,
        );
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['message'] ?? 'Request failed';
        return CartOperationsException(message, statusCode);
      case DioExceptionType.cancel:
        return CartOperationsException('Request cancelled');
      default:
        return CartOperationsException(
          'Network error: ${e.message}',
          e.response?.statusCode,
        );
    }
  }
}

/// Custom exception for cart operations
class CartOperationsException extends Failure {
  final String message;
  final int? statusCode;

  const CartOperationsException(this.message, [this.statusCode]);

  @override
  List<Object?> get props => [message, statusCode];

  @override
  String toString() => 'CartOperationsException: $message';
}
