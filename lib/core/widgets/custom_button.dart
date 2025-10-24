import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum ButtonType { primary, secondary, outlined, text }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final ButtonType type;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.type = ButtonType.primary,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color buttonColor;
    Color buttonTextColor;
    Color? spinnerColor;

    switch (type) {
      case ButtonType.primary:
        buttonColor = backgroundColor ?? AppTheme.primaryColor;
        buttonTextColor = textColor ?? Colors.white;
        spinnerColor = Colors.white;
        break;
      case ButtonType.secondary:
        buttonColor = backgroundColor ?? AppTheme.secondaryColor;
        buttonTextColor = textColor ?? Colors.white;
        spinnerColor = Colors.white;
        break;
      case ButtonType.outlined:
        buttonColor = backgroundColor ?? Colors.transparent;
        buttonTextColor = textColor ?? AppTheme.primaryColor;
        spinnerColor = AppTheme.primaryColor;
        break;
      case ButtonType.text:
        buttonColor = backgroundColor ?? Colors.transparent;
        buttonTextColor = textColor ?? AppTheme.primaryColor;
        spinnerColor = AppTheme.primaryColor;
        break;
    }

    Widget buttonChild = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              color: spinnerColor,
              strokeWidth: 2.5,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: buttonTextColor),
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: buttonTextColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          );

    if (type == ButtonType.text) {
      return SizedBox(
        width: width,
        height: height ?? 50,
        child: TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            padding:
                padding ??
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            backgroundColor: buttonColor,
            shape: RoundedRectangleBorder(
              borderRadius: borderRadius ?? BorderRadius.circular(10),
            ),
          ),
          child: buttonChild,
        ),
      );
    }

    if (type == ButtonType.outlined) {
      return SizedBox(
        width: width,
        height: height ?? 52,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: buttonTextColor,
            backgroundColor: buttonColor,
            side: BorderSide(color: AppTheme.primaryColor, width: 2),
            padding:
                padding ??
                const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: borderRadius ?? BorderRadius.circular(10),
            ),
          ),
          child: buttonChild,
        ),
      );
    }

    // Primary and Secondary buttons use ElevatedButton
    return SizedBox(
      width: width,
      height: height ?? 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: buttonTextColor,
          elevation: 2,
          shadowColor: AppTheme.primaryColor.withOpacity(0.3),
          disabledBackgroundColor: AppTheme.borderColor,
          disabledForegroundColor: AppTheme.textTertiary,
          padding:
              padding ??
              const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(10),
          ),
        ),
        child: buttonChild,
      ),
    );
  }
}
