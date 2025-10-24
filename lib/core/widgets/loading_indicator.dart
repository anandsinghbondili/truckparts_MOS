import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Loading indicator widgets for consistent loading states
class LoadingIndicator extends StatelessWidget {
  final String? message;
  final bool isLinear;

  const LoadingIndicator({super.key, this.message, this.isLinear = false});

  const LoadingIndicator.linear({super.key, this.message}) : isLinear = true;

  const LoadingIndicator.circular({super.key, this.message}) : isLinear = false;

  @override
  Widget build(BuildContext context) {
    if (isLinear) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (message != null) ...[
            Text(
              message!,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
          ],
          const LinearProgressIndicator(
            backgroundColor: AppTheme.borderColor,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
        ],
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            strokeWidth: 3,
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
