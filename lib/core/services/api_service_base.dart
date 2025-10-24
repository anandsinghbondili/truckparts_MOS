import 'package:dio/dio.dart';
import 'app_context_service.dart';

/// Base class for API services that use AppContext
///
/// This class provides helper methods to build API requests with
/// the required parameters from the login response stored in AppContext.
///
/// Example usage:
/// ```dart
/// class MyApiService extends ApiServiceBase {
///   MyApiService({
///     required super.dio,
///     required super.appContext,
///   });
///
///   Future<Response> getCustomerOrders() async {
///     final url = buildApiUrl('/api/Orders/GetCustomerOrders');
///     final params = {
///       ...appContext.apiParameters,
///       'StartDate': '2024-01-01',
///     };
///     return await dio.get(url, queryParameters: params);
///   }
/// }
/// ```
abstract class ApiServiceBase {
  final Dio dio;
  final AppContextService appContext;

  ApiServiceBase({required this.dio, required this.appContext});

  /// Build full API URL using the base URL from app context
  String buildApiUrl(String endpoint) {
    final baseUrl = appContext.apiBaseUrl;
    // Remove leading slash from endpoint if present
    final cleanEndpoint = endpoint.startsWith('/')
        ? endpoint.substring(1)
        : endpoint;
    return '$baseUrl/$cleanEndpoint';
  }

  /// Get standard API parameters from app context
  Map<String, String> get standardApiParams => appContext.apiParameters;

  /// Build query parameters by merging standard params with custom params
  Map<String, dynamic> buildQueryParams([Map<String, dynamic>? customParams]) {
    final params = <String, dynamic>{...standardApiParams};
    if (customParams != null) {
      params.addAll(customParams);
    }
    return params;
  }

  /// Make a GET request with standard API parameters
  Future<Response> getWithContext(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final url = buildApiUrl(endpoint);
    final params = buildQueryParams(queryParameters);

    print('🌐 API GET: $url');
    print('📋 Parameters: $params');

    return await dio.get(url, queryParameters: params, options: options);
  }

  /// Make a POST request with standard API parameters
  Future<Response> postWithContext(
    String endpoint, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final url = buildApiUrl(endpoint);
    final params = buildQueryParams(queryParameters);

    print('🌐 API POST: $url');
    print('📋 Query Parameters: $params');
    print('📦 Body: $data');

    return await dio.post(
      url,
      data: data,
      queryParameters: params,
      options: options,
    );
  }

  /// Make a PUT request with standard API parameters
  Future<Response> putWithContext(
    String endpoint, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final url = buildApiUrl(endpoint);
    final params = buildQueryParams(queryParameters);

    print('🌐 API PUT: $url');
    print('📋 Query Parameters: $params');
    print('📦 Body: $data');

    return await dio.put(
      url,
      data: data,
      queryParameters: params,
      options: options,
    );
  }

  /// Make a DELETE request with standard API parameters
  Future<Response> deleteWithContext(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final url = buildApiUrl(endpoint);
    final params = buildQueryParams(queryParameters);

    print('🌐 API DELETE: $url');
    print('📋 Parameters: $params');

    return await dio.delete(url, queryParameters: params, options: options);
  }

  /// Check if app context is initialized before making API calls
  bool get isContextReady => appContext.isInitialized;

  /// Get error message if context is not ready
  String get contextNotReadyMessage =>
      'App context not initialized. Please login first.';
}
