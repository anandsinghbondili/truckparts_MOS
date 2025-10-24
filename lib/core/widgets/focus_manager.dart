import 'package:flutter/material.dart';

/// A widget that manages focus across the app
/// Automatically unfocuses inputs when tapping outside
class AppFocusManager extends StatelessWidget {
  final Widget child;

  const AppFocusManager({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Unfocus any focused input when tapping outside
        FocusScope.of(context).unfocus();
      },
      // Don't consume the tap event, let it pass through to child widgets
      behavior: HitTestBehavior.translucent,
      child: child,
    );
  }
}

/// A mixin that provides focus management utilities
mixin FocusManagerMixin<T extends StatefulWidget> on State<T> {
  /// Unfocus all inputs in the current context
  void unfocusAll() {
    FocusScope.of(context).unfocus();
  }

  /// Unfocus a specific focus node
  void unfocusNode(FocusNode? focusNode) {
    focusNode?.unfocus();
  }

  /// Request focus on a specific focus node
  void requestFocus(FocusNode? focusNode) {
    focusNode?.requestFocus();
  }
}
