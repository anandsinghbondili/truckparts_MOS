import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../cart/data/services/cart_service.dart';
import '../../../orders/data/services/order_service.dart';

class OrderConfirmationPage extends StatefulWidget {
  final Map<String, dynamic> orderInfo;

  const OrderConfirmationPage({super.key, required this.orderInfo});

  @override
  State<OrderConfirmationPage> createState() => _OrderConfirmationPageState();
}

class _OrderConfirmationPageState extends State<OrderConfirmationPage> {
  @override
  void initState() {
    super.initState();
    // Clear the cart and save the order when order is confirmed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cartService = Provider.of<CartService>(context, listen: false);
      final orderService = Provider.of<OrderService>(context, listen: false);

      // Save the order to order history
      _saveOrder(orderService);

      // Clear the cart
      cartService.clearCart();
    });
  }

  void _saveOrder(OrderService orderService) {
    try {
      final orderId = widget.orderInfo['orderId'] as String;
      final totalAmount =
          (widget.orderInfo['totalAmount'] as num?)?.toDouble() ?? 0.0;
      final itemCount = (widget.orderInfo['itemCount'] as num?)?.toInt() ?? 0;
      final items = widget.orderInfo['items'] as List<dynamic>? ?? [];

      final orderItems = items
          .map(
            (item) => OrderItem(
              partId: item['partId'] ?? '',
              partName: item['partName'] ?? '',
              brand: item['brand'] ?? '',
              size: item['size'] ?? '',
              quantity: item['quantity'] ?? 1,
              unitPrice: (item['unitPrice'] as num?)?.toDouble() ?? 0.0,
              totalPrice: (item['totalPrice'] as num?)?.toDouble() ?? 0.0,
            ),
          )
          .toList();

      final order = Order(
        id: orderId,
        date: DateTime.now(),
        status: 'Confirmed',
        totalAmount: totalAmount,
        itemCount: itemCount,
        items: orderItems,
      );

      orderService.addOrder(order);
    } catch (e) {
      debugPrint('Error saving order: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderId = widget.orderInfo['orderId'] as String;
    final date = widget.orderInfo['date'] as DateTime;
    final totalAmount = widget.orderInfo['totalAmount'] as double;
    final itemCount = widget.orderInfo['itemCount'] as int;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // No back button on confirmation page
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 24),
            const SizedBox(width: 8),
            const Text('Order Confirmation'),
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),

              // Success Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.successColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 50),
              ),

              const SizedBox(height: 32),

              // Success Message
              Text(
                'Order Placed Successfully!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              Text(
                'Thank you for your order. We will process it shortly.',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Order Details Card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () {}, // Tappable for ripple effect
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Order Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Order ID
                        _buildDetailRow(
                          'Order ID',
                          orderId,
                          Icons.receipt_long,
                        ),

                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(height: 1),
                        ),

                        // Date & Time
                        _buildDetailRow(
                          'Date & Time',
                          DateFormat('dd MMM yyyy, hh:mm a').format(date),
                          Icons.calendar_today,
                        ),

                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(height: 1),
                        ),

                        // Items Count
                        _buildDetailRow(
                          'Items',
                          '$itemCount items',
                          Icons.shopping_bag,
                        ),

                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(height: 1),
                        ),

                        // Total Amount
                        _buildDetailRow(
                          'Total Amount',
                          PriceFormatter.formatPriceWithCurrency(totalAmount),
                          Icons.payments,
                          isAmount: true,
                        ),

                        const SizedBox(height: 24),

                        // Divider
                        Container(height: 1, color: AppTheme.borderColor),

                        const SizedBox(height: 20),

                        // Order Status
                        Row(
                          children: [
                            Icon(
                              Icons.local_shipping,
                              color: AppTheme.primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Status: ',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const Text(
                              'Confirmed',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.successColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // Action Buttons
              Column(
                children: [
                  // Continue Shopping Button - Primary Action
                  CustomButton(
                    text: 'Continue Shopping',
                    icon: Icons.shopping_bag_outlined,
                    onPressed: () => context.go(AppRouter.home),
                    type: ButtonType.primary,
                    width: double.infinity,
                  ),

                  const SizedBox(height: 12),

                  // View Orders Button - Secondary Action
                  CustomButton(
                    text: 'View My Orders',
                    icon: Icons.receipt_long_outlined,
                    onPressed: () => context.go(AppRouter.orders),
                    type: ButtonType.outlined,
                    width: double.infinity,
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon, {
    bool isAmount = false,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.textSecondary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isAmount
                ? const Color(0xFF00A000)
                : AppTheme.textPrimary, // Darker green for amounts
          ),
        ),
      ],
    );
  }
}
