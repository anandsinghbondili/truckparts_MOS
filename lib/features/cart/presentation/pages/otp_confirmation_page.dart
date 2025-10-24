import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../data/services/order_placement_service.dart';
import '../../data/services/cart_service.dart';

class OtpConfirmationPage extends StatefulWidget {
  final Map<String, dynamic> orderData;

  const OtpConfirmationPage({super.key, required this.orderData});

  @override
  State<OtpConfirmationPage> createState() => _OtpConfirmationPageState();
}

class _OtpConfirmationPageState extends State<OtpConfirmationPage> {
  final List<TextEditingController> _otpControllers = List.generate(
    4,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());
  bool _isLoading = false;
  bool _isResendEnabled = true;
  int _resendCountdown = 30;

  // Services
  final _orderPlacementService = GetIt.instance<OrderPlacementService>();
  final _cartService = GetIt.instance<CartService>();

  @override
  void initState() {
    super.initState();
    try {
      _startResendCountdown();
      _generateAndSendOTP();
    } catch (e) {
      debugPrint('Error in OTP confirmation initState: $e');
    }
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _startResendCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
        _startResendCountdown();
      } else if (mounted) {
        setState(() {
          _isResendEnabled = true;
        });
      }
    });
  }

  void _generateAndSendOTP() async {
    try {
      print('📱 Sending Purchase OTP...');

      final response = await _orderPlacementService.sendPurchaseOTP();
      final otpResponse = OtpResponse.fromJson(response);

      if (otpResponse.success) {
        print('✅ OTP sent successfully: ${otpResponse.message}');
        if (mounted) {
          SnackBarUtils.showSuccess(
            context,
            message: 'OTP sent to your mobile number',
          );
        }
      } else {
        print('❌ Failed to send OTP: ${otpResponse.message}');
        if (mounted) {
          SnackBarUtils.showError(
            context,
            message: otpResponse.message ?? 'Failed to send OTP',
          );
        }
      }
    } catch (e) {
      print('❌ Error sending OTP: $e');
      if (mounted) {
        SnackBarUtils.showError(
          context,
          message: 'Failed to send OTP. Please try again.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      final grandTotal =
          (widget.orderData['grandTotal'] as num?)?.toDouble() ?? 0.0;
      final itemCount = (widget.orderData['itemCount'] as num?)?.toInt() ?? 0;

      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRouter.cart);
              }
            },
          ),
          title: const Text('OTP Verification'),
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
        body: _isLoading
            ? _buildLoadingState()
            : _buildOTPVerificationContent(grandTotal, itemCount),
      );
    } catch (e) {
      debugPrint('Error in OTP confirmation build: $e');
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          title: const Text('OTP Verification'),
        ),
        body: const Center(child: Text('Error loading OTP verification page')),
      );
    }
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 300),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              );
            },
          ),
          const SizedBox(height: 16),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 300),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Text(
                  'Processing...',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOTPVerificationContent(double grandTotal, int itemCount) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Summary Card
          _buildOrderSummaryCard(grandTotal, itemCount),

          const SizedBox(height: 32),

          // OTP Instructions
          _buildOTPInstructions(),

          const SizedBox(height: 24),

          // OTP Input Fields
          _buildOTPInputFields(),

          const SizedBox(height: 24),

          // Verify Button
          _buildVerifyButton(),

          const SizedBox(height: 24),

          // Resend Section
          _buildResendSection(),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryCard(double grandTotal, int itemCount) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {}, // Tappable for ripple effect
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.shopping_cart_checkout_outlined,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Order Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Items: $itemCount',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    PriceFormatter.formatPriceWithCurrency(grandTotal),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00A000), // Darker, more vibrant green
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOTPInstructions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter OTP',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'We have sent a 4-digit OTP to your registered mobile number. Please enter it below to confirm your order.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.grey[600],
            fontWeight: FontWeight.normal,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildOTPInputFields() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(4, (index) {
        return Focus(
          child: Builder(
            builder: (context) {
              final hasFocus = Focus.of(context).hasFocus;
              return Container(
                width: 65,
                height: 65,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: hasFocus
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: TextField(
                  controller: _otpControllers[index],
                  focusNode: _focusNodes[index],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppTheme.borderColor,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryColor,
                        width: 2.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppTheme.borderColor,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      if (index < 3) {
                        _focusNodes[index + 1].requestFocus();
                      } else {
                        _focusNodes[index].unfocus();
                        _checkOTPCompletion();
                      }
                    } else if (value.isEmpty && index > 0) {
                      _focusNodes[index - 1].requestFocus();
                    }
                  },
                ),
              );
            },
          ),
        );
      }),
    );
  }

  Widget _buildVerifyButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _verifyOTP,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Verify & Place Order',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  Widget _buildResendSection() {
    return Center(
      child: Column(
        children: [
          Text(
            "Didn't receive the OTP?",
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _isResendEnabled ? _resendOTP : null,
            child: Text(
              _isResendEnabled
                  ? 'Resend OTP'
                  : 'Resend in ${_resendCountdown}s',
              style: TextStyle(
                color: _isResendEnabled
                    ? AppTheme.primaryColor
                    : AppTheme.textTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _checkOTPCompletion() {
    final otp = _otpControllers.map((controller) => controller.text).join();
    if (otp.length == 4) {
      // Auto-verify if OTP is complete
      _verifyOTP();
    }
  }

  void _verifyOTP() async {
    final otp = _otpControllers.map((controller) => controller.text).join();

    if (otp.length != 4) {
      if (mounted) {
        SnackBarUtils.showError(context, message: 'Please enter complete OTP');
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('🔐 Verifying OTP: $otp');

      // Step 1: Verify OTP
      final otpResponse = await _orderPlacementService.verifyPlaceOrderOTP(otp);
      final otpResult = OtpResponse.fromJson(otpResponse);

      if (otpResult.success) {
        print('✅ OTP verified successfully');

        // Step 2: Place Order
        print('🛒 Placing order...');
        final orderResponse = await _orderPlacementService.placeOrder();
        final orderResult = OrderPlacementResponse.fromJson(orderResponse);

        if (orderResult.success) {
          print('✅ Order placed successfully: ${orderResult.message}');
          if (mounted) {
            _showOrderConfirmation(orderResult);
          }
        } else {
          print('❌ Order placement failed: ${orderResult.message}');
          if (mounted) {
            SnackBarUtils.showError(
              context,
              message: orderResult.message ?? 'Failed to place order',
            );
          }
        }
      } else {
        print('❌ OTP verification failed: ${otpResult.message}');
        if (mounted) {
          SnackBarUtils.showError(
            context,
            message: otpResult.message ?? 'Invalid OTP. Please try again.',
          );

          // Clear OTP fields
          for (var controller in _otpControllers) {
            controller.clear();
          }
          _focusNodes[0].requestFocus();
        }
      }
    } catch (e) {
      print('❌ Error in OTP verification/order placement: $e');
      if (mounted) {
        SnackBarUtils.showError(
          context,
          message: 'Failed to verify OTP. Please try again.',
        );

        // Clear OTP fields
        for (var controller in _otpControllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _resendOTP() {
    setState(() {
      _isResendEnabled = false;
      _resendCountdown = 30;
    });

    _startResendCountdown();
    _generateAndSendOTP();

    // Clear existing OTP
    for (var controller in _otpControllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  void _showOrderConfirmation(OrderPlacementResponse orderResult) {
    final orderInfo = {
      'orderId':
          orderResult.orderNumber ??
          orderResult.orderId ??
          'TP${DateTime.now().millisecondsSinceEpoch}',
      'date': DateTime.now(),
      'totalAmount': widget.orderData['grandTotal'],
      'itemCount': widget.orderData['itemCount'],
      'items': widget.orderData['items'],
      'message': orderResult.message,
      'success': orderResult.success,
    };

    // Clear the cart after successful order
    _clearCart();

    context.go(AppRouter.orderConfirmation, extra: orderInfo);
  }

  void _clearCart() {
    try {
      // Clear the cart using CartService
      _cartService.clearCart();
      print('✅ Cart cleared after successful order');
    } catch (e) {
      debugPrint('Error clearing cart: $e');
    }
  }
}
