import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../config/environment.dart';

/// App Context Service for managing global application state and API configuration
///
/// This service stores the login response parameters and provides them for API calls.
/// It manages the following configuration:
/// - protocol: from Environment config (http/https)
/// - host/port: from Environment config (3030 for Production, 3032 for UAT)
/// - AcOwner: from login response
/// - AppType: from login response
/// - UserID: from login response (mobile)
/// - Password: from login response
/// - SalesRep: from login response (empid)
/// - CustomerID: fetched from CustomerData API (no longer hardcoded)
class AppContextService {
  final SharedPreferences _prefs;

  /// Current environment configuration
  final EnvironmentConfig environment = EnvironmentConfig.current;

  // Storage keys
  static const String _keyProtocol = 'app_context_protocol';
  static const String _keyHost = 'app_context_host';
  static const String _keyAcOwner = 'app_context_ac_owner';
  static const String _keyAppType = 'app_context_app_type';
  static const String _keyUserId = 'app_context_user_id';
  static const String _keyPassword = 'app_context_password';
  static const String _keySalesRep = 'app_context_sales_rep';
  static const String _keyCustomerId = 'app_context_customer_id';
  static const String _keyEmpName = 'app_context_emp_name';
  static const String _keyRolesId = 'app_context_roles_id';
  static const String _keyRolesName = 'app_context_roles_name';
  static const String _keyTokenId = 'app_context_token_id';
  static const String _keyLoginParameters = 'app_context_login_parameters';
  static const String _keyRememberMe = 'app_context_remember_me';
  static const String _keySavedPhone = 'app_context_saved_phone';
  static const String _keySavedPassword = 'app_context_saved_password';
  static const String _keyCustomerData = 'app_context_customer_data';
  static const String _keyCustomerAddress = 'app_context_customer_address';

  AppContextService(this._prefs);

  /// Initialize context from login response
  Future<void> initializeFromLoginResponse(
    Map<String, dynamic> loginResponse,
  ) async {
    if (loginResponse['success'] == true &&
        loginResponse['parameters'] != null) {
      final parameters = loginResponse['parameters'] as Map<String, dynamic>;

      // Store login parameters
      await _prefs.setString(_keyLoginParameters, jsonEncode(parameters));

      // Extract and store individual parameters from environment
      await _prefs.setString(_keyProtocol, environment.protocol);
      await _prefs.setString(_keyHost, environment.port);
      await _prefs.setString(
        _keyAcOwner,
        parameters['AcOwner']?.toString() ?? '',
      );
      await _prefs.setString(
        _keyAppType,
        parameters['apptype']?.toString() ?? '',
      );
      await _prefs.setString(
        _keyUserId,
        parameters['mobile']?.toString() ?? '',
      );
      await _prefs.setString(
        _keyPassword,
        parameters['password']?.toString() ?? '',
      );
      await _prefs.setString(
        _keySalesRep,
        parameters['empid']?.toString() ?? '',
      );

      // NOTE: CustomerID is NOT available in login response
      // It will be fetched and stored from CustomerData API after login
      // No longer hardcoded based on mobile number

      // Store additional employee information
      await _prefs.setString(
        _keyEmpName,
        parameters['empname']?.toString() ?? '',
      );
      await _prefs.setString(
        _keyRolesId,
        parameters['rolesid']?.toString() ?? '',
      );
      await _prefs.setString(
        _keyRolesName,
        parameters['rolesname']?.toString() ?? '',
      );
      await _prefs.setString(
        _keyTokenId,
        parameters['tokenid']?.toString() ?? '',
      );

      print('✅ AppContext initialized successfully');
      print('   - Protocol: $protocol');
      print('   - Host: $host');
      print('   - AcOwner: $acOwner');
      print('   - AppType: $appType');
      print('   - UserID: $userId');
      print('   - SalesRep: $salesRep');
      print('   - CustomerID: $customerId'); // Removed hardcoded mapping
      print('   - EmpName: $empName');
      print('   - TokenId: $tokenId');
    }
  }

  /// Get protocol from environment (http/https)
  String get protocol => _prefs.getString(_keyProtocol) ?? environment.protocol;

  /// Get host/port from environment (3030 for Production, 3032 for UAT)
  String get host => _prefs.getString(_keyHost) ?? environment.port;

  /// Get AcOwner from login response
  String get acOwner => _prefs.getString(_keyAcOwner) ?? '';

  /// Get AppType from login response
  String get appType => _prefs.getString(_keyAppType) ?? '';

  /// Get UserID (mobile) from login response
  String get userId => _prefs.getString(_keyUserId) ?? '';

  /// Get Password from login response
  String get password => _prefs.getString(_keyPassword) ?? '';

