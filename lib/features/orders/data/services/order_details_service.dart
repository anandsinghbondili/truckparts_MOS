import 'package:dio/dio.dart';
import '../../../../core/services/api_service_base.dart';
import '../../../../core/errors/failures.dart';

/// Service for fetching order details and tracking information
class OrderDetailsService extends ApiServiceBase {
  OrderDetailsService({required super.dio, required super.appContext});

  /// Get order details by RowId
  ///
  /// API: GET /api/Mobileapp/SalesOrderDetails?RowId={{RowId}}&AcOwner={{AcOwner}}&AppType={{AppType}}&TokenId={{TokenId}}
  ///
  /// Returns order details response
  Future<Map<String, dynamic>> getOrderDetails(String rowId) async {
    if (!isContextReady) {
      throw OrderDetailsException(contextNotReadyMessage);
    }

    try {
      print('📋 OrderDetailsService: Fetching order details for RowId: $rowId');

      // Use only the required parameters for order details
      final orderDetailsParams = {
        'RowId': rowId,
        'AcOwner': appContext.acOwner,
        'AppType': appContext.appType,
        'TokenId': appContext.tokenId,
        'OperatingUnit': '123456789', // Empty as per API specification
      };

      final url = buildApiUrl('/api/Mobileapp/SalesOrderDetails');
      print('🌐 API GET: $url');
      print('📋 Parameters: $orderDetailsParams');

      final response = await dio.get(url, queryParameters: orderDetailsParams);

      print('✅ Order Details Response: ${response.data}');

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print('❌ OrderDetailsService: DioException: ${e.message}');
      print('❌ Response: ${e.response?.data}');
      throw _handleDioException(e);
    } catch (e) {
      print('❌ OrderDetailsService: Unexpected error: ${e.toString()}');
      throw OrderDetailsException('Unexpected error: ${e.toString()}');
    }
  }

  /// Get order tracking details by RowId
  ///
  /// API: GET /api/Mobileapp/TrackOrderDetails?RowId={{RowId}}&AcOwner={{AcOwner}}&AppType={{AppType}}&TokenId={{TokenId}}
  ///
  /// Returns order tracking response
  Future<Map<String, dynamic>> getOrderTracking(String rowId) async {
    if (!isContextReady) {
      throw OrderDetailsException(contextNotReadyMessage);
    }

    try {
      print(
        '🚚 OrderDetailsService: Fetching order tracking for RowId: $rowId',
      );

      // Use only the required parameters for order tracking
      final trackingParams = {
        'RowId': rowId,
        'AcOwner': appContext.acOwner,
        'AppType': appContext.appType,
        'TokenId': appContext.tokenId,
      };

      final url = buildApiUrl('/api/Mobileapp/TrackOrderDetails');
      print('🌐 API GET: $url');
      print('📋 Parameters: $trackingParams');

      final response = await dio.get(url, queryParameters: trackingParams);

      print('✅ Order Tracking Response: ${response.data}');

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print('❌ OrderDetailsService: DioException: ${e.message}');
      print('❌ Response: ${e.response?.data}');
      throw _handleDioException(e);
    } catch (e) {
      print('❌ OrderDetailsService: Unexpected error: ${e.toString()}');
      throw OrderDetailsException('Unexpected error: ${e.toString()}');
    }
  }

  /// Handle Dio exceptions
  OrderDetailsException _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return OrderDetailsException(
          'Connection timeout. Please check your internet connection.',
          e.response?.statusCode,
        );
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['message'] ?? 'Request failed';
        return OrderDetailsException(message, statusCode);
      case DioExceptionType.cancel:
        return OrderDetailsException('Request cancelled');
      default:
        return OrderDetailsException(
          'Network error: ${e.message}',
          e.response?.statusCode,
        );
    }
  }
}

/// Response model for order details
class OrderDetailsResponse {
  final bool success;
  final String? message;
  final String? orderId;
  final String? transNo; // Transaction number from API
  final String? orderDate;
  final List<OrderDetailItem>? items;
  final double? subTotal;
  final double? taxAmount;
  final double? totalAmount;
  final Map<String, dynamic>? customerDetails;
  final Map<String, dynamic>? billDetails;

