import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool readOnly;
  final bool enabled;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final void Function()? onTap;
  final List<TextInputFormatter>? inputFormatters;
  final EdgeInsetsGeometry? contentPadding;
  final Color? fillColor;
  final BorderRadius? borderRadius;

  const CustomTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.readOnly = false,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.inputFormatters,
    this.contentPadding,
    this.fillColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Focus(
      child: Builder(
        builder: (context) {
          final hasFocus = Focus.of(context).hasFocus;
          return Container(
            decoration: BoxDecoration(
              borderRadius: borderRadius ?? BorderRadius.circular(12),
              boxShadow: hasFocus
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              obscureText: obscureText,
              readOnly: readOnly,
              enabled: enabled,
              maxLines: maxLines,
              minLines: minLines,
              maxLength: maxLength,
              validator: validator,
              onChanged: onChanged,
              onFieldSubmitted: onSubmitted,
              onTap: onTap,
              inputFormatters: inputFormatters,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: enabled ? AppTheme.textPrimary : AppTheme.textTertiary,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                labelText: labelText,
                hintText: hintText,
                helperText: helperText,
                errorText: errorText,
                prefixIcon: prefixIcon != null
                    ? Icon(
                        prefixIcon,
                        color: hasFocus
                            ? AppTheme.primaryColor
                            : (enabled
                                  ? AppTheme.textSecondary
                                  : AppTheme.textTertiary),
                        size: 22,
                      )
                    : null,
                suffixIcon: suffixIcon,
                filled: true,
                fillColor:
                    fillColor ??
                    (enabled ? Colors.white : AppTheme.dividerColor),
                contentPadding:
                    contentPadding ??
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                border: OutlineInputBorder(
                  borderRadius: borderRadius ?? BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppTheme.borderColor,
                    width: 1.5,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: borderRadius ?? BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppTheme.borderColor,
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: borderRadius ?? BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppTheme.primaryColor,
                    width: 2.5,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: borderRadius ?? BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppTheme.errorColor,
                    width: 1.5,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: borderRadius ?? BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppTheme.errorColor,
                    width: 2.5,
                  ),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: borderRadius ?? BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppTheme.borderColor,
                    width: 1.5,
                  ),
                ),
                labelStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: hasFocus
                      ? AppTheme.primaryColor
                      : (enabled
                            ? AppTheme.textSecondary
                            : AppTheme.textTertiary),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                floatingLabelStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: hasFocus
                      ? AppTheme.primaryColor
                      : AppTheme.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textTertiary,
                  fontSize: 15,
                ),
                helperStyle: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
                errorStyle: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.errorColor,
                  fontSize: 13,
                ),
                counterStyle: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textTertiary,
                  fontSize: 12,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class PhoneNumberField extends StatelessWidget {
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final String? errorText;

  const PhoneNumberField({
    super.key,
    this.controller,
    this.validator,
    this.onChanged,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      labelText: 'Phone Number',
      hintText: 'Enter your phone number',
      keyboardType: TextInputType.phone,
      prefixIcon: Icons.phone,
      maxLength: 10,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
      validator:
          validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your phone number';
            }
            if (value.length != 10) {
              return 'Please enter a valid 10-digit phone number';
            }
            if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value)) {
              return 'Please enter a valid Indian mobile number';
            }
            return null;
          },
      onChanged: onChanged,
      errorText: errorText,
    );
  }
}

class OtpField extends StatelessWidget {
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  const OtpField({super.key, this.controller, this.validator, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      labelText: 'OTP',
      hintText: 'Enter 6-digit OTP',
      keyboardType: TextInputType.number,
      prefixIcon: Icons.security,
      maxLength: 6,
      textInputAction: TextInputAction.done,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(6),
      ],
      validator:
          validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter OTP';
            }
            if (value.length != 6) {
              return 'Please enter a valid 6-digit OTP';
            }
            return null;
          },
      onChanged: onChanged,
    );
  }
}