  /// Get SalesRep (empid) from login response
  String get salesRep => _prefs.getString(_keySalesRep) ?? '';

  /// Get CustomerID from CustomerData API
  String get customerId => _prefs.getString(_keyCustomerId) ?? '';

  /// Get Employee Name
  String get empName => _prefs.getString(_keyEmpName) ?? '';

  /// Get Roles ID
  String get rolesId => _prefs.getString(_keyRolesId) ?? '';

  /// Get Roles Name
  String get rolesName => _prefs.getString(_keyRolesName) ?? '';

  /// Get Token ID
  String get tokenId => _prefs.getString(_keyTokenId) ?? '';

  /// Get all login parameters
  Map<String, dynamic>? get loginParameters {
    final paramsString = _prefs.getString(_keyLoginParameters);
    if (paramsString != null) {
      try {
        return jsonDecode(paramsString) as Map<String, dynamic>;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// API Server IP Address (from environment)
  String get serverIp => environment.serverIp;

  /// Company Information
  static const String companyName = 'Sri Venkateshwara Auto Parts';
  static const String companyNameFull =
      'Sri Venkateshwara Auto Parts Private Limited';

  /// Admin Contact Information
  static const String adminName = 'Ganesh';
  static const String adminPhone = '8142043894';
  static const String adminPhoneFormatted = '+91 81420 43894';
  static const String adminPhoneDialable = '+918142043894';
  static const String adminEmail = 'accounts@ricomtechnologies.com';

  /// Promotional Content
  static const String promoYoutubeUrl =
      'https://www.youtube.com/watch?v=mrYno_FPUlk';
  static const String promoYoutubeVideoId = 'mrYno_FPUlk';

  /// Build API base URL from environment configuration
  String get apiBaseUrl => environment.baseUrl;

  /// Build API base URL with custom port (for special endpoints)
  String getApiBaseUrlWithPort(String port) => '$protocol://$serverIp:$port';

  /// Get API parameters for requests
  Map<String, String> get apiParameters => {
    'AcOwner': acOwner,
    'AppType': appType,
    'UserID': userId,
    'Password': password,
    'SalesRep': salesRep,
    'CustomerID': customerId,
  };

  /// Get query parameters as a formatted string
  String get apiQueryString {
    final params = apiParameters;
    return params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  /// Check if context is initialized
  bool get isInitialized => acOwner.isNotEmpty && userId.isNotEmpty;

  /// Store customer data from CustomerData API
  /// Also extracts and stores the CustomerID from the response
  Future<void> storeCustomerData(Map<String, dynamic> customerData) async {
    await _prefs.setString(_keyCustomerData, jsonEncode(customerData));

    print('');
    print('╔═══════════════════════════════════════════════════════════════╗');
    print('║        EXTRACTING CUSTOMER ID FROM API RESPONSE              ║');
    print('╚═══════════════════════════════════════════════════════════════╝');
    print('');

    // Extract CustomerID from the API response
    // API structure: {success: true, message: "...", parameters: [{customerid: "102177", ...}]}
    final parameters = customerData['parameters'];

    print('📊 Response Structure Analysis:');
    print('   - Response keys: ${customerData.keys.join(", ")}');
    print('   - Parameters type: ${parameters.runtimeType}');

    if (parameters is List && parameters.isNotEmpty) {
      final firstItem = parameters.first;
      print('   - First item type: ${firstItem.runtimeType}');
      print(
        '   - First item keys: ${firstItem is Map ? firstItem.keys.join(", ") : "N/A"}',
      );
      print('');

      if (firstItem is Map) {
        final extractedCustomerId = firstItem['customerid']?.toString();

        if (extractedCustomerId != null && extractedCustomerId.isNotEmpty) {
          await _prefs.setString(_keyCustomerId, extractedCustomerId);
          print('✅ CustomerID extracted and stored successfully');
          print('   📌 CustomerID: "$extractedCustomerId"');
          print('');
        } else {
          print('❌ CustomerID NOT FOUND in response!');
          print('   Looking for key: "customerid"');
          print('   Value found: ${firstItem['customerid']}');
          print('');
          print('   Available keys in first item:');
          firstItem.forEach((key, value) {
            print('      - $key: $value');
          });
          print('');
        }
      }
    } else {
      print('');
      print('❌ Invalid CustomerData response structure!');
      print('   - Expected: List with at least one item');
      print('   - Got: ${parameters.runtimeType}');
      print('   - Response keys: ${customerData.keys.join(", ")}');
      print('');
    }
  }

  /// Get stored customer data
  Map<String, dynamic>? get customerData {
    final dataString = _prefs.getString(_keyCustomerData);
    if (dataString != null) {
      try {
        return jsonDecode(dataString) as Map<String, dynamic>;
      } catch (e) {
        print('❌ Error parsing customer data: $e');
        return null;
      }
    }
    return null;
  }

  /// Store customer address from GetAddress API
  Future<void> storeCustomerAddress(Map<String, dynamic> addressData) async {
    await _prefs.setString(_keyCustomerAddress, jsonEncode(addressData));
    print('✅ Customer address stored successfully');
  }

  /// Get stored customer address
  Map<String, dynamic>? get customerAddress {
    final dataString = _prefs.getString(_keyCustomerAddress);
    if (dataString != null) {
      try {
        return jsonDecode(dataString) as Map<String, dynamic>;
      } catch (e) {
        print('❌ Error parsing customer address: $e');
        return null;
      }
    }
    return null;
  }

  /// Get formatted delivery address string
  String get deliveryAddress {
    final address = customerAddress;
    if (address == null) {
      print('⚠️ No customer address stored');
      return 'No address available';
    }

    print('📍 Parsing customer address from stored data...');
    print('   - Keys in response: ${address.keys.join(", ")}');

    // Try to extract address from different possible structures
    // The API might return addresses as a list or direct data
    final parameters = address['parameters'] ?? address['Parameters'];
    final addresses = address['addresses'] ?? address['Addresses'];
    final data = address['data'] ?? address['Data'];
    final result = address['result'] ?? address['Result'];

    String? addressLine;
    String? addressLine1;
    String? addressLine2;
    String? city;
    String? state;
    String? pincode;

    // Check if parameters contains address list (primary structure from GetAddress API)
    if (parameters is List && parameters.isNotEmpty) {
      print('   - Found parameters list with ${parameters.length} items');
      final firstAddress = parameters.first;
      // Address structure: Address, Address1, Address2, City, State, Zip
      addressLine = firstAddress['Address'];
      addressLine1 = firstAddress['Address1'];
      addressLine2 = firstAddress['Address2'];
      city = firstAddress['City'];
      state = firstAddress['State'];
      pincode = firstAddress['Zip'];
    }
    // Check if it's a list of addresses, use first or default
    else if (addresses is List && addresses.isNotEmpty) {
      print('   - Found addresses list with ${addresses.length} items');
      final firstAddress = addresses.firstWhere(
        (addr) => addr['isDefault'] == true || addr['IsDefault'] == true,
        orElse: () => addresses.first,
      );
      addressLine1 =
          firstAddress['addressLine1'] ??
          firstAddress['AddressLine1'] ??
          firstAddress['address1'] ??
          firstAddress['Address1'];
      addressLine2 =
          firstAddress['addressLine2'] ??
          firstAddress['AddressLine2'] ??
          firstAddress['address2'] ??
          firstAddress['Address2'];
      city = firstAddress['city'] ?? firstAddress['City'];
      state = firstAddress['state'] ?? firstAddress['State'];
      pincode =
          firstAddress['pincode'] ??
          firstAddress['Pincode'] ??
          firstAddress['PinCode'] ??
          firstAddress['pinCode'] ??
          firstAddress['zip'] ??
          firstAddress['Zip'];
    } else if (data != null) {
      print('   - Found data object');
      // Direct data structure
      addressLine = data['Address'];
      addressLine1 =
          data['addressLine1'] ??
          data['AddressLine1'] ??
          data['address1'] ??
          data['Address1'];
      addressLine2 =
          data['addressLine2'] ??
          data['AddressLine2'] ??
          data['address2'] ??
          data['Address2'];
      city = data['city'] ?? data['City'];
      state = data['state'] ?? data['State'];
      pincode =
          data['pincode'] ??
          data['Pincode'] ??
          data['PinCode'] ??
          data['pinCode'] ??
          data['zip'] ??
          data['Zip'];
    } else if (result != null) {
      print('   - Found result object');
      // Result structure
      addressLine = result['Address'];
      addressLine1 =
          result['addressLine1'] ??
          result['AddressLine1'] ??
          result['address1'] ??
          result['Address1'];
      addressLine2 =
          result['addressLine2'] ??
          result['AddressLine2'] ??
          result['address2'] ??
          result['Address2'];
      city = result['city'] ?? result['City'];
      state = result['state'] ?? result['State'];
      pincode =
          result['pincode'] ??
          result['Pincode'] ??
          result['PinCode'] ??
          result['pinCode'] ??
          result['zip'] ??
          result['Zip'];
    } else {
      print('   - Trying direct address structure');
      // Try direct structure
      addressLine = address['Address'];
      addressLine1 =
          address['addressLine1'] ??
          address['AddressLine1'] ??
          address['address1'] ??
          address['Address1'];
      addressLine2 =
          address['addressLine2'] ??
          address['AddressLine2'] ??
          address['address2'] ??
          address['Address2'];
      city = address['city'] ?? address['City'];
      state = address['state'] ?? address['State'];
      pincode =
          address['pincode'] ??
          address['Pincode'] ??
          address['PinCode'] ??
          address['pinCode'] ??
          address['zip'] ??
          address['Zip'];
    }

    // Build formatted address
    final parts = <String>[];
    if (addressLine != null && addressLine.isNotEmpty) {
      parts.add(addressLine);
    }
    if (addressLine1 != null && addressLine1.isNotEmpty) {
      parts.add(addressLine1);
    }
    if (addressLine2 != null && addressLine2.isNotEmpty) {
      parts.add(addressLine2);
    }
    if (city != null && city.isNotEmpty) parts.add(city);
    if (state != null && state.isNotEmpty) parts.add(state);
    if (pincode != null && pincode.isNotEmpty) parts.add(pincode);

    print('   - Parsed address parts: ${parts.join(", ")}');

    return parts.isNotEmpty ? parts.join(', ') : 'No address available';
  }

  /// Clear all context data
  Future<void> clear() async {
    await _prefs.remove(_keyProtocol);
    await _prefs.remove(_keyHost);
    await _prefs.remove(_keyAcOwner);
    await _prefs.remove(_keyAppType);
    await _prefs.remove(_keyUserId);
    await _prefs.remove(_keyPassword);
    await _prefs.remove(_keySalesRep);
    await _prefs.remove(_keyCustomerId);
    await _prefs.remove(_keyEmpName);
    await _prefs.remove(_keyRolesId);
    await _prefs.remove(_keyRolesName);
    await _prefs.remove(_keyTokenId);
    await _prefs.remove(_keyLoginParameters);
    await _prefs.remove(_keyCustomerData);
    await _prefs.remove(_keyCustomerAddress);
    print('🗑️  AppContext cleared');
  }

  /// Get user roles as a list
  List<String> get userRoles {
    final rolesString = rolesName;
    if (rolesString.isEmpty) return [];
    return rolesString.split(',').map((r) => r.trim()).toList();
  }

  /// Get role IDs as a list
  List<String> get roleIds {
    final rolesIdString = rolesId;
    if (rolesIdString.isEmpty) return [];
    return rolesIdString.split(',').map((r) => r.trim()).toList();
  }

  /// Check if user has a specific role
  bool hasRole(String roleName) {
    return userRoles.any(
      (role) => role.toLowerCase() == roleName.toLowerCase(),
    );
  }

  /// Print current context for debugging
  void printContext() {
    print('📋 App Context:');
    print('   - Protocol: $protocol');
    print('   - Host: $host');
    print('   - API Base URL: $apiBaseUrl');
    print('   - AcOwner: $acOwner');
    print('   - AppType: $appType');
    print('   - UserID: $userId');
    print('   - Password: ${password.isNotEmpty ? '***' : 'not set'}');
    print('   - SalesRep: $salesRep');
    print('   - CustomerID: $customerId');
    print('   - EmpName: $empName');
    print('   - Roles: ${userRoles.join(', ')}');
    print('   - TokenId: $tokenId');
    print('   - Initialized: $isInitialized');
  }

  /// Save login credentials for "Remember Me" functionality
  Future<void> saveLoginCredentials({
    required String phoneNumber,
    required String password,
    required bool rememberMe,
  }) async {
    await _prefs.setBool(_keyRememberMe, rememberMe);

    if (rememberMe) {
      await _prefs.setString(_keySavedPhone, phoneNumber);
      await _prefs.setString(_keySavedPassword, password);
      print('✅ Login credentials saved for Remember Me');
    } else {
      await _prefs.remove(_keySavedPhone);
      await _prefs.remove(_keySavedPassword);
      print('🗑️ Login credentials cleared (Remember Me disabled)');
    }
  }

  /// Get saved login credentials
  Map<String, String?> getSavedLoginCredentials() {
    final rememberMe = _prefs.getBool(_keyRememberMe) ?? false;
    if (!rememberMe) {
      return {'phone': null, 'password': null, 'rememberMe': 'false'};
    }

    return {
      'phone': _prefs.getString(_keySavedPhone),
      'password': _prefs.getString(_keySavedPassword),
      'rememberMe': 'true',
    };
  }

  /// Check if Remember Me is enabled
  bool get isRememberMeEnabled => _prefs.getBool(_keyRememberMe) ?? false;

  /// Clear saved login credentials
  Future<void> clearSavedCredentials() async {
    await _prefs.remove(_keyRememberMe);
    await _prefs.remove(_keySavedPhone);
    await _prefs.remove(_keySavedPassword);
    print('🗑️ Saved login credentials cleared');
  }
}
