import 'package:dio/dio.dart';
import '../../../../core/services/api_service_base.dart';

/// Order Placement Service for handling order placement flow
///
/// APIs:
/// 1. PurchaseOTP - Send OTP to initiate order
/// 2. verifyPlaceOrder - Verify OTP for order placement
/// 3. SaveSalesOrder - Place order after OTP verification
class OrderPlacementService extends ApiServiceBase {
  OrderPlacementService({required super.dio, required super.appContext});

  /// Step 1: Send OTP to initiate order
  ///
  /// API: GET /api/Mobileapp/PurchaseOTP?AcOwner={{AcOwner}}&MobileNo={{UserID}}&CustomerId={{CustomerID}}&SalesRep={{SalesRep}}
  /// Note: Added SalesRep parameter to ensure OTP goes to logged-in user
  ///
  /// Returns OTP response
  Future<Map<String, dynamic>> sendPurchaseOTP() async {
    if (!isContextReady) {
      throw OrderPlacementException(contextNotReadyMessage);
    }

    try {
      print('📱 OrderPlacementService: Sending Purchase OTP');

      final response = await getWithContext(
        '/api/Mobileapp/PurchaseOTP',
        queryParameters: {
          'MobileNo': appContext.userId,
          'CustomerId': appContext.customerId,
          'SalesRep': appContext.salesRep,
        },
      );

      print('✅ Purchase OTP Response: ${response.data}');

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print('❌ OrderPlacementService: DioException: ${e.message}');
      print('❌ Response: ${e.response?.data}');
      throw _handleDioException(e);
    } catch (e) {
      print('❌ OrderPlacementService: Unexpected error: ${e.toString()}');
      throw OrderPlacementException('Unexpected error: ${e.toString()}');
    }
  }

  /// Step 2: Verify OTP for order placement
  ///
  /// API: GET /api/Mobileapp/verifyPlaceOrder?AcOwner={{AcOwner}}&MobileNo={{UserID}}&Otp={{user_entered_otp}}&SalesRep={{SalesRep}}
  /// Note: Added SalesRep parameter to ensure OTP verification uses logged-in user
  ///
  /// Returns OTP verification response
  Future<Map<String, dynamic>> verifyPlaceOrderOTP(String otp) async {
    if (!isContextReady) {
      throw OrderPlacementException(contextNotReadyMessage);
    }

    if (otp.length != 4) {
      throw OrderPlacementException('OTP must be exactly 4 digits');
    }

    try {
      print('🔐 OrderPlacementService: Verifying OTP: $otp');

      final response = await getWithContext(
        '/api/Mobileapp/verifyPlaceOrder',
        queryParameters: {
          'MobileNo': appContext.userId,
          'Otp': otp,
          'SalesRep': appContext.salesRep,
        },
      );

      print('✅ OTP Verification Response: ${response.data}');

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print('❌ OrderPlacementService: DioException: ${e.message}');
      print('❌ Response: ${e.response?.data}');
      throw _handleDioException(e);
    } catch (e) {
      print('❌ OrderPlacementService: Unexpected error: ${e.toString()}');
      throw OrderPlacementException('Unexpected error: ${e.toString()}');
    }
  }

  /// Step 3: Place Order after OTP verification
  ///
  /// API: POST /api/Mobileapp/SaveSalesOrder
  /// Body: {
  ///   "Customerid": "{{CustomerID}}",
  ///   "Tokenid": "{{tokenID}}",
  ///   "AcOwner": "{{AcOwner}}",
  ///   "Salesrep": "{{SalesRep}}",
  ///   "apptype": "{{AppType}}"
  /// }
  ///
  /// Returns order placement response
  Future<Map<String, dynamic>> placeOrder() async {
    if (!isContextReady) {
      throw OrderPlacementException(contextNotReadyMessage);
    }

    try {
      print('🛒 OrderPlacementService: Placing order');

      final requestBody = {
        'Customerid': appContext.customerId,
        'Tokenid': appContext.tokenId,
        'AcOwner': appContext.acOwner,
        'Salesrep': appContext.salesRep,
        'apptype': appContext.appType,
      };

      print('📤 Order Request Body: $requestBody');

      final response = await postWithContext(
        '/api/Mobileapp/SaveSalesOrder',
        data: requestBody,
      );

      print('✅ Order Placement Response: ${response.data}');

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print('❌ OrderPlacementService: DioException: ${e.message}');
      print('❌ Response: ${e.response?.data}');
      throw _handleDioException(e);
    } catch (e) {
      print('❌ OrderPlacementService: Unexpected error: ${e.toString()}');
      throw OrderPlacementException('Unexpected error: ${e.toString()}');
    }
  }

  /// Handle Dio exceptions
  OrderPlacementException _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return OrderPlacementException(
          'Connection timeout. Please check your internet connection.',
          e.response?.statusCode,
        );
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['message'] ?? 'Request failed';
        return OrderPlacementException(message, statusCode);
      case DioExceptionType.cancel:
        return OrderPlacementException('Request cancelled');
      default:
        return OrderPlacementException(
          'Network error: ${e.message}',
          e.response?.statusCode,
        );
    }
  }
}

/// Custom exception for order placement operations
class OrderPlacementException implements Exception {
  final String message;
  final int? statusCode;

  OrderPlacementException(this.message, [this.statusCode]);

  @override
  String toString() => 'OrderPlacementException: $message';
}

/// Response model for OTP operations
class OtpResponse {
  final bool success;
  final String? message;
  final String? otp;
  final Map<String, dynamic>? data;

  OtpResponse({required this.success, this.message, this.otp, this.data});

  factory OtpResponse.fromJson(Map<String, dynamic> json) {
    return OtpResponse(
      success: json['success'] ?? json['Success'] ?? false,
      message: json['message'] ?? json['Message'],
      otp: json['otp'] ?? json['Otp'] ?? json['OTP'],
      data: json['data'] ?? json['Data'] ?? json['parameters'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'success': success, 'message': message, 'otp': otp, 'data': data};
  }
}

/// Response model for order placement
class OrderPlacementResponse {
  final bool success;
  final String? message;
  final String? orderId;
  final dynamic data; // Changed to dynamic to handle both string and map

  OrderPlacementResponse({
    required this.success,
    this.message,
    this.orderId,
    this.data,
  });

  factory OrderPlacementResponse.fromJson(Map<String, dynamic> json) {
    // Handle data field that can be either string or map
    dynamic dataField = json['data'] ?? json['Data'] ?? json['parameters'];

    return OrderPlacementResponse(
      success: json['success'] ?? json['Success'] ?? false,
      message: json['message'] ?? json['Message'],
      orderId: json['orderId'] ?? json['OrderId'] ?? json['orderid'],
      data: dataField,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'orderId': orderId,
      'data': data,
    };
  }

  /// Get order number from data field (handles both string and map formats)
  String? get orderNumber {
    if (data is String) {
      return data as String;
    } else if (data is Map<String, dynamic>) {
      final dataMap = data as Map<String, dynamic>;
      return dataMap['orderNumber'] ??
          dataMap['order_number'] ??
          dataMap['OrderNumber'];
    }
    return null;
  }
}
