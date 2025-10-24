import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/app_router.dart';

class NavigationUtils {
  /// Safely navigates back to the previous page, with fallback to a default route
  /// if there's no previous page in the navigation stack
  static void safePop(
    BuildContext context, {
    String fallbackRoute = AppRouter.home,
  }) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(fallbackRoute);
    }
  }

  /// Navigates back to the previous page, with fallback to login if not authenticated
  static void safePopWithAuthFallback(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRouter.login);
    }
  }
}
