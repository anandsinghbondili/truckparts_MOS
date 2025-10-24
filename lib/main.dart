import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';

import 'core/injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/services/data_loading_service.dart';
import 'core/widgets/focus_manager.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/cart/data/services/cart_service.dart';
import 'features/orders/data/services/order_service.dart';
import 'features/text_scanner/presentation/bloc/text_scanner_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait mode only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Configure dependencies
  await configureDependencies();

  // Initialize services
  final cartService = GetIt.instance<CartService>();
  await cartService.loadCart();

  // Don't load orders during app startup - load them when Orders page is opened
  // final orderService = GetIt.instance<OrderService>();
  // await orderService.loadOrders();

  runApp(const TruckPartsApp());
}

class TruckPartsApp extends StatelessWidget {
  const TruckPartsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(create: (context) => GetIt.instance<AuthBloc>()),
        BlocProvider<TextScannerBloc>(
          create: (context) => GetIt.instance<TextScannerBloc>(),
        ),
      ],
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<CartService>(
            create: (context) => GetIt.instance<CartService>(),
          ),
          ChangeNotifierProvider<OrderService>(
            create: (context) => GetIt.instance<OrderService>(),
          ),
          ChangeNotifierProvider<ThemeProvider>(
            create: (context) => ThemeProvider(),
          ),
          ChangeNotifierProvider<DataLoadingService>(
            create: (context) => GetIt.instance<DataLoadingService>(),
          ),
        ],
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return AppFocusManager(
              child: MaterialApp.router(
                title: 'Truck Parts - MOS',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.lightTheme,
                // App only functions in light mode - dark theme disabled
                themeMode: ThemeMode.light,
                routerConfig: AppRouter.router,
              ),
            );
          },
        ),
      ),
    );
  }
}
