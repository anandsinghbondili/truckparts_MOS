import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/api_service_base.dart';
import '../../../../core/errors/failures.dart';
import 'order_service.dart';

/// Service for fetching sales order information from the server
class SalesOrderApiService extends ApiServiceBase {
  SalesOrderApiService({required super.dio, required super.appContext});

  /// Get sales order information (order history)
  ///
  /// API: GET /api/Mobileapp/GetSalesOrderInfo?OPUnit=&CustomerId={{CustomerID}}&EmployeeId=&SearchData=&AcOwner={{AcOwner}}&AppType={{AppType}}&TokenId={{tokenID}}
  ///
  /// Returns sales order information response
  Future<Map<String, dynamic>> getSalesOrderInfo() async {
    if (!isContextReady) {
      throw SalesOrderException(contextNotReadyMessage);
    }

    try {
      print('📋 SalesOrderApiService: Fetching sales order information');

      // Use the correct API endpoint with proper parameters
      final orderParams = {
        'OPUnit': '', // Empty as per API specification
        'CustomerId': appContext.customerId,
        'EmployeeId': '', // Empty as per API specification
        'SearchData': '', // Empty as per API specification
        'AcOwner': appContext.acOwner,
        'AppType': appContext.appType,
        'TokenId': appContext.tokenId,
      };

      final response = await getWithContext(
        '/api/Mobileapp/GetSalesOrderInfo',
        queryParameters: orderParams,
      );

      print('✅ Sales Order Info Response: ${response.data}');

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print('❌ SalesOrderApiService: DioException: ${e.message}');
      print('❌ Response: ${e.response?.data}');
      throw _handleDioException(e);
    } catch (e) {
      print('❌ SalesOrderApiService: Unexpected error: ${e.toString()}');
      throw SalesOrderException('Unexpected error: ${e.toString()}');
    }
  }

  /// Handle Dio exceptions
  SalesOrderException _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return SalesOrderException(
          'Connection timeout. Please check your internet connection.',
          e.response?.statusCode,
        );
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['message'] ?? 'Request failed';
        return SalesOrderException(message, statusCode);
      case DioExceptionType.cancel:
        return SalesOrderException('Request cancelled');
      default:
        return SalesOrderException(
          'Network error: ${e.message}',
          e.response?.statusCode,
        );
    }
  }
}

/// Response model for sales order information
class SalesOrderInfoResponse {
  final bool success;
  final String? message;
  final List<SalesOrder>? orders;

  SalesOrderInfoResponse({required this.success, this.message, this.orders});

  factory SalesOrderInfoResponse.fromJson(Map<String, dynamic> json) {
    List<SalesOrder>? orders;

    // Parse orders from different possible locations
    if (json['orders'] != null) {
      orders = (json['orders'] as List)
          .map((order) => SalesOrder.fromJson(order))
          .toList();
    } else if (json['parameters'] != null && json['parameters'] is List) {
      // Parameters is directly a list of orders
      orders = (json['parameters'] as List)
          .map((order) => SalesOrder.fromJson(order))
          .toList();
    } else if (json['parameters'] != null &&
        json['parameters']['orders'] != null) {
      orders = (json['parameters']['orders'] as List)
          .map((order) => SalesOrder.fromJson(order))
          .toList();
    } else if (json['parameters'] != null &&
        json['parameters']['salesOrders'] != null) {
      orders = (json['parameters']['salesOrders'] as List)
          .map((order) => SalesOrder.fromJson(order))
          .toList();
    } else if (json['data'] != null && json['data'] is List) {
      orders = (json['data'] as List)
          .map((order) => SalesOrder.fromJson(order))
          .toList();
    }

    return SalesOrderInfoResponse(
      success: json['success'] ?? json['Success'] ?? false,
      message: json['message'] ?? json['Message'],
      orders: orders,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'orders': orders?.map((order) => order.toJson()).toList(),
    };
  }
}

/// Sales order model
class SalesOrder {
  final String id;
  final String orderNumber;
  final String? orderNo; // Order number for Order History
  final String? transNo; // Transaction number from API
  final DateTime orderDate;
  final String status;
  final double totalAmount;
  final int itemCount;
  final String? customerName;
  final String? customerId;
  final String? rowId; // This is important for order details API
  final List<SalesOrderItem>? items;

  SalesOrder({
    required this.id,
    required this.orderNumber,
    this.orderNo,
    this.transNo,
    required this.orderDate,
    required this.status,
    required this.totalAmount,
    required this.itemCount,
    this.customerName,
    this.customerId,
    this.rowId,
    this.items,
  });

