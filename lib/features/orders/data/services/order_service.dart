import 'package:flutter/foundation.dart';
import 'sales_order_api_service.dart';

class OrderItem {
  final String partId;
  final String partName;
  final String brand;
  final String size;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  OrderItem({
    required this.partId,
    required this.partName,
    required this.brand,
    required this.size,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  Map<String, dynamic> toJson() {
    return {
      'partId': partId,
      'partName': partName,
      'brand': brand,
      'size': size,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
    };
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      partId: json['partId'] ?? '',
      partName: json['partName'] ?? '',
      brand: json['brand'] ?? '',
      size: json['size'] ?? '',
      quantity: json['quantity'] ?? 1,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class Order {
  final String id;
  final String? orderNo; // Order number for Order History
  final String? transNo; // Transaction number from API
  final DateTime date;
  final String status;
  final double totalAmount;
  final int itemCount;
  final List<OrderItem> items;

  Order({
    required this.id,
    this.orderNo,
    this.transNo,
    required this.date,
    required this.status,
    required this.totalAmount,
    required this.itemCount,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderNo': orderNo,
      'transNo': transNo,
      'date': date.toIso8601String(),
      'status': status,
      'totalAmount': totalAmount,
      'itemCount': itemCount,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? '',
      orderNo: json['orderNo'],
      transNo: json['transNo'],
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      status: json['status'] ?? 'Pending',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      itemCount: json['itemCount'] ?? 0,
      items:
          (json['items'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class OrderService extends ChangeNotifier {
  List<Order> _orders = [];
  bool _isLoading = false;
  String? _errorMessage;
  final SalesOrderApiService? _salesOrderApiService;

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  OrderService({SalesOrderApiService? salesOrderApiService})
    : _salesOrderApiService = salesOrderApiService;

  Future<void> loadOrders() async {
    // Always fetch from server
    if (_salesOrderApiService != null) {
      await _loadOrdersFromServer();
    } else {
      // No API service available - show error
      setState(() {
        _errorMessage = 'Order service not available';
        _orders = [];
      });
    }
  }

  Future<void> _loadOrdersFromServer() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('📋 OrderService: Fetching orders from server...');

      final response = await _salesOrderApiService!.getSalesOrderInfo();
      final salesOrderResponse = SalesOrderInfoResponse.fromJson(response);

      if (salesOrderResponse.success) {
        // Convert SalesOrder to Order for compatibility
        _orders =
            salesOrderResponse.orders
                ?.map((salesOrder) => salesOrder.toOrder())
                .toList() ??
            [];

        print('✅ OrderService: Loaded ${_orders.length} orders from server');
      } else {
        _errorMessage =
            salesOrderResponse.message ?? 'Failed to load orders from server';
        print('❌ OrderService: Server error: $_errorMessage');

        // Don't fallback to local storage for server errors
        _orders = [];
      }
    } catch (e) {
      print('❌ OrderService: Error loading from server: $e');

      // Check if it's a context not ready error
      if (e.toString().contains('Context not ready') ||
          e.toString().contains('not initialized')) {
        _errorMessage = 'Please log in to view your orders';
        _orders = [];
      } else {
        _errorMessage = 'Failed to load orders: ${e.toString()}';
        _orders = [];
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void setState(VoidCallback fn) {
    fn();
    notifyListeners();
  }

  /// Refresh orders from server
  Future<void> refreshOrders() async {
    if (_salesOrderApiService != null) {
      await _loadOrdersFromServer();
    } else {
      await loadOrders();
    }
  }

  Future<void> addOrder(Order order) async {
    try {
      _orders.insert(0, order); // Add to beginning of list
      notifyListeners();
    } catch (e) {
      // Error adding order: $e
    }
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      final index = _orders.indexWhere((order) => order.id == orderId);
      if (index != -1) {
        _orders[index] = Order(
          id: _orders[index].id,
          orderNo: _orders[index].orderNo,
          transNo: _orders[index].transNo,
          date: _orders[index].date,
          status: newStatus,
          totalAmount: _orders[index].totalAmount,
          itemCount: _orders[index].itemCount,
          items: _orders[index].items,
        );
        notifyListeners();
      }
    } catch (e) {
      // Error updating order status: $e
    }
  }

  /// Clear all orders (used on logout)
  Future<void> clearOrders() async {
    _orders = [];
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
    print('✅ OrderService: All orders cleared');
  }
}