  OrderDetailsResponse({
    required this.success,
    this.message,
    this.orderId,
    this.transNo,
    this.orderDate,
    this.items,
    this.subTotal,
    this.taxAmount,
    this.totalAmount,
    this.customerDetails,
    this.billDetails,
  });

  factory OrderDetailsResponse.fromJson(Map<String, dynamic> json) {
    List<OrderDetailItem>? items;
    Map<String, dynamic>? customerDetails;
    Map<String, dynamic>? billDetails;
    String? orderId;
    String? transNo;
    String? orderDate;
    double? subTotal;
    double? taxAmount;
    double? totalAmount;

    // Parse from the actual API response structure
    if (json['parameters'] != null) {
      final parameters = json['parameters'] as Map<String, dynamic>;

      // Parse primary order details
      if (parameters['primary'] != null) {
        final primary = parameters['primary'] as Map<String, dynamic>;
        transNo = primary['TransNo'];
        orderId = primary['Id'] ?? primary['TransNo'];
        orderDate = primary['Date'];
        subTotal = _parseDouble(primary['SubTotal']);
        taxAmount = _parseDouble(primary['TaxAmount']);
        totalAmount = _parseDouble(primary['TotalAmount']);

        // Customer details from primary
        customerDetails = {
          'customerName': primary['Customer'],
          'customerId': primary['customerid'],
          'vehicleNo': primary['vehicleno'],
          'mechanic': primary['mechanic'],
          'morNo': primary['morno'],
          'dcNo': primary['dcno'],
          'morDate': primary['mordate'],
          'dcDate': primary['dcdate'],
        };

        // Bill details from primary
        billDetails = {
          'subTotal': primary['SubTotal'],
          'taxAmount': primary['TaxAmount'],
          'totalAmount': primary['TotalAmount'],
        };
      }

      // Parse secondary items
      if (parameters['secondary'] != null) {
        items = (parameters['secondary'] as List)
            .map((item) => OrderDetailItem.fromJson(item))
            .toList();
      }
    }

    // Fallback to old structure if new structure not found
    if (items == null) {
      if (json['items'] != null) {
        items = (json['items'] as List)
            .map((item) => OrderDetailItem.fromJson(item))
            .toList();
      } else if (json['parameters'] != null &&
          json['parameters']['items'] != null) {
        items = (json['parameters']['items'] as List)
            .map((item) => OrderDetailItem.fromJson(item))
            .toList();
      }
    }

    if (customerDetails == null) {
      if (json['customerDetails'] != null) {
        customerDetails = json['customerDetails'] as Map<String, dynamic>;
      } else if (json['parameters'] != null &&
          json['parameters']['customerDetails'] != null) {
        customerDetails =
            json['parameters']['customerDetails'] as Map<String, dynamic>;
      }
    }

    if (billDetails == null) {
      if (json['billDetails'] != null) {
        billDetails = json['billDetails'] as Map<String, dynamic>;
      } else if (json['parameters'] != null &&
          json['parameters']['billDetails'] != null) {
        billDetails = json['parameters']['billDetails'] as Map<String, dynamic>;
      }
    }

    return OrderDetailsResponse(
      success: json['success'] ?? json['Success'] ?? false,
      message: json['message'] ?? json['Message'],
      orderId: orderId ?? json['orderId'] ?? json['OrderId'],
      transNo: transNo ?? json['transNo'] ?? json['TransNo'],
      orderDate: orderDate ?? json['orderDate'] ?? json['OrderDate'],
      items: items,
      subTotal: subTotal ?? _parseDouble(json['subTotal'] ?? json['SubTotal']),
      taxAmount:
          taxAmount ?? _parseDouble(json['taxAmount'] ?? json['TaxAmount']),
      totalAmount:
          totalAmount ??
          _parseDouble(json['totalAmount'] ?? json['TotalAmount']),
      customerDetails: customerDetails,
      billDetails: billDetails,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'orderId': orderId,
      'orderDate': orderDate,
      'items': items?.map((item) => item.toJson()).toList(),
      'subTotal': subTotal,
      'taxAmount': taxAmount,
      'totalAmount': totalAmount,
      'customerDetails': customerDetails,
      'billDetails': billDetails,
    };
  }
}

