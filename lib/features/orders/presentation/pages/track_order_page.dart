import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/router/app_router.dart';
import '../../data/services/order_details_service.dart';

class TrackOrderPage extends StatefulWidget {
  final String rowId;
  final String orderId;

  const TrackOrderPage({super.key, required this.rowId, required this.orderId});

  @override
  State<TrackOrderPage> createState() => _TrackOrderPageState();
}

class _TrackOrderPageState extends State<TrackOrderPage> {
  final _orderDetailsService = GetIt.instance<OrderDetailsService>();

  bool _isLoading = true;
  String? _errorMessage;
  OrderTrackingResponse? _trackingDetails;

  @override
  void initState() {
    super.initState();
    _loadTrackingDetails();
  }

  Future<void> _loadTrackingDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('🚚 Loading tracking details for RowId: ${widget.rowId}');

      final response = await _orderDetailsService.getOrderTracking(
        widget.rowId,
      );
      final trackingDetails = OrderTrackingResponse.fromJson(response);

      if (trackingDetails.success) {
        setState(() {
          _trackingDetails = trackingDetails;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              trackingDetails.message ?? 'Failed to load tracking details';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading tracking details: $e');
      setState(() {
        _errorMessage = 'Failed to load tracking details. Please try again.';
        _isLoading = false;
      });
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
          onPressed: () => context.pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_shipping, size: 24),
            const SizedBox(width: 8),
            const Text('Track Order'),
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
          : _buildTrackingDetails(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.primaryColor),
          const SizedBox(height: 16),
          Text(
            'Loading tracking details...',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
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
              _errorMessage ?? 'Failed to load tracking details',
              style: const TextStyle(fontSize: 16, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadTrackingDetails,
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

  Widget _buildTrackingDetails() {
    if (_trackingDetails == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Info Header
          _buildOrderInfoHeader(),

          const SizedBox(height: 24),

          // Tracking Timeline
          _buildTrackingTimeline(),
        ],
      ),
    );
  }

  Widget _buildOrderInfoHeader() {
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
                    'Order Number',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    _trackingDetails!.sono ??
                        _trackingDetails!.orderNumber ??
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
                    _trackingDetails!.orderDate ?? 'N/A',
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
    );
  }

  Widget _buildTrackingTimeline() {
    final trackingSteps = _getTrackingSteps();

    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.timeline,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Order Tracking Timeline',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildConnectedTimeline(trackingSteps),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectedTimeline(List<TrackingStep> steps) {
    return Column(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isLast = index == steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline Column
            Column(
              children: [
                // Step Circle
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: step.isCompleted
                        ? AppTheme.primaryColor
                        : Colors.grey[200],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: step.isCompleted
                          ? AppTheme.primaryColor
                          : Colors.grey[300]!,
                      width: 1.5,
                    ),
                    boxShadow: step.isCompleted
                        ? [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    step.icon,
                    color: step.isCompleted ? Colors.white : Colors.grey[500],
                    size: 16,
                  ),
                ),
                // Connecting Line
                if (!isLast)
                  Container(
                    width: 1.5,
                    height: 40,
                    color: step.isCompleted
                        ? AppTheme.primaryColor
                        : Colors.grey[300],
                    margin: const EdgeInsets.symmetric(vertical: 2),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // Step Content
            Expanded(
              child: Container(
                margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      step.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: step.isCompleted
                            ? AppTheme.textPrimary
                            : Colors.grey[600],
                        letterSpacing: 0.2,
                      ),
                    ),
                    if (step.date.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        step.date,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  List<TrackingStep> _getTrackingSteps() {
    final tracking = _trackingDetails!;

    return [
      TrackingStep(
        title: 'Order Placed',
        description: '',
        number: tracking.orderNumber ?? '',
        date: tracking.orderDate ?? '',
        isCompleted: tracking.orderNumber?.isNotEmpty == true,
        icon: Icons.shopping_cart_outlined,
      ),
      TrackingStep(
        title: 'Picked',
        description: '',
        number: tracking.pickNumber ?? '',
        date: tracking.pickDate ?? '',
        isCompleted: tracking.pickNumber?.isNotEmpty == true,
        icon: Icons.inventory_outlined,
      ),
      TrackingStep(
        title: 'Packed',
        description: '',
        number: tracking.packNumber ?? '',
        date: tracking.packDate ?? '',
        isCompleted: tracking.packNumber?.isNotEmpty == true,
        icon: Icons.inventory_2_outlined,
      ),
      TrackingStep(
        title: 'Invoiced',
        description: '',
        number: tracking.invoiceNumber ?? '',
        date: tracking.invoiceDate ?? '',
        isCompleted: tracking.invoiceNumber?.isNotEmpty == true,
        icon: Icons.receipt_outlined,
      ),
      TrackingStep(
        title: 'Shipped',
        description: '',
        number: tracking.shipNumber ?? '',
        date: tracking.shipDate ?? '',
        isCompleted: tracking.shipNumber?.isNotEmpty == true,
        icon: Icons.local_shipping_outlined,
      ),
      TrackingStep(
        title: 'Delivered',
        description: '',
        number: tracking.podNumber ?? '',
        date: tracking.podDate ?? '',
        isCompleted: tracking.podNumber?.isNotEmpty == true,
        icon: Icons.check_circle_outlined,
      ),
    ];
  }
}

class TrackingStep {
  final String title;
  final String description;
  final String number;
  final String date;
  final bool isCompleted;
  final IconData icon;

  TrackingStep({
    required this.title,
    required this.description,
    required this.number,
    required this.date,
    required this.isCompleted,
    required this.icon,
  });
}
