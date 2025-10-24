import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/utils/error_handler.dart';
import '../../data/services/order_details_service.dart';

class OrderDetailsPage extends StatefulWidget {
  final String rowId;
  final String orderId;
  final String? orderStatus; // ✅ Add order status parameter

  const OrderDetailsPage({
    super.key,
    required this.rowId,
    required this.orderId,
    this.orderStatus, // ✅ Optional order status
  });

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  final _orderDetailsService = GetIt.instance<OrderDetailsService>();

  bool _isLoading = true;
  String? _errorMessage;
  OrderDetailsResponse? _orderDetails;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('📋 Loading order details for RowId: ${widget.rowId}');

      final response = await _orderDetailsService.getOrderDetails(widget.rowId);
      final orderDetails = OrderDetailsResponse.fromJson(response);

      if (orderDetails.success) {
        setState(() {
          _orderDetails = orderDetails;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ErrorHandler.handleError(
            context: context,
            error: orderDetails.message ?? 'Failed to load order details',
            customTitle: 'Load Order Failed',
            actionButtonText: 'Retry',
            onActionPressed: _loadOrderDetails,
          );
        }
      }
    } catch (e) {
      print('❌ Error loading order details: $e');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ErrorHandler.handleApiError(
          context: context,
          error: e,
          onRetry: _loadOrderDetails,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRouter.orders),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long, size: 24),
            const SizedBox(width: 8),
            const Text('Order Details'),
          ],
        ),
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go(AppRouter.home),
          ),
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
          : _errorMessage != null
          ? _buildErrorState()
          : Column(
              children: [
                Expanded(child: _buildOrderDetails()),
                // Track Order Button docked to bottom
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 12,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(child: _buildTrackOrderButton()),
                ),
              ],
            ),
    );
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
                  'Loading order details...',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outlined, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Failed to load order details',
              style: const TextStyle(fontSize: 16, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadOrderDetails,
              icon: const Icon(Icons.refresh_outlined),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetails() {
    if (_orderDetails == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Section - Order ID and Date
          _buildOrderHeader(),

          const SizedBox(height: 16),

          // Items Section - Scrollable if needed
          Expanded(child: SingleChildScrollView(child: _buildItemsSection())),

          const SizedBox(height: 16),

          // Bill Details Section (fixed at bottom)
          _buildBillDetailsSection(),
        ],
      ),
    );
  }

  Widget _buildOrderHeader() {
    return Hero(
      tag: 'order_${widget.orderId}',
      child: Card(
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
                // Order Status - Prominent Display (only if status is available)
                if (widget.orderStatus != null &&
                    widget.orderStatus!.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Order Status: ${widget.orderStatus}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Order Number',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _orderDetails!.transNo ??
                          _orderDetails!.orderId ??
                          widget.orderId,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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
                      'Order Date',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _orderDetails!.orderDate ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemsSection() {
    final items = _orderDetails!.items ?? [];

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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Items (${items.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (_orderDetails!.totalAmount != null)
                    Text(
                      PriceFormatter.formatPriceWithCurrency(
                        _orderDetails!.totalAmount!,
                      ),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00A000), // Darker, more vibrant green
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              ...items.map((item) => _buildItemCard(item)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(OrderDetailItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8), // Reduced from 12
      padding: const EdgeInsets.all(10), // Reduced from 12
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10), // Reduced from 12
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.partName,
            style: const TextStyle(
              fontSize: 15, // Reduced from 16
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 3), // Reduced from 4
          if (item.brand.isNotEmpty || item.size.isNotEmpty)
            Text(
              '${item.brand}${item.brand.isNotEmpty && item.size.isNotEmpty ? ' • ' : ''}${item.size}',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ), // Reduced from 14
            ),
          const SizedBox(height: 6), // Reduced from 8
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Qty: ${item.quantity}',
                style: const TextStyle(
                  fontSize: 13, // Reduced from 14
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                PriceFormatter.formatPriceWithCurrency(item.totalPrice),
                style: const TextStyle(
                  fontSize: 15, // Reduced from 16
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00A000), // Darker, more vibrant green
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBillDetailsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {}, // Tappable for ripple effect
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10), // Match Cart: Reduced from 16
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bill Details',
                style: TextStyle(
                  fontSize: 15, // Match Cart: Reduced from 18
                  fontWeight: FontWeight.w600, // Match Cart: Changed from bold
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8), // Match Cart: Reduced from 16
              if (_orderDetails!.subTotal != null)
                _buildDetailRow(
                  'Sub Total',
                  PriceFormatter.formatPriceWithCurrency(
                    _orderDetails!.subTotal!,
                  ),
                  isAmount: true,
                ),
              if (_orderDetails!.taxAmount != null) ...[
                const SizedBox(height: 6), // Match Cart: Reduced from 8
                _buildDetailRow(
                  'Taxes', // Match Cart: Changed from 'Tax Amount'
                  PriceFormatter.formatPriceWithCurrency(
                    _orderDetails!.taxAmount!,
                  ),
                  isAmount: true,
                ),
              ],
              if (_orderDetails!.totalAmount != null) ...[
                const Divider(height: 16), // Match Cart: Reduced from 24
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Amount',
                      style: TextStyle(
                        fontSize: 15, // Match Cart: Reduced from 16
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      PriceFormatter.formatPriceWithCurrency(
                        _orderDetails!.totalAmount!,
                      ),
                      style: const TextStyle(
                        fontSize: 16, // Match Cart: Reduced from 18
                        fontWeight: FontWeight.bold,
                        color: Color(
                          0xFF00A000,
                        ), // Match Cart: Darker, more vibrant green
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isAmount = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13, // Match Cart: Reduced from 14
            color: AppTheme.textSecondary, // Match Cart: Use textSecondary
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13, // Match Cart: Reduced from 14
            color: Color(0xFF00A000), // Match Cart: Darker, more vibrant green
            fontWeight: FontWeight.w600, // Match Cart: Made bolder
          ),
        ),
      ],
    );
  }

  Widget _buildTrackOrderButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          context.push(
            AppRouter.trackOrder,
            extra: {'rowId': widget.rowId, 'orderId': widget.orderId},
          );
        },
        icon: const Icon(Icons.local_shipping, size: 22),
        label: const Text(
          'Track Order',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          elevation: 4,
          shadowColor: AppTheme.primaryColor.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
