import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/app_context_service.dart';
import '../../../../core/services/data_loading_service.dart';
import '../../domain/entities/auth_tokens.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../services/emp_login_service.dart';
import '../services/customer_data_service.dart';
import '../services/customer_address_service.dart';
import '../../../home/data/services/item_details_by_customer_service.dart';
import '../../../home/data/services/parts_data_service.dart';

/// Repository implementation for Employee Login API integration
/// This implementation uses the new API endpoint while keeping the existing
/// functionality commented out for reference
class EmpAuthRepositoryImpl implements AuthRepository {
  final EmpLoginService empLoginService;
  final CustomerDataService customerDataService;
  final CustomerAddressService customerAddressService;
  final ItemDetailsByCustomerService itemDetailsByCustomerService;
  final PartsDataService partsDataService;
  final AuthLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  final AppContextService appContextService;
  final DataLoadingService dataLoadingService;

  EmpAuthRepositoryImpl({
    required this.empLoginService,
    required this.customerDataService,
    required this.customerAddressService,
    required this.itemDetailsByCustomerService,
    required this.partsDataService,
    required this.localDataSource,
    required this.networkInfo,
    required this.appContextService,
    required this.dataLoadingService,
  });

  @override
  Future<Result<AuthTokens>> login({
    required String phoneNumber,
    required String password,
    bool rememberMe = false,
  }) async {
    // EMPLOYEE API INTEGRATION - Employee Login
    if (await networkInfo.isConnected) {
      try {
        print(
          '🔄 EmpAuthRepository: Calling API with - Phone: $phoneNumber, Password: ${password.replaceRange(2, password.length, '*' * (password.length - 2))}',
        );

        final response = await empLoginService.login(
          mobileNo: phoneNumber,
          password: password,
        );

        // Parse the response and create AuthTokens
        print('🔄 EmpAuthRepository: Parsing response: $response');
        final empResponse = EmpLoginResponse.fromJson(response);
        print(
          '🔄 EmpAuthRepository: Parsed response - success: ${empResponse.success}, message: ${empResponse.message}',
        );

        if (empResponse.success) {
          // Initialize App Context with login response
          await appContextService.initializeFromLoginResponse(response);

          // Save login credentials if Remember Me is enabled
          await appContextService.saveLoginCredentials(
            phoneNumber: phoneNumber,
            password: password,
            rememberMe: rememberMe,
          );

          // Start background data fetch asynchronously (non-blocking)
          final loginCompleteTime = DateTime.now();
          print('');
          print(
            '╔════════════════════════════════════════════════════════════════╗',
          );
          print(
            '║  ✅ LOGIN SUCCESSFUL - Starting Background Data Fetch        ║',
          );
          print(
            '╚════════════════════════════════════════════════════════════════╝',
          );
          print('⏰ Time: ${loginCompleteTime.toIso8601String()}');
          print('🚀 Launching async background fetch (NON-BLOCKING)...');
          print('   User will see Home page immediately!');
          print('');

          _fetchBackgroundData(
                appContextService: appContextService,
                customerDataService: customerDataService,
                customerAddressService: customerAddressService,
                itemDetailsByCustomerService: itemDetailsByCustomerService,
                partsDataService: partsDataService,
                dataLoadingService: dataLoadingService,
              )
              .then((_) {
                final completionTime = DateTime.now();
                final duration = completionTime.difference(loginCompleteTime);
                print('');
                print(
                  '╔════════════════════════════════════════════════════════════════╗',
                );
                print(
                  '║  ✅ ALL BACKGROUND DATA FETCH COMPLETED                       ║',
                );
                print(
                  '╚════════════════════════════════════════════════════════════════╝',
                );
                print('⏱️  Total time: ${duration.inMilliseconds}ms');
                print('');
              })
              .catchError((error) {
                print('');
                print(
                  '╔════════════════════════════════════════════════════════════════╗',
                );
                print(
                  '║  ❌ BACKGROUND DATA FETCH FAILED                              ║',
                );
                print(
                  '╚════════════════════════════════════════════════════════════════╝',
                );
                print('Error: $error');
                print('');
              });

          // Create AuthTokens from the API response
          final tokens = AuthTokens(
            accessToken:
                empResponse.token ??
                'emp_access_token_${DateTime.now().millisecondsSinceEpoch}',
            refreshToken:
                empResponse.refreshToken ??
                'emp_refresh_token_${DateTime.now().millisecondsSinceEpoch}',
            expiresIn: empResponse.expiresIn ?? 3600, // Default 1 hour
          );

          // Save tokens locally
          await localDataSource.saveTokens(tokens);

          // Create user from response parameters if available
          if (empResponse.parameters != null) {
            final user = User(
              id:
                  empResponse.parameters!['empid']?.toString() ??
                  'emp_user_${DateTime.now().millisecondsSinceEpoch}',
              name:
                  empResponse.parameters!['empname']?.toString() ??
                  'Employee User',
              email: '', // API doesn't provide email
              phoneNumber: phoneNumber,
              profileImage: null, // API doesn't provide profile image
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            await localDataSource.saveUser(user);
          }

          return Result.success(tokens);
        } else {
          return Result.failure(
            ServerFailure(message: empResponse.message ?? 'Login failed'),
          );
        }
      } on EmpLoginException catch (e) {
        return Result.failure(ServerFailure(message: e.message));
      } catch (e) {
        return Result.failure(ServerFailure(message: e.toString()));
      }
    } else {
      return const Result.failure(
        NetworkFailure(message: 'No internet connection'),
      );
    }

    /* COMMENTED OUT - ORIGINAL LOGIN IMPLEMENTATION
    // Bypass login for test credentials
    if (phoneNumber == '9988776655' && password == 'welcome123') {
      final testTokens = AuthTokens(
        accessToken: 'test_access_token_12345',
        refreshToken: 'test_refresh_token_67890',
        expiresIn: 3600,
      );
      await localDataSource.saveTokens(testTokens);

      // Also save a test user
      final testUser = User(
        id: 'test_user_123',
        name: 'Test User',
        email: 'test@truckparts.com',
        phoneNumber: phoneNumber,
        profileImage: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await localDataSource.saveUser(testUser);

      return Result.success(testTokens);
    }

    if (await networkInfo.isConnected) {
      try {
        final tokens = await remoteDataSource.login(
          phoneNumber: phoneNumber,
          password: password,
        );

        await localDataSource.saveTokens(tokens);
        return Result.success(tokens);
      } catch (e) {
        return Result.failure(ServerFailure(message: e.toString()));
      }
    } else {
      return const Result.failure(
        NetworkFailure(message: 'No internet connection'),
      );
    }
    */
  }

  @override
  Future<Result<void>> forgotPassword({required String phoneNumber}) async {
    // For now, return success as the new API might not have forgot password
    // This can be implemented later when the API endpoint is available
    return const Result.success(null);

    /* COMMENTED OUT - ORIGINAL FORGOT PASSWORD IMPLEMENTATION
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.forgotPassword(phoneNumber: phoneNumber);
        return const Result.success(null);
      } catch (e) {
        return Result.failure(ServerFailure(message: e.toString()));
      }
    } else {
      return const Result.failure(
        NetworkFailure(message: 'No internet connection'),
      );
    }
    */
  }

  @override
  Future<Result<void>> resetPassword({
    required String phoneNumber,
    required String otp,
    required String newPassword,
  }) async {
    // For now, return success as the new API might not have reset password
    // This can be implemented later when the API endpoint is available
    return const Result.success(null);

    /* COMMENTED OUT - ORIGINAL RESET PASSWORD IMPLEMENTATION
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.resetPassword(
          phoneNumber: phoneNumber,
          otp: otp,
          newPassword: newPassword,
        );
        return const Result.success(null);
      } catch (e) {
        return Result.failure(ServerFailure(message: e.toString()));
      }
    } else {
      return const Result.failure(
        NetworkFailure(message: 'No internet connection'),
      );
    }
    */
  }

  @override
  Future<Result<void>> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    // For now, return success as the new API might not have OTP verification
    // This can be implemented later when the API endpoint is available
    return const Result.success(null);

    /* COMMENTED OUT - ORIGINAL OTP VERIFICATION IMPLEMENTATION
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.verifyOtp(phoneNumber: phoneNumber, otp: otp);
        return const Result.success(null);
      } catch (e) {
        return Result.failure(ServerFailure(message: e.toString()));
      }
    } else {
      return const Result.failure(
        NetworkFailure(message: 'No internet connection'),
      );
    }
    */
  }

