import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/sms_autofill_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/navigation_utils.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../data/services/password_reset_service.dart';

class OtpVerificationPage extends StatefulWidget {
  final dynamic extra; // Can be String or Map

  const OtpVerificationPage({super.key, required this.extra});

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage>
    with OtpAutoFillMixin {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _passwordResetService = GetIt.instance<PasswordResetService>();
  String? _phoneNumber;
  String? _receivedOtp;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
    // Start listening for SMS OTP
    listenForOtp();
  }

  void _initializeData() {
    // Handle both String and Map formats for backward compatibility
    if (widget.extra is String) {
      _phoneNumber = widget.extra as String;
    } else if (widget.extra is Map) {
      final data = widget.extra as Map<String, dynamic>;
      _phoneNumber = data['phoneNumber'] as String?;
      _receivedOtp = data['otp'] as String?;

      // Auto-fill OTP if provided (for testing/development)
      if (_receivedOtp != null && _receivedOtp!.isNotEmpty) {
        _otpController.text = _receivedOtp!;
        print('📱 Auto-filled OTP from API response: $_receivedOtp');
      }
    }
  }

  @override
  void onOtpReceived(String otp) {
    setState(() {
      _otpController.text = otp;
    });
    print('📱 Auto-filled OTP from SMS: $otp');

    // Optionally auto-verify
    // _verifyOTP();
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOTP() async {
    if (_formKey.currentState!.validate()) {
      if (_phoneNumber == null || _phoneNumber!.isEmpty) {
        SnackBarUtils.showError(
          context,
          message: 'Phone number not available. Please go back and try again.',
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final otp = _otpController.text.trim();

        print('🔐 Verifying OTP: $otp for mobile: $_phoneNumber');

        // Call the OTP verification API
        final response = await _passwordResetService.verifyOtp(
          mobileNumber: _phoneNumber!,
          otp: otp,
        );

        print('✅ OTP Verification Response: $response');

        // Parse response
        final verifyResponse = PasswordResetResponse.fromJson(response);

        if (verifyResponse.success) {
          if (!mounted) return;

          SnackBarUtils.showSuccess(
            context,
            message: verifyResponse.message ?? 'OTP verified successfully!',
          );

          // Navigate to reset password page
          context.go(AppRouter.resetPassword, extra: _phoneNumber);
        } else {
          if (!mounted) return;

          SnackBarUtils.showError(
            context,
            message: verifyResponse.message ?? 'Invalid OTP. Please try again.',
          );
        }
      } on PasswordResetException catch (e) {
        print('❌ OTP Verification Error: ${e.message}');

        if (!mounted) return;

        SnackBarUtils.showError(context, message: e.message);
      } catch (e) {
        print('❌ Unexpected Error: $e');

        if (!mounted) return;

        SnackBarUtils.showError(
          context,
          message: 'Failed to verify OTP. Please try again.',
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

  Future<void> _resendOTP() async {
    if (_phoneNumber == null || _phoneNumber!.isEmpty) {
      SnackBarUtils.showError(
        context,
        message: 'Phone number not available. Please go back and try again.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _passwordResetService.requestOtp(_phoneNumber!);
      final resetResponse = PasswordResetResponse.fromJson(response);

      if (resetResponse.success) {
        if (!mounted) return;

        SnackBarUtils.showSuccess(
          context,
          message: resetResponse.message ?? 'OTP resent successfully!',
        );

        // Update received OTP if provided
        if (resetResponse.otp != null) {
          setState(() {
            _receivedOtp = resetResponse.otp;
            _otpController.text = resetResponse.otp!;
          });
        }
      } else {
        if (!mounted) return;

        SnackBarUtils.showError(
          context,
          message: resetResponse.message ?? 'Failed to resend OTP',
        );
      }
    } catch (e) {
      print('❌ Resend OTP Error: $e');

      if (!mounted) return;

      SnackBarUtils.showError(
        context,
        message: 'Failed to resend OTP. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mobile-only sizing
    final iconSize = 80.0;
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
          onPressed: () => NavigationUtils.safePop(
            context,
            fallbackRoute: AppRouter.forgotPassword,
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_user, size: 24),
            const SizedBox(width: 8),
            const Text('OTP Verification'),
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
      body: SafeArea(
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
              Column(
                children: [
                  Container(
                    width: iconSize,
                    height: iconSize,
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
                      Icons.sms_outlined,
                      size: iconSize * 0.5,
                      color: AppTheme.primaryColor,
                    ),
                  ),

                  SizedBox(height: spacingAfterIcon),

                  Text(
                    'Verify OTP',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: spacingAfterTitle),

                  Text(
                    'Enter the 4-digit OTP sent to\n${_phoneNumber ?? "your mobile"}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),

                  SizedBox(height: spacingAfterTitle),

                  if (_receivedOtp != null && _receivedOtp!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryColor.withValues(alpha: 0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        'OTP auto-filled from SMS',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14.0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),

              SizedBox(height: spacingBeforeForm),

              // OTP Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    CustomTextField(
                      controller: _otpController,
                      labelText: 'OTP',
                      hintText: 'Enter 4-digit OTP',
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      prefixIcon: Icons.lock_outline,
                      suffixIcon: _otpController.text.isNotEmpty
                          ? Icon(
                              Icons.check_circle_outlined,
                              color: Colors.green,
                            )
                          : null,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter OTP';
                        }
                        if (value.length != 4) {
                          return 'OTP must be 4 digits';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 32.0),

                    // Verify Button
                    CustomButton(
                      text: 'Verify OTP',
                      icon: Icons.verified_user_outlined,
                      width: double.infinity,
                      onPressed: _isLoading ? null : _verifyOTP,
                      isLoading: _isLoading,
                    ),
                  ],
                ),
              ),

              SizedBox(height: spacingAfterForm),

              // Resend OTP
              Center(
                child: TextButton(
                  onPressed: _isLoading ? null : _resendOTP,
                  child: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primaryColor,
                          ),
                        )
                      : Text(
                          'Resend OTP',
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
    );
  }
}
