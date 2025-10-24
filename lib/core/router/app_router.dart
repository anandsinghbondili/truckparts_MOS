import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// import '../../features/auth/presentation/pages/login_page.dart'; // COMMENTED OUT - ORIGINAL IMPLEMENTATION
import '../../features/auth/presentation/pages/emp_login_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/reset_password_page.dart';
import '../../features/auth/presentation/pages/otp_verification_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/search/presentation/pages/search_results_page.dart';
import '../../features/cart/presentation/pages/cart_page.dart';
import '../../features/cart/presentation/pages/otp_confirmation_page.dart';
import '../../features/cart/presentation/pages/order_confirmation_page.dart';
import '../../features/orders/presentation/pages/orders_page.dart';
import '../../features/orders/presentation/pages/order_details_page.dart';
import '../../features/orders/presentation/pages/track_order_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/settings_page.dart';
import '../../features/profile/presentation/pages/contact_us_page.dart';
import '../../features/items/presentation/pages/items_page.dart';
import '../../features/text_scanner/presentation/screens/text_scanner_home_screen.dart';
import '../../features/text_scanner/presentation/screens/text_result_screen.dart';
import '../widgets/splash_screen.dart';

class AppRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String otpVerification = '/otp-verification';
  static const String home = '/home';
  static const String searchResults = '/search-results';
  static const String cart = '/cart';
  static const String otpConfirmation = '/otp-confirmation';
  static const String orderConfirmation = '/order-confirmation';
  static const String orders = '/orders';
  static const String orderDetails = '/order-details';
  static const String trackOrder = '/track-order';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String contactUs = '/contact-us';
  static const String items = '/items';
  static const String textScanner = '/text-scanner';
  static const String textResult = '/text-result';

  static final GoRouter router = GoRouter(
    initialLocation: splash,
    debugLogDiagnostics: true,
    routes: [
      // Splash Screen
      GoRoute(
        path: splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth Routes - COMMENTED OUT ORIGINAL LOGIN PAGE
      // GoRoute(
      //   path: login,
      //   name: 'login',
      //   builder: (context, state) => const LoginPage(),
      // ),

      // NEW Employee Login Page
      GoRoute(
        path: login,
        name: 'login',
        builder: (context, state) => const EmpLoginPage(),
      ),
      GoRoute(
        path: forgotPassword,
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: resetPassword,
        name: 'reset-password',
        builder: (context, state) {
          final phoneNumber = state.extra as String?;
          return ResetPasswordPage(phoneNumber: phoneNumber ?? '');
        },
      ),
      GoRoute(
        path: otpVerification,
        name: 'otp-verification',
        builder: (context, state) {
          // Support both String (old format) and Map (new format)
          final extra = state.extra;
          return OtpVerificationPage(extra: extra ?? '');
        },
      ),

      // Main App Routes
      GoRoute(
        path: home,
        name: 'home',
        builder: (context, state) => const TextScannerHomeScreen(),
      ),
      GoRoute(
        path: cart,
        name: 'cart',
        builder: (context, state) => const CartPage(),
      ),
      GoRoute(
        path: orders,
        name: 'orders',
        builder: (context, state) => const OrdersPage(),
      ),
      GoRoute(
        path: profile,
        name: 'profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: searchResults,
        name: 'search-results',
        builder: (context, state) {
          final query = state.extra as Map<String, dynamic>?;
          return SearchResultsPage(searchQuery: query ?? {});
        },
      ),
      GoRoute(
        path: otpConfirmation,
        name: 'otp-confirmation',
        builder: (context, state) {
          final orderData = state.extra as Map<String, dynamic>?;
          return OtpConfirmationPage(orderData: orderData ?? {});
        },
      ),
      GoRoute(
        path: orderConfirmation,
        name: 'order-confirmation',
        builder: (context, state) {
          final orderInfo = state.extra as Map<String, dynamic>?;
          return OrderConfirmationPage(orderInfo: orderInfo ?? {});
        },
      ),
      GoRoute(
        path: orderDetails,
        name: 'order-details',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return OrderDetailsPage(
            rowId: extra?['rowId'] ?? '',
            orderId: extra?['orderId'] ?? '',
            orderStatus: extra?['orderStatus'], // ✅ Pass the order status
          );
        },
      ),
      GoRoute(
        path: trackOrder,
        name: 'track-order',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return TrackOrderPage(
            rowId: extra?['rowId'] ?? '',
            orderId: extra?['orderId'] ?? '',
          );
        },
      ),
      GoRoute(
        path: settings,
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: contactUs,
        name: 'contact-us',
        builder: (context, state) => const ContactUsPage(),
      ),
      GoRoute(
        path: items,
        name: 'items',
        builder: (context, state) => const ItemsPage(),
      ),
      GoRoute(
        path: textScanner,
        name: 'text-scanner',
        builder: (context, state) => const TextScannerHomeScreen(),
      ),
      GoRoute(
        path: textResult,
        name: 'text-result',
        builder: (context, state) {
          final recognizedText = state.extra as dynamic;
          return TextResultScreen(recognizedText: recognizedText);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outlined, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'The page you are looking for does not exist.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.normal),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go(home),
              icon: const Icon(Icons.home_outlined),
              label: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
}