/// Order detail item model
class OrderDetailItem {
  final String id;
  final String partName;
  final String brand;
  final String size;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  OrderDetailItem({
    required this.id,
    required this.partName,
    required this.brand,
    required this.size,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory OrderDetailItem.fromJson(Map<String, dynamic> json) {
    // Parse quantity and prices
    final qty = json['Qty'] ?? json['quantity'] ?? 1;
    final unitPrice = _parseDouble(
      json['BPrice'] ?? json['unitPrice'] ?? json['price'] ?? 0.0,
    );
    final totalPrice =
        unitPrice * (qty is int ? qty : int.tryParse(qty.toString()) ?? 1);

    return OrderDetailItem(
      id: json['LineId'] ?? json['id'] ?? json['itemId'] ?? '',
      partName: json['Item'] ?? json['partName'] ?? json['item'] ?? '',
      brand: json['brand'] ?? '',
      size: json['Units'] ?? json['size'] ?? '',
      quantity: qty is int ? qty : int.tryParse(qty.toString()) ?? 1,
      unitPrice: unitPrice,
      totalPrice: totalPrice,
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
      'partName': partName,
      'brand': brand,
      'size': size,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
    };
  }
}

/// Response model for order tracking
class OrderTrackingResponse {
  final bool success;
  final String? message;
  final String? orderNumber;
  final String? sono; // Sales order number for Track Order
  final String? transNo; // Transaction number from API
  final String? orderDate;
  final String? pickNumber;
  final String? pickDate;
  final String? packNumber;
  final String? packDate;
  final String? invoiceNumber;
  final String? invoiceDate;
  final String? shipNumber;
  final String? shipDate;
  final String? podNumber;
  final String? podDate;

  OrderTrackingResponse({
    required this.success,
    this.message,
    this.orderNumber,
    this.sono,
    this.transNo,
    this.orderDate,
    this.pickNumber,
    this.pickDate,
    this.packNumber,
    this.packDate,
    this.invoiceNumber,
    this.invoiceDate,
    this.shipNumber,
    this.shipDate,
    this.podNumber,
    this.podDate,
  });

  factory OrderTrackingResponse.fromJson(Map<String, dynamic> json) {
    final parameters = json['parameters'] as Map<String, dynamic>? ?? {};

    return OrderTrackingResponse(
      success: json['success'] ?? json['Success'] ?? false,
      message: json['message'] ?? json['Message'],
      orderNumber: parameters['sono'] ?? '',
      sono: parameters['sono'] ?? parameters['SONo'],
      transNo: parameters['transno'] ?? parameters['TransNo'],
      orderDate: parameters['sodate'] ?? '',
      pickNumber: parameters['pickno'] ?? '',
      pickDate: parameters['pickdate'] ?? '',
      packNumber: parameters['packno'] ?? '',
      packDate: parameters['packdate'] ?? '',
      invoiceNumber: parameters['invoiceno'] ?? '',
      invoiceDate: parameters['invoicedate'] ?? '',
      shipNumber: parameters['shipno'] ?? '',
      shipDate: parameters['shipdate'] ?? '',
      podNumber: parameters['podno'] ?? '',
      podDate: parameters['poddate'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'orderNumber': orderNumber,
      'orderDate': orderDate,
      'pickNumber': pickNumber,
      'pickDate': pickDate,
      'packNumber': packNumber,
      'packDate': packDate,
      'invoiceNumber': invoiceNumber,
      'invoiceDate': invoiceDate,
      'shipNumber': shipNumber,
      'shipDate': shipDate,
      'podNumber': podNumber,
      'podDate': podDate,
    };
  }
}

/// Custom exception for order details operations
class OrderDetailsException extends Failure {
  final String message;
  final int? statusCode;

  const OrderDetailsException(this.message, [this.statusCode]);

  @override
  List<Object?> get props => [message, statusCode];

  @override
  String toString() => 'OrderDetailsException: $message';
}
