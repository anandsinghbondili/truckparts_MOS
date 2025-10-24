import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../features/auth/data/datasources/auth_local_datasource.dart';
import '../features/auth/data/datasources/auth_remote_datasource.dart';
// import '../features/auth/data/repositories/auth_repository_impl.dart'; // COMMENTED OUT - ORIGINAL IMPLEMENTATION
import '../features/auth/data/repositories/emp_auth_repository_impl.dart';
import '../features/auth/data/services/emp_login_service.dart';
import '../features/auth/data/services/password_reset_service.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/cart/data/services/cart_service.dart';
import '../features/cart/data/services/cart_api_service.dart';
import '../features/cart/data/services/cart_operations_service.dart';
import '../features/cart/data/services/order_placement_service.dart';
import '../features/orders/data/services/order_details_service.dart';
import '../features/orders/data/services/sales_order_api_service.dart';
import '../features/orders/data/services/order_service.dart';
import '../features/auth/data/services/customer_data_service.dart';
import '../features/auth/data/services/customer_address_service.dart';
import '../features/home/data/services/item_details_by_customer_service.dart';
import '../features/home/data/services/parts_data_service.dart';
import '../features/text_scanner/data/datasources/image_service.dart';
import '../features/text_scanner/data/datasources/permission_service.dart';
import '../features/text_scanner/data/datasources/text_recognition_service.dart';
import '../features/text_scanner/data/repositories/text_recognition_repository_impl.dart';
import '../features/text_scanner/domain/repositories/text_recognition_repository.dart';
import '../features/text_scanner/domain/usecases/capture_image_usecase.dart';
import '../features/text_scanner/domain/usecases/pick_image_usecase.dart';
import '../features/text_scanner/domain/usecases/recognize_text_usecase.dart';
import '../features/text_scanner/domain/usecases/request_permissions_usecase.dart';
import '../features/text_scanner/presentation/bloc/text_scanner_bloc.dart';
import '../features/text_scanner/data/services/text_match_service.dart';
import 'network/api_client.dart';
import 'network/network_info.dart';
import 'services/app_context_service.dart';
import 'services/data_loading_service.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // Initialize Hive
  await Hive.initFlutter();

  // Initialize SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPreferences);

  // Register core dependencies
  getIt.registerSingleton<Dio>(DioModule.createDio(sharedPreferences));
  getIt.registerSingleton<Connectivity>(Connectivity());

  // Register network dependencies
  getIt.registerSingleton<NetworkInfo>(NetworkInfoImpl(getIt<Connectivity>()));
  getIt.registerSingleton<ApiClient>(ApiClient(getIt<Dio>()));

  // Register App Context Service
  getIt.registerSingleton<AppContextService>(
    AppContextService(getIt<SharedPreferences>()),
  );

  // Register Data Loading Service
  getIt.registerSingleton<DataLoadingService>(DataLoadingService());

  // Register auth data sources
  getIt.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(
      sharedPreferences: getIt<SharedPreferences>(),
      secureStorage: const FlutterSecureStorage(),
    ),
  );

  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(apiClient: getIt<ApiClient>()),
  );

  // Register Employee Login Service
  getIt.registerLazySingleton<EmpLoginService>(
    () => EmpLoginService(dio: getIt<Dio>()),
  );

  // Register Customer Data Service
  getIt.registerLazySingleton<CustomerDataService>(
    () => CustomerDataService(dio: getIt<Dio>()),
  );

  // Register Customer Address Service
  getIt.registerLazySingleton<CustomerAddressService>(
    () => CustomerAddressService(dio: getIt<Dio>()),
  );

  // Register ItemDetailsbyCustomer Service
  getIt.registerLazySingleton<ItemDetailsByCustomerService>(
    () => ItemDetailsByCustomerService(dio: getIt<Dio>()),
  );

  // Register Parts Data Service (Singleton to store parts data)
  getIt.registerSingleton<PartsDataService>(PartsDataService());

  // Register Password Reset Service
  getIt.registerLazySingleton<PasswordResetService>(
    () => PasswordResetService(
      dio: getIt<Dio>(),
      appContext: getIt<AppContextService>(),
    ),
  );

  // Register auth repository - COMMENTED OUT ORIGINAL IMPLEMENTATION
  // getIt.registerLazySingleton<AuthRepository>(
  //   () => AuthRepositoryImpl(
  //     remoteDataSource: getIt<AuthRemoteDataSource>(),
  //     localDataSource: getIt<AuthLocalDataSource>(),
  //     networkInfo: getIt<NetworkInfo>(),
  //   ),
  // );

  // Register NEW Employee Auth repository
  getIt.registerLazySingleton<AuthRepository>(
    () => EmpAuthRepositoryImpl(
      empLoginService: getIt<EmpLoginService>(),
      customerDataService: getIt<CustomerDataService>(),
      customerAddressService: getIt<CustomerAddressService>(),
      itemDetailsByCustomerService: getIt<ItemDetailsByCustomerService>(),
      partsDataService: getIt<PartsDataService>(),
      localDataSource: getIt<AuthLocalDataSource>(),
      networkInfo: getIt<NetworkInfo>(),
      appContextService: getIt<AppContextService>(),
      dataLoadingService: getIt<DataLoadingService>(),
    ),
  );

  // Register auth bloc
  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(authRepository: getIt<AuthRepository>()),
  );

  // Register cart services
  getIt.registerSingleton<CartService>(CartService());

  getIt.registerLazySingleton<CartApiService>(
    () => CartApiService(
      dio: getIt<Dio>(),
      appContext: getIt<AppContextService>(),
    ),
  );

  getIt.registerLazySingleton<CartOperationsService>(
    () => CartOperationsService(
      dio: getIt<Dio>(),
      appContext: getIt<AppContextService>(),
    ),
  );

  getIt.registerLazySingleton<OrderPlacementService>(
    () => OrderPlacementService(
      dio: getIt<Dio>(),
      appContext: getIt<AppContextService>(),
    ),
  );

  getIt.registerLazySingleton<OrderDetailsService>(
    () => OrderDetailsService(
      dio: getIt<Dio>(),
      appContext: getIt<AppContextService>(),
    ),
  );

  getIt.registerLazySingleton<SalesOrderApiService>(
    () => SalesOrderApiService(
      dio: getIt<Dio>(),
      appContext: getIt<AppContextService>(),
    ),
  );

  getIt.registerLazySingleton<OrderService>(
    () => OrderService(salesOrderApiService: getIt<SalesOrderApiService>()),
  );

  // Register text scanner dependencies
  getIt.registerLazySingleton<ImageService>(() => ImageService());
  getIt.registerLazySingleton<PermissionService>(() => PermissionService());
  getIt.registerLazySingleton<TextRecognitionService>(
    () => TextRecognitionService(),
  );

  getIt.registerLazySingleton<TextMatchService>(() => TextMatchService());

  getIt.registerLazySingleton<TextRecognitionRepository>(
    () => TextRecognitionRepositoryImpl(
      imageService: getIt<ImageService>(),
      permissionService: getIt<PermissionService>(),
      textRecognitionService: getIt<TextRecognitionService>(),
    ),
  );

  getIt.registerLazySingleton<CaptureImageUseCase>(
    () => CaptureImageUseCase(getIt<TextRecognitionRepository>()),
  );

  getIt.registerLazySingleton<PickImageUseCase>(
    () => PickImageUseCase(getIt<TextRecognitionRepository>()),
  );

  getIt.registerLazySingleton<RecognizeTextUseCase>(
    () => RecognizeTextUseCase(getIt<TextRecognitionRepository>()),
  );

  getIt.registerLazySingleton<RequestPermissionsUseCase>(
    () => RequestPermissionsUseCase(getIt<TextRecognitionRepository>()),
  );

  getIt.registerFactory<TextScannerBloc>(
    () => TextScannerBloc(
      captureImageUseCase: getIt<CaptureImageUseCase>(),
      pickImageUseCase: getIt<PickImageUseCase>(),
      recognizeTextUseCase: getIt<RecognizeTextUseCase>(),
      requestPermissionsUseCase: getIt<RequestPermissionsUseCase>(),
    ),
  );
}
