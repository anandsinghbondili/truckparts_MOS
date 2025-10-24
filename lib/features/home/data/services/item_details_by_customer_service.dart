import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/services/app_context_service.dart';
import '../models/part_model.dart';

/// Service for handling ItemDetailsbyCustomer API integration
/// URL: {{protocol}}://{{host}}:{{port}}/api/Mobileapp/ItemDetailsbyCustomer?CustomerID={{CustomerID}}&AcOwner={{AcOwner}}&TokenId={{tokenId}}&Type={{AppType}}
class ItemDetailsByCustomerService {
  final Dio _dio;
  final AppContextService _appContext = GetIt.instance<AppContextService>();

  ItemDetailsByCustomerService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 60),
              sendTimeout: const Duration(seconds: 30),
            ),
          );

  /// Base URL from AppContextService
  String get _baseUrl => _appContext.apiBaseUrl;

  /// Get all items for a specific customer
  ///
  /// Uses parameters from AppContextService
  ///
  /// Returns a [List<PartModel>] containing all items for the customer
  Future<List<PartModel>> getItemsByCustomer() async {
    try {
      // Check network connectivity first
      final connectivityResults = await Connectivity().checkConnectivity();
      if (connectivityResults.contains(ConnectivityResult.none)) {
        throw ItemDetailsByCustomerException(
          'No internet connection. Please check your network.',
        );
      }

      print('');
      print(
        '╔════════════════════════════════════════════════════════════════╗',
      );
      print(
        '║      🌐 API CALL: ItemDetailsbyCustomer                       ║',
      );
      print(
        '╚════════════════════════════════════════════════════════════════╝',
      );
      print('');
      print('📡 REQUEST DETAILS:');
      print('   Base URL: $_baseUrl');
      print('   Endpoint: /api/Mobileapp/ItemDetailsbyCustomer');
      print('   Method: GET');
      print('');
      print('📋 PARAMETERS FROM AppContextService:');
      print('   1. CustomerID = "${_appContext.customerId}"');
      print('   2. AcOwner = "${_appContext.acOwner}"');
      print('   3. TokenId = "${_appContext.tokenId}"');
      print('   4. Type = "${_appContext.appType}"');
      print('');

      // Validate parameters
      if (_appContext.customerId.isEmpty) {
        throw ItemDetailsByCustomerException(
          'CustomerID is required but is empty',
        );
      }
      if (_appContext.acOwner.isEmpty) {
        throw ItemDetailsByCustomerException(
          'AcOwner is required but is empty',
        );
      }
      if (_appContext.tokenId.isEmpty) {
        throw ItemDetailsByCustomerException(
          'TokenId is required but is empty',
        );
      }
      if (_appContext.appType.isEmpty) {
        throw ItemDetailsByCustomerException(
          'AppType is required but is empty',
        );
      }

      // Build the query parameters from AppContextService
      final queryParams = {
        'CustomerID': _appContext.customerId,
        'AcOwner': _appContext.acOwner,
        'TokenId': _appContext.tokenId,
        'Type': _appContext.appType,
      };

      final fullUrl =
          '$_baseUrl/api/Mobileapp/ItemDetailsbyCustomer?${Uri(queryParameters: queryParams).query}';
      print('🔗 FULL REQUEST URL:');
      print('   $fullUrl');
      print('');
      print('⏳ Making HTTP GET request...');
      print('');

      final response = await _dio.get(
        '$_baseUrl/api/Mobileapp/ItemDetailsbyCustomer',
        queryParameters: queryParams,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      print(
        '╔════════════════════════════════════════════════════════════════╗',
      );
      print(
        '║      ✅ API RESPONSE RECEIVED                                  ║',
      );
      print(
        '╚════════════════════════════════════════════════════════════════╝',
      );
      print('');
      print('📥 RESPONSE STATUS: ${response.statusCode}');
      print('📦 RESPONSE TYPE: ${response.data.runtimeType}');
      print('');
      print('📄 RESPONSE BODY:');
      final dataStr = response.data.toString();
      if (dataStr.length > 500) {
        print('${dataStr.substring(0, 500)}...');
        print('[Response truncated - total length: ${dataStr.length} chars]');
      } else {
        print(dataStr);
      }
      print('');

      if (response.statusCode == 200) {
        final data = response.data;

        // Handle response format
        if (data is! Map<String, dynamic>) {
          print(
            '❌ ItemDetailsByCustomerService: Unexpected response format: ${data.runtimeType}',
          );
          print('❌ ItemDetailsByCustomerService: Raw data: $data');
          throw ItemDetailsByCustomerException(
            'Unexpected response format: ${data.runtimeType}',
          );
        }

        final responseMap = data;

        final success = responseMap['success'] ?? false;
        final message = responseMap['message'] ?? '';

        print('');
        print('📊 API Response Analysis:');
        print('   Success: $success');
        print('   Message: $message');
        print('   Response Keys: ${responseMap.keys.join(", ")}');

        if (!success) {
          // Check if it's "No Data Found" - this is not necessarily an error
          if (message.toLowerCase().contains('no data found')) {
            print('⚠️ No items found for this customer');
            print('   This might be normal if the customer has no items yet.');
            print('   Returning empty list...');
            print('');
            return []; // Return empty list instead of throwing error
          }

          throw ItemDetailsByCustomerException(
            'API returned failure: $message',
          );
        }

        // Extract items from parameters
        final parameters = responseMap['parameters'];
        if (parameters == null) {
          print(
            '⚠️ ItemDetailsByCustomerService: No parameters found in response',
          );
          print(
            '⚠️ ItemDetailsByCustomerService: Available keys: ${responseMap.keys.join(", ")}',
          );
          return [];
        }

        if (parameters is! List) {
          print(
            '⚠️ ItemDetailsByCustomerService: Parameters is not a list, type: ${parameters.runtimeType}',
          );
          print(
            '⚠️ ItemDetailsByCustomerService: Parameters data: $parameters',
          );
          return [];
        }

        final itemsList = parameters;

        print('');
        print('📦 Parsing Items from Response...');
        print('   Total items in response: ${itemsList.length}');

        if (itemsList.isEmpty) {
          print('   ⚠️ WARNING: Parameters list is empty - No items found!');
          return [];
        }

        final firstItem = itemsList.first as Map<String, dynamic>;
        print('   First item preview:');
        print('     - ID: ${firstItem['itemid']}');
        print('     - Name: ${firstItem['itemname']}');
        print('     - Brand: ${firstItem['Brand']}');
        print('     - Price: ${firstItem['list_price']}');

        final items = itemsList
            .map((itemJson) {
              try {
                return PartModel.fromApiJson(itemJson as Map<String, dynamic>);
              } catch (e) {
                print(
                  '⚠️ ItemDetailsByCustomerService: Error parsing item: $e',
                );
                print('⚠️ ItemDetailsByCustomerService: Item data: $itemJson');
                return null;
              }
            })
            .where((item) => item != null)
            .cast<PartModel>()
            .toList();

        print('');
        print('✅ Items Parsed Successfully!');
        print('   Items parsed: ${items.length} / ${itemsList.length}');
        if (items.length < itemsList.length) {
          print(
            '   ⚠️ Warning: ${itemsList.length - items.length} items failed to parse',
          );
        }
        print('');

        return items;
      } else {
        throw ItemDetailsByCustomerException(
          'Failed to fetch items with status code: ${response.statusCode}',
          response.statusCode,
        );
      }
    } on DioException catch (e) {
      print('❌ ItemDetailsByCustomerService: DioException: ${e.message}');
      print('❌ ItemDetailsByCustomerService: Response: ${e.response?.data}');
      throw _handleDioException(e);
    } catch (e) {
      print(
        '❌ ItemDetailsByCustomerService: Unexpected error: ${e.toString()}',
      );
      if (e is ItemDetailsByCustomerException) rethrow;
      throw ItemDetailsByCustomerException('Unexpected error: ${e.toString()}');
    }
  }

  /// Handle Dio exceptions and convert them to ItemDetailsByCustomerException
  ItemDetailsByCustomerException _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ItemDetailsByCustomerException(
          'Connection timeout. Please check your internet connection.',
        );
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message =
            e.response?.data?['message'] ??
            e.response?.data?['error'] ??
            'Server error occurred';

        if (statusCode == 401) {
          return ItemDetailsByCustomerException(
            'Authentication failed. Please login again.',
            statusCode,
          );
        } else if (statusCode == 403) {
          return ItemDetailsByCustomerException(
            'Access denied. You do not have permission.',
            statusCode,
          );
        } else if (statusCode == 404) {
          return ItemDetailsByCustomerException(
            'Items endpoint not found.',
            statusCode,
          );
        } else if (statusCode == 500) {
          return ItemDetailsByCustomerException(
            'Internal server error. Please try again later.',
            statusCode,
          );
        }
        return ItemDetailsByCustomerException(message, statusCode);
      case DioExceptionType.cancel:
        return ItemDetailsByCustomerException('Request was cancelled.');
      case DioExceptionType.connectionError:
        return ItemDetailsByCustomerException(
          'No internet connection. Please check your network.',
        );
      default:
        return ItemDetailsByCustomerException(
          'An unexpected error occurred. Please try again.',
        );
    }
  }
}

/// Custom exception for ItemDetailsByCustomer API errors
class ItemDetailsByCustomerException implements Exception {
  final String message;
  final int? statusCode;

  ItemDetailsByCustomerException(this.message, [this.statusCode]);

  @override
  String toString() => 'ItemDetailsByCustomerException: $message';
}
