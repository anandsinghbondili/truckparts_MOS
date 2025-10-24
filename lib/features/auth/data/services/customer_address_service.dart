import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/services/app_context_service.dart';

/// Service for handling Customer Address API integration
/// URL: {{protocol}}://{{host}}:{{port}}/api/Mobileapp/GetAddress?CustomerId={{CustomerID}}
class CustomerAddressService {
  final Dio _dio;
  final AppContextService _appContext = GetIt.instance<AppContextService>();

  CustomerAddressService({Dio? dio}) : _dio = dio ?? Dio();

  /// Base URL from AppContextService
  String get _baseUrl => _appContext.apiBaseUrl;

  /// Fetch customer address using CustomerId from AppContextService
  ///
  /// Returns a [Map<String, dynamic>] containing the API response
  Future<Map<String, dynamic>> getCustomerAddress() async {
    try {
      print('📍 CustomerAddressService: Fetching customer address');
      print('   - CustomerId: ${_appContext.customerId}');

      // Build the query parameters from AppContextService
      final queryParams = {'CustomerId': _appContext.customerId};

      final fullUrl =
          '$_baseUrl/api/Mobileapp/GetAddress?${Uri(queryParameters: queryParams).query}';
      print('🌐 CustomerAddressService: Full GET URL: $fullUrl');

      final response = await _dio.get(
        '$_baseUrl/api/Mobileapp/GetAddress',
        queryParameters: queryParams,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      print(
        '📡 CustomerAddressService: Response status: ${response.statusCode}',
      );
      print('📡 CustomerAddressService: Response data: ${response.data}');

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception(
          'Failed to fetch customer address: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      print('❌ CustomerAddressService: DioException occurred');
      print('   - Error type: ${e.type}');
      print('   - Error message: ${e.message}');
      print('   - Response: ${e.response?.data}');

      if (e.response?.data != null) {
        throw Exception('API Error: ${e.response?.data}');
      } else {
        throw Exception('Network Error: ${e.message}');
      }
    } catch (e) {
      print('❌ CustomerAddressService: Unexpected error: $e');
      rethrow;
    }
  }
}

/// Model for Customer Address Response
class CustomerAddressResponse {
  final bool success;
  final String? message;
  final List<dynamic>? addresses;
  final Map<String, dynamic>? data;

  CustomerAddressResponse({
    required this.success,
    this.message,
    this.addresses,
    this.data,
  });

  factory CustomerAddressResponse.fromJson(Map<String, dynamic> json) {
    return CustomerAddressResponse(
      success: json['success'] ?? json['Success'] ?? false,
      message: json['message'] ?? json['Message'],
      addresses: json['addresses'] ?? json['Addresses'],
      data: json['data'] ?? json['Data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'addresses': addresses,
      'data': data,
    };
  }
}

/// Model for a single customer address
class CustomerAddress {
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? state;
  final String? pincode;
  final String? country;
  final bool? isDefault;

  CustomerAddress({
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.state,
    this.pincode,
    this.country,
    this.isDefault,
  });

  factory CustomerAddress.fromJson(Map<String, dynamic> json) {
    return CustomerAddress(
      addressLine1: json['addressLine1'] ?? json['AddressLine1'],
      addressLine2: json['addressLine2'] ?? json['AddressLine2'],
      city: json['city'] ?? json['City'],
      state: json['state'] ?? json['State'],
      pincode: json['pincode'] ?? json['Pincode'] ?? json['PinCode'],
      country: json['country'] ?? json['Country'],
      isDefault: json['isDefault'] ?? json['IsDefault'] ?? false,
    );
  }

  /// Format address as a single string
  String get formattedAddress {
    final parts = <String>[];
    if (addressLine1 != null && addressLine1!.isNotEmpty) {
      parts.add(addressLine1!);
    }
    if (addressLine2 != null && addressLine2!.isNotEmpty) {
      parts.add(addressLine2!);
    }
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (state != null && state!.isNotEmpty) parts.add(state!);
    if (pincode != null && pincode!.isNotEmpty) parts.add(pincode!);

    return parts.join(', ');
  }
}
