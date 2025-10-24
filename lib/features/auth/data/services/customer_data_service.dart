import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/services/app_context_service.dart';

/// Service for handling Customer Data API integration
/// URL: {{protocol}}://{{host}}:{{port}}/api/Mobileapp/CustomerData?SalesRep={{SalesRep}}&AcOwner={{AcOwner}}&TokenId={{tokenID}}
class CustomerDataService {
  final Dio _dio;
  final AppContextService _appContext = GetIt.instance<AppContextService>();

  CustomerDataService({Dio? dio}) : _dio = dio ?? Dio();

  /// Base URL from AppContextService
  String get _baseUrl => _appContext.apiBaseUrl;

  /// Fetch customer data using parameters from AppContextService
  ///
  /// Returns a [Map<String, dynamic>] containing the API response
  Future<Map<String, dynamic>> getCustomerData() async {
    try {
      print('👤 CustomerDataService: Fetching customer data');
      print('   - SalesRep: ${_appContext.salesRep}');
      print('   - AcOwner: ${_appContext.acOwner}');
      print('   - TokenId: ${_appContext.tokenId}');

      // Build the query parameters from AppContextService
      final queryParams = {
        'SalesRep': _appContext.salesRep,
        'AcOwner': _appContext.acOwner,
        'TokenId': _appContext.tokenId,
      };

      final fullUrl =
          '$_baseUrl/api/Mobileapp/CustomerData?${Uri(queryParameters: queryParams).query}';
      print('🌐 CustomerDataService: Full GET URL: $fullUrl');

      final response = await _dio.get(
        '$_baseUrl/api/Mobileapp/CustomerData',
        queryParameters: queryParams,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      print('📡 CustomerDataService: Response status: ${response.statusCode}');
      print('📡 CustomerDataService: Response data: ${response.data}');

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception(
          'Failed to fetch customer data: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      print('❌ CustomerDataService: DioException occurred');
      print('   - Error type: ${e.type}');
      print('   - Error message: ${e.message}');
      print('   - Response: ${e.response?.data}');

      if (e.response?.data != null) {
        throw Exception('API Error: ${e.response?.data}');
      } else {
        throw Exception('Network Error: ${e.message}');
      }
    } catch (e) {
      print('❌ CustomerDataService: Unexpected error: $e');
      rethrow;
    }
  }
}

/// Model for Customer Data Response
class CustomerDataResponse {
  final bool success;
  final String? message;
  final Map<String, dynamic>? data;
  final List<dynamic>? customers;

  CustomerDataResponse({
    required this.success,
    this.message,
    this.data,
    this.customers,
  });

  factory CustomerDataResponse.fromJson(Map<String, dynamic> json) {
    return CustomerDataResponse(
      success: json['success'] ?? json['Success'] ?? false,
      message: json['message'] ?? json['Message'],
      data: json['data'] ?? json['Data'],
      customers: json['customers'] ?? json['Customers'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data,
      'customers': customers,
    };
  }
}