  @override
  Future<Result<AuthTokens>> refreshToken({
    required String refreshToken,
  }) async {
    // For now, return the stored tokens as the new API might not have refresh token
    // This can be implemented later when the API endpoint is available
    try {
      final tokens = await localDataSource.getTokens();
      if (tokens != null) {
        return Result.success(tokens);
      } else {
        return const Result.failure(CacheFailure(message: 'No tokens found'));
      }
    } catch (e) {
      return Result.failure(CacheFailure(message: e.toString()));
    }

    /* COMMENTED OUT - ORIGINAL REFRESH TOKEN IMPLEMENTATION
    if (await networkInfo.isConnected) {
      try {
        final tokens = await remoteDataSource.refreshToken(
          refreshToken: refreshToken,
        );

        await localDataSource.saveTokens(tokens);
        return Result.success(tokens);
      } catch (e) {
        return Result.failure(ServerFailure(message: e.toString()));
      }
    } else {
      return const Result.failure(
        NetworkFailure(message: 'No internet connection'),
      );
    }
    */
  }

  @override
  Future<Result<User>> getUserProfile() async {
    // First try to get user from local storage
    try {
      final user = await localDataSource.getUser();
      if (user != null) {
        return Result.success(user);
      }
    } catch (e) {
      // Continue to try remote if local fails
    }

    // If no local user, return a default user
    // This can be enhanced when user profile API is available
    final defaultUser = User(
      id: 'emp_user_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Employee User',
      email: '',
      phoneNumber: '',
      profileImage: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return Result.success(defaultUser);

    /* COMMENTED OUT - ORIGINAL GET USER PROFILE IMPLEMENTATION
    // First try to get user from local storage (for bypassed login)
    try {
      final user = await localDataSource.getUser();
      if (user != null) {
        return Result.success(user);
      }
    } catch (e) {
      // Continue to try remote if local fails
    }

    // If no local user, try to get from remote (for real API calls)
    if (await networkInfo.isConnected) {
      try {
        final user = await remoteDataSource.getUserProfile();
        await localDataSource.saveUser(user);
        return Result.success(user);
      } catch (e) {
        // If API fails, check if we have any local user data
        try {
          final localUser = await localDataSource.getUser();
          if (localUser != null) {
            return Result.success(localUser);
          }
        } catch (localError) {
          // Ignore local errors
        }
        return Result.failure(ServerFailure(message: e.toString()));
      }
    } else {
      return const Result.failure(CacheFailure(message: 'No user data found'));
    }
    */
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await localDataSource.clearTokens();
      await localDataSource.clearUser();

      // Clear app context on logout, but preserve Remember Me credentials
      await appContextService.clear();

      // Only clear saved credentials if Remember Me is not enabled
      if (!appContextService.isRememberMeEnabled) {
        await appContextService.clearSavedCredentials();
      }

      return const Result.success(null);
    } catch (e) {
      return Result.failure(CacheFailure(message: e.toString()));
    }

    /* COMMENTED OUT - ORIGINAL LOGOUT IMPLEMENTATION
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.logout();
      } catch (e) {
        // Continue with local logout even if remote logout fails
      }
    }

    try {
      await localDataSource.clearTokens();
      await localDataSource.clearUser();
      return const Result.success(null);
    } catch (e) {
      return Result.failure(CacheFailure(message: e.toString()));
    }
    */
  }

