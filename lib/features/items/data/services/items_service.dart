import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/services/app_context_service.dart';
import '../models/item_model.dart';

/// Service for handling Items API integration
/// URL: {{protocol}}://{{serverIp}}:{{port}}/api/Mobileapp/Itemddlinfo?AcOwner={{AcOwner}}&TokenId={{TokenId}}&AppType={{AppType}}
/// All parameters and configuration are automatically retrieved from AppContextService
/// Environment: UAT (HTTP:3032) | Production (HTTPS:3030)
class ItemsService {
  final Dio _dio;
  final AppContextService _appContext = GetIt.instance<AppContextService>();

  ItemsService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 60),
              sendTimeout: const Duration(seconds: 30),
            ),
          );

  /// Base URL from AppContextService environment configuration
  String get _baseUrl => _appContext.apiBaseUrl;

  /// Get all items from the API
  ///
  /// Uses parameters from AppContextService
  ///
  /// Returns a [List<ItemModel>] containing all items
  Future<List<ItemModel>> getAllItems() async {
    try {
      // Check network connectivity first
      final connectivityResults = await Connectivity().checkConnectivity();
      if (connectivityResults.contains(ConnectivityResult.none)) {
        throw ItemsException(
          'No internet connection. Please check your network.',
        );
      }

      print('📦 ItemsService: Fetching all items...');
      print(
        '📦 ItemsService: AcOwner: ${_appContext.acOwner}, TokenId: ${_appContext.tokenId}, AppType: ${_appContext.appType}',
      );

      // Build the full URL with parameters from AppContextService
      final queryParams = {
        'AcOwner': _appContext.acOwner,
        'TokenId': _appContext.tokenId,
        'AppType': _appContext.appType,
      };
      final fullUrl =
          '$_baseUrl/api/Mobileapp/Itemddlinfo?${Uri(queryParameters: queryParams).query}';

      print('🌐 ItemsService: Full GET URL: $fullUrl');
      print('📋 ItemsService: Query Parameters: $queryParams');
      print('📋 ItemsService: Base URL: $_baseUrl');
      print('📋 ItemsService: Endpoint: /api/Mobileapp/Itemddlinfo');
      print(
        '📋 ItemsService: Request Headers: {Content-Type: application/json, Accept: application/json}',
      );

      final response = await _dio.get(
        '$_baseUrl/api/Mobileapp/Itemddlinfo',
        queryParameters: queryParams,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      print('📡 ItemsService: Response status: ${response.statusCode}');
      print('📡 ItemsService: Response headers: ${response.headers}');
      print(
        '📡 ItemsService: Response data type: ${response.data.runtimeType}',
      );
      print(
        '📡 ItemsService: Response data length: ${response.data is List ? (response.data as List).length : 'Not a list'}',
      );
      print('📡 ItemsService: Request URL: ${response.requestOptions.uri}');
      print(
        '📡 ItemsService: Request method: ${response.requestOptions.method}',
      );

      // Log first few items for debugging
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data.containsKey('parameters') && data['parameters'] is List) {
          final items = data['parameters'] as List;
          print(
            '📡 ItemsService: First item sample: ${items.isNotEmpty ? items.first : 'No items'}',
          );
        }
      }

      if (response.statusCode == 200) {
        final data = response.data;

        // Handle different response formats
        List<dynamic> itemsList;
        if (data is List) {
          itemsList = data;
        } else if (data is Map<String, dynamic>) {
          // Check if data is wrapped in a response object
          if (data.containsKey('parameters') && data['parameters'] is List) {
            itemsList = data['parameters'] as List<dynamic>;
          } else if (data.containsKey('data') && data['data'] is List) {
            itemsList = data['data'] as List<dynamic>;
          } else if (data.containsKey('items') && data['items'] is List) {
            itemsList = data['items'] as List<dynamic>;
          } else if (data.containsKey('results') && data['results'] is List) {
            itemsList = data['results'] as List<dynamic>;
          } else {
            // If it's a single item, wrap it in a list
            itemsList = [data];
          }
        } else {
          throw ItemsException(
            'Unexpected response format: ${data.runtimeType}',
          );
        }

        print('📦 ItemsService: Parsing ${itemsList.length} items...');

        final items = itemsList
            .map((itemJson) {
              try {
                return ItemModel.fromJson(itemJson as Map<String, dynamic>);
              } catch (e) {
                print('⚠️ ItemsService: Error parsing item: $e');
                print('⚠️ ItemsService: Item data: $itemJson');
                return null;
              }
            })
            .where((item) => item != null)
            .cast<ItemModel>()
            .toList();

        print('✅ ItemsService: Successfully parsed ${items.length} items');
        return items;
      } else {
        throw ItemsException(
          'Failed to fetch items with status code: ${response.statusCode}',
          response.statusCode,
        );
      }
    } on DioException catch (e) {
      print('❌ ItemsService: DioException: ${e.message}');
      print('❌ ItemsService: Response: ${e.response?.data}');
      throw _handleDioException(e);
    } catch (e) {
      print('❌ ItemsService: Unexpected error: ${e.toString()}');
      throw ItemsException('Unexpected error: ${e.toString()}');
    }
  }

  /// Test API connection using AppContextService parameters
  Future<void> testApiConnection() async {
    try {
      print('🧪 ItemsService: Testing API connection...');
      final response = await _dio.get(
        '$_baseUrl/api/Mobileapp/Itemddlinfo',
        queryParameters: {
          'AcOwner': _appContext.acOwner,
          'TokenId': _appContext.tokenId,
          'AppType': _appContext.appType,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );
      print('🧪 ItemsService: Test response status: ${response.statusCode}');
      print(
        '🧪 ItemsService: Test response data type: ${response.data.runtimeType}',
      );
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        print('🧪 ItemsService: Test success: ${data['success']}');
        print('🧪 ItemsService: Test message: ${data['message']}');
        if (data.containsKey('parameters') && data['parameters'] is List) {
          print(
            '🧪 ItemsService: Test items count: ${(data['parameters'] as List).length}',
          );
        }
      }
    } catch (e) {
      print('🧪 ItemsService: Test failed: $e');
    }
  }

  /// Handle Dio exceptions and convert them to ItemsException
  ItemsException _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ItemsException(
          'Connection timeout. Please check your internet connection.',
        );
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message =
            e.response?.data?['message'] ??
            e.response?.data?['error'] ??
            'Server error occurred';

        if (statusCode == 401) {
          return ItemsException(
            'Authentication failed. Please login again.',
            statusCode,
          );
        } else if (statusCode == 403) {
          return ItemsException(
            'Access denied. You do not have permission.',
            statusCode,
          );
        } else if (statusCode == 404) {
          return ItemsException('Items endpoint not found.', statusCode);
        } else if (statusCode == 500) {
          return ItemsException(
            'Internal server error. Please try again later.',
            statusCode,
          );
        }
        return ItemsException(message, statusCode);
      case DioExceptionType.cancel:
        return ItemsException('Request was cancelled.');
      case DioExceptionType.connectionError:
        return ItemsException(
          'No internet connection. Please check your network.',
        );
      default:
        return ItemsException(
          'An unexpected error occurred. Please try again.',
        );
    }
  }
}

/// Custom exception for Items API errors
class ItemsException implements Exception {
  final String message;
  final int? statusCode;

  ItemsException(this.message, [this.statusCode]);

  @override
  String toString() => 'ItemsException: $message';
}
