import 'package:dio/dio.dart';
import 'api_service_base.dart';

/// Example API Service demonstrating how to use AppContextService for API calls
///
/// This service shows how to make API calls with the context parameters
/// from the login response (AcOwner, AppType, UserID, Password, SalesRep, CustomerID)
class ExampleApiService extends ApiServiceBase {
  ExampleApiService({required super.dio, required super.appContext});

  /// Example: Get customer orders
  ///
  /// API Endpoint: GET /api/Orders/GetCustomerOrders
  /// Parameters from context:
  /// - AcOwner
  /// - AppType
  /// - UserID
  /// - Password
  /// - SalesRep
  /// - CustomerID
  /// Additional parameters:
  /// - StartDate
  /// - EndDate
  Future<Map<String, dynamic>> getCustomerOrders({
    required String startDate,
    required String endDate,
  }) async {
    if (!isContextReady) {
      throw Exception(contextNotReadyMessage);
    }

    try {
      final response = await getWithContext(
        '/api/Orders/GetCustomerOrders',
        queryParameters: {'StartDate': startDate, 'EndDate': endDate},
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print('❌ Error getting customer orders: ${e.message}');
      rethrow;
    }
  }

  /// Example: Place an order
  ///
  /// API Endpoint: POST /api/Orders/PlaceOrder
  /// Parameters from context automatically included
  Future<Map<String, dynamic>> placeOrder({
    required Map<String, dynamic> orderData,
  }) async {
    if (!isContextReady) {
      throw Exception(contextNotReadyMessage);
    }

    try {
      final response = await postWithContext(
        '/api/Orders/PlaceOrder',
        data: orderData,
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print('❌ Error placing order: ${e.message}');
      rethrow;
    }
  }

  /// Example: Get inventory
  ///
  /// API Endpoint: GET /api/Inventory/GetItems
  /// Shows how to add additional custom parameters
  Future<Map<String, dynamic>> getInventory({
    String? partNumber,
    String? category,
  }) async {
    if (!isContextReady) {
      throw Exception(contextNotReadyMessage);
    }

    final customParams = <String, dynamic>{};
    if (partNumber != null) customParams['PartNumber'] = partNumber;
    if (category != null) customParams['Category'] = category;

    try {
      final response = await getWithContext(
        '/api/Inventory/GetItems',
        queryParameters: customParams,
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print('❌ Error getting inventory: ${e.message}');
      rethrow;
    }
  }

  /// Example: Direct usage of app context for custom API calls
  ///
  /// This shows how to manually build requests using app context
  Future<Response> customApiCall(String endpoint) async {
    if (!appContext.isInitialized) {
      throw Exception('App context not initialized');
    }

    // Build URL manually
    final baseUrl = appContext.apiBaseUrl;
    final fullUrl = '$baseUrl$endpoint';

    // Get all API parameters
    final params = appContext.apiParameters;

    print('🔧 Custom API Call');
    print('   URL: $fullUrl');
    print('   Protocol: ${appContext.protocol}');
    print('   Host: ${appContext.host}');
    print('   AcOwner: ${appContext.acOwner}');
    print('   AppType: ${appContext.appType}');
    print('   UserID: ${appContext.userId}');
    print('   SalesRep: ${appContext.salesRep}');
    print('   CustomerID: ${appContext.customerId}');
    print('   TokenId: ${appContext.tokenId}');

    return await dio.get(
      fullUrl,
      queryParameters: params,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
  }
}
