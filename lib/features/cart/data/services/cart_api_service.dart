import 'package:dio/dio.dart';
import '../../../../core/services/api_service_base.dart';

/// Cart API Service for fetching cart details from server
///
/// API: GET /api/Mobileapp/GetCartDetails
/// Parameters from app context:
/// - AcOwner
/// - AppType
/// - TokenId
class CartApiService extends ApiServiceBase {
  CartApiService({required super.dio, required super.appContext});

  /// Get cart details from server
  ///
  /// API: GET /api/Mobileapp/GetCartDetails?AcOwner={{AcOwner}}&TokenId={{TokenId}}&AppType={{AppType}}
  ///
  /// Returns cart details including items, quantities, and prices
  Future<Map<String, dynamic>> getCartDetails() async {
    if (!isContextReady) {
      throw CartApiException(contextNotReadyMessage);
    }

    try {
      print('🛒 CartApiService: Fetching cart details');

      final response = await getWithContext(
        '/api/Mobileapp/GetCartDetails',
        queryParameters: {'TokenId': appContext.tokenId},
      );

      print('✅ Cart Details Response: ${response.data}');

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print('❌ CartApiService: DioException: ${e.message}');
      print('❌ Response: ${e.response?.data}');
      throw _handleDioException(e);
    } catch (e) {
      print('❌ CartApiService: Unexpected error: ${e.toString()}');
      throw CartApiException('Unexpected error: ${e.toString()}');
    }
  }

  /// Handle Dio exceptions
  CartApiException _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return CartApiException(
          'Connection timeout. Please check your internet connection.',
          e.response?.statusCode,
        );
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['message'] ?? 'Request failed';
        return CartApiException(message, statusCode);
      case DioExceptionType.cancel:
        return CartApiException('Request cancelled');
      default:
        return CartApiException(
          'Network error: ${e.message}',
          e.response?.statusCode,
        );
    }
  }
}

/// Custom exception for cart API operations
class CartApiException implements Exception {
  final String message;
  final int? statusCode;

  CartApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'CartApiException: $message';
}

/// Response model for cart details
class CartDetailsResponse {
  final bool success;
  final String? message;
  final List<CartItemData>? items;
  final double? subTotal;
  final double? taxAmount;
  final double? totalAmount;
  final Map<String, dynamic>? data;

  CartDetailsResponse({
    required this.success,
    this.message,
    this.items,
    this.subTotal,
    this.taxAmount,
    this.totalAmount,
    this.data,
  });

  factory CartDetailsResponse.fromJson(Map<String, dynamic> json) {
    List<CartItemData>? items;
    double? subTotal;
    double? taxAmount;
    double? totalAmount;

    // Parse items from different possible locations
    if (json['items'] != null) {
      // Direct items array
      items = (json['items'] as List)
          .map((item) => CartItemData.fromJson(item))
          .toList();
    } else if (json['data'] != null && json['data']['items'] != null) {
      // Items in data object
      items = (json['data']['items'] as List)
          .map((item) => CartItemData.fromJson(item))
          .toList();
    } else if (json['parameters'] != null &&
        json['parameters']['cartitems'] != null) {
      // Items in parameters.cartitems (actual server response structure)
      items = (json['parameters']['cartitems'] as List)
          .map((item) => CartItemData.fromJson(item))
          .toList();
    }

    // Parse totals from parameters object (server response structure)
    if (json['parameters'] != null) {
      final parameters = json['parameters'];
      subTotal = CartItemData._parseDouble(parameters['SubTotal']);
      taxAmount = CartItemData._parseDouble(parameters['TaxAmount']);
      totalAmount = CartItemData._parseDouble(parameters['TotalAmount']);
    } else {
      // Fallback to direct fields
      subTotal = CartItemData._parseDouble(
        json['subTotal'] ?? json['SubTotal'],
      );
      taxAmount = CartItemData._parseDouble(
        json['taxAmount'] ?? json['TaxAmount'],
      );
      totalAmount = CartItemData._parseDouble(
        json['totalAmount'] ?? json['TotalAmount'],
      );
    }

    return CartDetailsResponse(
      success: json['success'] ?? json['Success'] ?? false,
      message: json['message'] ?? json['Message'],
      items: items,
      subTotal: subTotal,
      taxAmount: taxAmount,
      totalAmount: totalAmount,
      data: json['data'] ?? json['Data'] ?? json['parameters'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'items': items?.map((item) => item.toJson()).toList(),
      'subTotal': subTotal,
      'taxAmount': taxAmount,
      'totalAmount': totalAmount,
      'data': data,
    };
  }
}

/// Model for individual cart item from API
class CartItemData {
  final String id;
  final String? partNumber;
  final String? partName;
  final String? description;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String? brand;
  final String? category;
  final Map<String, dynamic>? additionalData;

  CartItemData({
    required this.id,
    this.partNumber,
    this.partName,
    this.description,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.brand,
    this.category,
    this.additionalData,
  });

  factory CartItemData.fromJson(Map<String, dynamic> json) {
    return CartItemData(
      id:
          json['id']?.toString() ??
          json['Id']?.toString() ??
          json['itemid']?.toString() ??
          json['ItemId']?.toString() ??
          '',
      partNumber:
          json['partNumber'] ??
          json['PartNumber'] ??
          json['item'] ??
          json['Item'],
      partName:
          json['partName'] ??
          json['PartName'] ??
          json['name'] ??
          json['Name'] ??
          json['item'] ??
          json['Item'],
      description:
          json['description'] ??
          json['Description'] ??
          json['uomname'] ??
          json['UomName'],
      quantity: _parseInt(
        json['quantity'] ?? json['Quantity'] ?? json['qty'] ?? json['Qty'] ?? 1,
      ),
      unitPrice: _parseDouble(
        json['price'] ?? // Server sends "price" as unit price
            json['Price'] ??
            json['unitPrice'] ??
            json['UnitPrice'] ??
            0,
      ),
      totalPrice: _parseDouble(
        json['subtotal'] ?? // Server sends "subtotal" as item total (price × qty)
            json['SubTotal'] ??
            json['totalPrice'] ??
            json['TotalPrice'] ??
            0,
      ),
      brand: json['brand'] ?? json['Brand'] ?? '',
      category:
          json['category'] ??
          json['Category'] ??
          json['uomname'] ??
          json['UomName'],
      additionalData: json,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'partNumber': partNumber,
      'partName': partName,
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'brand': brand,
      'category': category,
      ...?additionalData,
    };
  }

  /// Helper method to safely parse integer values from JSON
  static int _parseInt(dynamic value) {
    if (value == null) return 1;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? 1;
    }
    if (value is double) return value.toInt();
    return 1;
  }

  /// Helper method to safely parse double values from JSON
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }
}
