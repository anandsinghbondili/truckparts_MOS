import 'package:flutter/foundation.dart';

/// Service to manage loading state for background data fetch
class DataLoadingService extends ChangeNotifier {
  bool _isLoadingCustomerData = false;
  bool _isLoadingAddress = false;
  bool _isLoadingItems = false;

  String? _errorMessage;
  double _progress = 0.0;

  bool get isLoadingCustomerData => _isLoadingCustomerData;
  bool get isLoadingAddress => _isLoadingAddress;
  bool get isLoadingItems => _isLoadingItems;
  bool get isLoadingAny =>
      _isLoadingCustomerData || _isLoadingAddress || _isLoadingItems;

  String? get errorMessage => _errorMessage;
  double get progress => _progress;

  // Start loading customer data
  void startLoadingCustomerData() {
    _isLoadingCustomerData = true;
    _errorMessage = null;
    _updateProgress();
    notifyListeners();
    print('📊 DataLoadingService: Started loading customer data');
  }

  // Complete loading customer data
  void completeLoadingCustomerData() {
    _isLoadingCustomerData = false;
    _updateProgress();
    notifyListeners();
    print('📊 DataLoadingService: Completed loading customer data');
  }

  // Start loading address
  void startLoadingAddress() {
    _isLoadingAddress = true;
    _errorMessage = null;
    _updateProgress();
    notifyListeners();
    print('📊 DataLoadingService: Started loading address');
  }

  // Complete loading address
  void completeLoadingAddress() {
    _isLoadingAddress = false;
    _updateProgress();
    notifyListeners();
    print('📊 DataLoadingService: Completed loading address');
  }

  // Start loading items
  void startLoadingItems() {
    _isLoadingItems = true;
    _errorMessage = null;
    _updateProgress();
    notifyListeners();
    print('📊 DataLoadingService: Started loading items');
  }

  // Complete loading items
  void completeLoadingItems() {
    _isLoadingItems = false;
    _updateProgress();
    notifyListeners();
    print('📊 DataLoadingService: Completed loading items');
  }

  // Set error
  void setError(String message) {
    _errorMessage = message;
    _isLoadingCustomerData = false;
    _isLoadingAddress = false;
    _isLoadingItems = false;
    notifyListeners();
    print('📊 DataLoadingService: Error - $message');
  }

  // Reset all loading states
  void reset() {
    _isLoadingCustomerData = false;
    _isLoadingAddress = false;
    _isLoadingItems = false;
    _errorMessage = null;
    _progress = 0.0;
    notifyListeners();
    print('📊 DataLoadingService: Reset all loading states');
  }

  // Update progress based on completed steps
  void _updateProgress() {
    int completed = 0;
    int total = 3;

    if (!_isLoadingCustomerData) completed++;
    if (!_isLoadingAddress) completed++;
    if (!_isLoadingItems) completed++;

    _progress = completed / total;
    print('📊 DataLoadingService: Progress = ${(_progress * 100).toInt()}%');
  }

  // Get loading message based on current state
  String get loadingMessage {
    if (_isLoadingCustomerData) {
      return 'Loading customer data...';
    } else if (_isLoadingAddress) {
      return 'Loading address...';
    } else if (_isLoadingItems) {
      return 'Loading items. Please wait...';
    }
    return 'Loading...';
  }
}
