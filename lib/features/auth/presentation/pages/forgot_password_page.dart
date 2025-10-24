import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/navigation_utils.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../data/services/password_reset_service.dart';
import '../bloc/auth_bloc.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../bloc/auth_state.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordResetService = GetIt.instance<PasswordResetService>();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Mobile-only sizing
    final iconContainerSize = 80.0;
    final iconSize = 40.0;
    final titleFontSize = 20.0;
    final subtitleFontSize = 14.0;
    final spacingAfterIcon = 24.0;
    final spacingAfterTitle = 8.0;
    final spacingBeforeForm = 48.0;
    final spacingAfterForm = 32.0;
    final horizontalPadding = 24.0;
    final verticalPadding = 24.0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            NavigationUtils.safePop(context, fallbackRoute: AppRouter.login);
          },
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_reset, size: 24),
            const SizedBox(width: 8),
            const Text('Forgot Password'),
          ],
        ),
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        actions: [
          // Company Logo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
            child: Image.asset(
              'assets/logos/shortform.png',
              fit: BoxFit.contain,
              height: 24,
            ),
          ),
        ],
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is ForgotPasswordSuccess) {
            context.go(AppRouter.otpVerification, extra: state.phoneNumber);
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40.0),

                // Header
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: iconContainerSize,
                        height: iconContainerSize,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.lock_reset_outlined,
                          size: iconSize,
                          color: AppTheme.primaryColor,
                        ),
                      ),

                      SizedBox(height: spacingAfterIcon),

                      Text(
                        'Forgot Password',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                              letterSpacing: 0.5,
                            ),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: spacingAfterTitle),

                      Text(
                        'Enter your phone number to receive OTP for password reset',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: spacingBeforeForm),

                // Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      CustomTextField(
                        controller: _phoneController,
                        labelText: 'Phone Number',
                        hintText: 'Enter your phone number',
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icons.phone_outlined,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your phone number';
                          }
                          if (value.length != 10) {
                            return 'Please enter a valid 10-digit phone number';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 32.0),

                      // Send OTP Button
                      CustomButton(
                        text: 'Send OTP',
                        width: double.infinity,
                        onPressed: _isLoading ? null : _handleForgotPassword,
                        isLoading: _isLoading,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: spacingAfterForm),

                // Back to Login
                Center(
                  child: TextButton(
                    onPressed: () => context.go(AppRouter.login),
                    child: Text(
                      'Back to Login',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleForgotPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final mobileNumber = _phoneController.text.trim();

        print('📱 Requesting OTP for mobile: $mobileNumber');

        // Call the password reset API using app context
        final response = await _passwordResetService.requestOtp(mobileNumber);

        print('✅ OTP Request Response: $response');

        // Parse response
        final resetResponse = PasswordResetResponse.fromJson(response);

        if (resetResponse.success) {
          // Show success message
          if (!mounted) return;

          SnackBarUtils.showSuccess(
            context,
            message:
                resetResponse.message ??
                'OTP sent successfully! Check your mobile device.',
          );

          // Navigate to OTP verification page with the phone number
          context.go(
            AppRouter.otpVerification,
            extra: {
              'phoneNumber': mobileNumber,
              'otp': resetResponse.otp, // May be null in production
            },
          );
        } else {
          if (!mounted) return;

          SnackBarUtils.showError(
            context,
            message: resetResponse.message ?? 'Failed to send OTP',
          );
        }
      } on PasswordResetException catch (e) {
        print('❌ Password Reset Error: ${e.message}');

        if (!mounted) return;

        SnackBarUtils.showError(context, message: e.message);
      } catch (e) {
        print('❌ Unexpected Error: $e');

        if (!mounted) return;

        SnackBarUtils.showError(
          context,
          message: 'An unexpected error occurred. Please try again.',
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
}