  @override
  Future<Result<bool>> isAuthenticated() async {
    try {
      final isAuth = await localDataSource.isAuthenticated();
      return Result.success(isAuth);
    } catch (e) {
      return Result.failure(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> saveTokens(AuthTokens tokens) async {
    try {
      await localDataSource.saveTokens(tokens);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<AuthTokens?>> getStoredTokens() async {
    try {
      final tokens = await localDataSource.getTokens();
      return Result.success(tokens);
    } catch (e) {
      return Result.failure(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> clearTokens() async {
    try {
      await localDataSource.clearTokens();
      return const Result.success(null);
    } catch (e) {
      return Result.failure(CacheFailure(message: e.toString()));
    }
  }

  /// Fetch customer data, address, and items in the background (non-blocking)
  Future<void> _fetchBackgroundData({
    required AppContextService appContextService,
    required CustomerDataService customerDataService,
    required CustomerAddressService customerAddressService,
    required ItemDetailsByCustomerService itemDetailsByCustomerService,
    required PartsDataService partsDataService,
    required DataLoadingService dataLoadingService,
  }) async {
    try {
      // Get parameters for data fetching
      final salesRep = appContextService.salesRep;
      final acOwner = appContextService.acOwner;
      final tokenIdValue = appContextService.tokenId;

      print('');
      print(
        '╔════════════════════════════════════════════════════════════════╗',
      );
      print('║  ⚡ OPTIMIZED DATA FETCH: Items Priority + Parallel Loading   ║');
      print(
        '╚════════════════════════════════════════════════════════════════╝',
      );
      print(
        'Strategy: 1. Fetch CustomerData → 2. Parallel fetch Items & Address',
      );
      print('');
      print('Checking parameters availability...');
      print(
        '  - SalesRep: "$salesRep" (${salesRep.isEmpty ? "EMPTY!" : "OK"})',
      );
      print('  - AcOwner: "$acOwner" (${acOwner.isEmpty ? "EMPTY!" : "OK"})');
      print(
        '  - TokenId: "$tokenIdValue" (${tokenIdValue.isEmpty ? "EMPTY!" : "OK"})',
      );

      if (salesRep.isEmpty || acOwner.isEmpty || tokenIdValue.isEmpty) {
        print(
          '⚠️ EmpAuthRepository: Missing required parameters for background data fetch',
        );
        print('   - SalesRep: ${salesRep.isEmpty ? "MISSING" : "OK"}');
        print('   - AcOwner: ${acOwner.isEmpty ? "MISSING" : "OK"}');
        print('   - TokenId: ${tokenIdValue.isEmpty ? "MISSING" : "OK"}');
        return;
      }

      print('✅ All parameters present, continuing...');

      // OPTIMIZED APPROACH: Fetch CustomerData FIRST to get CustomerId (required)
      // Then immediately fetch Items and Address IN PARALLEL for speed
      final startTime = DateTime.now();
      print('');
      print('⏰ Background Fetch Start Time: ${startTime.toIso8601String()}');
      print('');
      print('🚀 STEP 1: Fetching CustomerData (required for CustomerId)...');
      String customerId = '';

      try {
        final customerDataStart = DateTime.now();
        final customerData = await customerDataService.getCustomerData();

        await appContextService.storeCustomerData(customerData);
        customerId = appContextService.customerId;
        final customerDataDuration = DateTime.now().difference(
          customerDataStart,
        );
        print('');
        print('✅ CustomerData API completed');
        print('   ⏱️  Time taken: ${customerDataDuration.inMilliseconds}ms');
        print('   📌 Extracted CustomerId: "$customerId"');
        print('   📏 CustomerId length: ${customerId.length}');
        print('   🔍 CustomerId is empty: ${customerId.isEmpty}');
        print('');
      } catch (e) {
        print('');
        print('❌ Failed to fetch customer data: $e');
        print('   Cannot proceed without CustomerId');
        print('');
        return;
      }

      if (customerId.isEmpty) {
        print('');
        print(
          '╔════════════════════════════════════════════════════════════════╗',
        );
        print(
          '║  ❌ CRITICAL ERROR: CustomerId is EMPTY!                      ║',
        );
        print(
          '╚════════════════════════════════════════════════════════════════╝',
        );
        print('');
        print('Cannot fetch items and address without a valid CustomerID.');
        print('Please check the CustomerData API response structure.');
        print('');
        return;
      }

      print('');
      print(
        '╔════════════════════════════════════════════════════════════════╗',
      );
      print('║   🎯 NOW CALLING ItemDetailsbyCustomer API (PARALLEL)        ║');
      print(
        '╚════════════════════════════════════════════════════════════════╝',
      );
      print('⏰ API Call Start Time: ${DateTime.now().toIso8601String()}');
      print('');

      final appType = appContextService.appType;

      // Log the exact time when ItemDetailsbyCustomer will be called
      print('🌐 ABOUT TO CALL /api/Mobileapp/ItemDetailsbyCustomer');
      print('   with parameters:');
      print('   - CustomerID: $customerId');
      print('   - AcOwner: $acOwner');
      print('   - TokenId: $tokenIdValue');
      print('   - Type: $appType');
      print('');

      // STEP 2: Fetch Items AND Address IN PARALLEL (NO WAITING!)
      final results = await Future.wait([
        // Priority 1: Items fetch
        _fetchItemsData(
          customerId: customerId,
          acOwner: acOwner,
          tokenIdValue: tokenIdValue,
          appType: appType,
          itemDetailsByCustomerService: itemDetailsByCustomerService,
          partsDataService: partsDataService,
          appContextService: appContextService,
          dataLoadingService: dataLoadingService,
        ),
        // Priority 2: Address fetch (parallel)
        _fetchAddressData(
          customerId: customerId,
          customerAddressService: customerAddressService,
          appContextService: appContextService,
        ),
      ]);

      print('');
      print('✅ PARALLEL DATA FETCH COMPLETED');
      print('   - Items fetch: ${results[0] ? "SUCCESS" : "FAILED"}');
      print('   - Address fetch: ${results[1] ? "SUCCESS" : "FAILED"}');
      print('');
    } catch (e, stackTrace) {
      print('❌ Background data fetch error: $e');
      print('Stack trace: $stackTrace');
    }
  }

  /// Fetch items data - PRIORITY method with detailed logging
  Future<bool> _fetchItemsData({
    required String customerId,
    required String acOwner,
    required String tokenIdValue,
    required String appType,
    required ItemDetailsByCustomerService itemDetailsByCustomerService,
    required PartsDataService partsDataService,
    required AppContextService appContextService,
    required DataLoadingService dataLoadingService,
  }) async {
    // Track loading start time (declared outside try-catch for access in both blocks)
    late DateTime loadingStartTime;

    try {
      print('');
      print(
        '╔════════════════════════════════════════════════════════════════╗',
      );
      print('║  🎯 CALLING ItemDetailsbyCustomer API NOW!                   ║');
      print(
        '╚════════════════════════════════════════════════════════════════╝',
      );

      // Start loading indicator and record time
      loadingStartTime = DateTime.now();
      dataLoadingService.startLoadingItems();
      print('🔄 LOADING STARTED at: ${loadingStartTime.toIso8601String()}');

      print('');
      print('📋 Parameters:');
      print('   ├─ CustomerID: "$customerId"');
      print('   ├─ AcOwner: "$acOwner"');
      print('   ├─ TokenId: "$tokenIdValue"');
      print('   └─ Type: "$appType"');
      print('');

      // Print full AppContext for debugging
      print('📱 Full App Context:');
      appContextService.printContext();
      print('');

      final apiStartTime = DateTime.now();
      print('🌐 HTTP REQUEST STARTING at: ${apiStartTime.toIso8601String()}');
      print('');

      final items = await itemDetailsByCustomerService.getItemsByCustomer();

      final apiEndTime = DateTime.now();
      final apiDuration = apiEndTime.difference(apiStartTime);
      print('');
      print('📥 HTTP RESPONSE RECEIVED at: ${apiEndTime.toIso8601String()}');

      if (items.isEmpty) {
        final loadingEndTime = DateTime.now();
        final totalDuration = loadingEndTime.difference(loadingStartTime);

        print('');
        print('=' * 70);
        print('⚠️  ITEMS FETCH COMPLETED - NO DATA FOUND');
        print('   - Total items: 0');
        print('   - API call time: ${apiDuration.inMilliseconds}ms');
        print('   - Total loading time: ${totalDuration.inMilliseconds}ms');
        print('   - This customer has no items in the system yet.');
        print('=' * 70);
        print('');

        // Complete loading indicator
        dataLoadingService.completeLoadingItems();
        print('✅ LOADING ENDED at: ${loadingEndTime.toIso8601String()}');

        return true; // Still return true as the API call succeeded
      }

      partsDataService.storeParts(items);

      final loadingEndTime = DateTime.now();
      final totalDuration = loadingEndTime.difference(loadingStartTime);

      print('');
      print('=' * 70);
      print('✅ ITEMS FETCH COMPLETED SUCCESSFULLY!');
      print('   - Total items: ${items.length}');
      print(
        '   - API call time: ${apiDuration.inMilliseconds}ms (${(apiDuration.inMilliseconds / 1000).toStringAsFixed(2)}s)',
      );
      print(
        '   - Total loading time: ${totalDuration.inMilliseconds}ms (${(totalDuration.inMilliseconds / 1000).toStringAsFixed(2)}s)',
      );
      print(
        '   - PartsDataService initialized: ${partsDataService.isInitialized}',
      );
      print('=' * 70);
      print('');

      // Complete loading indicator
      dataLoadingService.completeLoadingItems();
      print('✅ LOADING ENDED at: ${loadingEndTime.toIso8601String()}');

      return true;
    } catch (e, stackTrace) {
      final loadingEndTime = DateTime.now();
      final errorDuration = loadingEndTime.difference(loadingStartTime);

      print('');
      print('=' * 70);
      print('❌ ITEMS FETCH FAILED: $e');
      print(
        '   - Error occurred after: ${errorDuration.inMilliseconds}ms (${(errorDuration.inMilliseconds / 1000).toStringAsFixed(2)}s)',
      );
      print('❌ Stack trace:');
      print(stackTrace);
      print('=' * 70);
      print('');

      // Complete loading indicator even on error
      dataLoadingService.completeLoadingItems();
      print('✅ LOADING ENDED at: ${loadingEndTime.toIso8601String()} (ERROR)');

      return false;
    }
  }

  /// Fetch address data - Lower priority, runs in parallel
  Future<bool> _fetchAddressData({
    required String customerId,
    required CustomerAddressService customerAddressService,
    required AppContextService appContextService,
  }) async {
    try {
      print('📍 Fetching customer address (parallel with items)...');
      print('   - CustomerId: ${appContextService.customerId}');

      final addressData = await customerAddressService.getCustomerAddress();

      await appContextService.storeCustomerAddress(addressData);
      print('✅ Address fetched successfully');
      return true;
    } catch (e) {
      print('⚠️ Failed to fetch address: $e');
      return false;
    }
  }
}