  factory SalesOrder.fromJson(Map<String, dynamic> json) {
    // Parse date - handle different date formats
    DateTime orderDate;
    try {
      final dateStr =
          json['Date'] ??
          json['orderDate'] ??
          json['OrderDate'] ??
          json['sodate'] ??
          json['SODate'];
      if (dateStr != null) {
        // Try different date formats
        if (dateStr.toString().contains('/')) {
          // Format: dd/MM/yyyy (Indian date format)
          // Example: "10/02/2025" = 10th February 2025
          final parts = dateStr.toString().split('/');
          if (parts.length == 3) {
            orderDate = DateTime(
              int.parse(parts[2]), // year
              int.parse(parts[1]), // month (FIXED: was parts[0])
              int.parse(parts[0]), // day (FIXED: was parts[1])
            );
            print(
              '📅 Date parsed: ${parts[0]}/${parts[1]}/${parts[2]} → ${DateFormat('dd MMM yyyy').format(orderDate)}',
            );
          } else {
            orderDate = DateTime.now();
          }
        } else {
          orderDate = DateTime.parse(dateStr.toString());
        }
      } else {
        orderDate = DateTime.now();
      }
    } catch (e) {
      print('⚠️ Error parsing date: ${json['Date']}, using current date');
      orderDate = DateTime.now();
    }

    // Parse items if available
    List<SalesOrderItem>? items;
    if (json['items'] != null) {
      items = (json['items'] as List)
          .map((item) => SalesOrderItem.fromJson(item))
          .toList();
    }

    return SalesOrder(
      id:
          json['orderid'] ??
          json['id'] ??
          json['Id'] ??
          json['orderId'] ??
          json['OrderId'] ??
          '',
      orderNumber:
          json['orderNo'] ??
          json['orderNumber'] ??
          json['OrderNumber'] ??
          json['sono'] ??
          json['SONo'] ??
          '',
      orderNo: json['orderNo'] ?? json['OrderNo'],
      transNo: json['transNo'] ?? json['TransNo'],
      orderDate: orderDate,
      status:
          json['status'] ??
          json['Status'] ??
          json['orderStatus'] ??
          json['OrderStatus'] ??
          'Pending',
      totalAmount: _parseDouble(
        json['totalAmount'] ??
            json['TotalAmount'] ??
            json['grandTotal'] ??
            json['GrandTotal'],
      ),
      itemCount:
          json['itemCount'] ??
          json['ItemCount'] ??
          json['quantity'] ??
          json['Quantity'] ??
          0,
      customerName:
          json['customerName'] ??
          json['CustomerName'] ??
          json['customer'] ??
          json['Customer'],
      customerId:
          json['customerId'] ??
          json['CustomerId'] ??
          json['customerID'] ??
          json['CustomerID'],
      rowId:
          json['rowId'] ??
          json['RowId'] ??
          json['id'] ??
          json['Id'], // Use id as fallback for rowId
      items: items,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'orderDate': orderDate.toIso8601String(),
      'status': status,
      'totalAmount': totalAmount,
      'itemCount': itemCount,
      'customerName': customerName,
      'customerId': customerId,
      'rowId': rowId,
      'items': items?.map((item) => item.toJson()).toList(),
    };
  }

  /// Convert to Order model for compatibility with existing UI
  Order toOrder() {
    return Order(
      id: id,
      orderNo: orderNo,
      transNo: transNo,
      date: orderDate,
      status: status,
      totalAmount: totalAmount,
      itemCount: itemCount,
      items: items?.map((item) => item.toOrderItem()).toList() ?? [],
    );
  }
}

/// Sales order item model
class SalesOrderItem {
  final String id;
  final String partName;
  final String brand;
  final String size;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  SalesOrderItem({
    required this.id,
    required this.partName,
    required this.brand,
    required this.size,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory SalesOrderItem.fromJson(Map<String, dynamic> json) {
    return SalesOrderItem(
      id: json['id'] ?? json['Id'] ?? json['itemId'] ?? json['ItemId'] ?? '',
      partName:
          json['partName'] ??
          json['PartName'] ??
          json['item'] ??
          json['Item'] ??
          '',
      brand: json['brand'] ?? json['Brand'] ?? '',
      size: json['size'] ?? json['Size'] ?? '',
      quantity: json['quantity'] ?? json['Quantity'] ?? 1,
      unitPrice: SalesOrder._parseDouble(
        json['unitPrice'] ??
            json['UnitPrice'] ??
            json['price'] ??
            json['Price'],
      ),
      totalPrice: SalesOrder._parseDouble(
        json['totalPrice'] ??
            json['TotalPrice'] ??
            json['subtotal'] ??
            json['Subtotal'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'partName': partName,
      'brand': brand,
      'size': size,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
    };
  }

  /// Convert to OrderItem model for compatibility with existing UI
  OrderItem toOrderItem() {
    return OrderItem(
      partId: id,
      partName: partName,
      brand: brand,
      size: size,
      quantity: quantity,
      unitPrice: unitPrice,
      totalPrice: totalPrice,
    );
  }
}

/// Custom exception for sales order operations
class SalesOrderException extends Failure {
  final String message;
  final int? statusCode;

  const SalesOrderException(this.message, [this.statusCode]);

  @override
  List<Object?> get props => [message, statusCode];

  @override
  String toString() => 'SalesOrderException: $message';
}
