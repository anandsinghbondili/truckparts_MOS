import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Service for SMS OTP Auto-fill
///
/// This service provides SMS OTP auto-detection and auto-fill functionality
/// for Android and iOS devices using platform-specific implementations.
class SmsAutofillService {
  static const MethodChannel _channel = MethodChannel('sms_autofill');

  /// Listen for incoming SMS with OTP
  ///
  /// This method will automatically detect SMS containing OTP
  /// and return the OTP code when received.
  ///
  /// Returns a Stream of OTP codes detected from incoming SMS
  static Stream<String> get otpStream async* {
    // For now, this is a placeholder implementation
    // In production, this would use SMS Retriever API for Android
    // and SMS User Consent API for iOS

    // You would integrate packages like:
    // - sms_autofill (for Android SMS Retriever API)
    // - smart_auth (for cross-platform SMS OTP)

    yield* Stream.empty();
  }

  /// Request SMS permissions and start listening for OTP
  ///
  /// Returns true if permissions granted and listening started
  static Future<bool> startListening() async {
    try {
      // Placeholder - would call native code
      return true;
    } catch (e) {
      print('Error starting SMS listening: $e');
      return false;
    }
  }

  /// Stop listening for SMS
  static Future<void> stopListening() async {
    try {
      // Placeholder - would call native code
    } catch (e) {
      print('Error stopping SMS listening: $e');
    }
  }

  /// Extract OTP from SMS text
  ///
  /// Extracts numeric OTP from SMS message
  /// Supports common OTP patterns (4-6 digits)
  static String? extractOtpFromSms(String smsBody) {
    // Pattern to match 4-6 digit OTP
    final RegExp otpPattern = RegExp(r'\b(\d{4,6})\b');
    final match = otpPattern.firstMatch(smsBody);

    if (match != null && match.groupCount >= 1) {
      return match.group(1);
    }

    return null;
  }

  /// Get app signature for SMS Retriever API (Android only)
  ///
  /// This signature is used to identify your app in SMS
  /// Required format: <#> Your OTP is 1234 <app_signature>
  static Future<String?> getAppSignature() async {
    try {
      final String? signature = await _channel.invokeMethod('getAppSignature');
      return signature;
    } catch (e) {
      print('Error getting app signature: $e');
      return null;
    }
  }
}

/// Widget mixin for OTP auto-fill functionality
///
/// Use this mixin in your OTP verification widget to enable auto-fill
///
/// Example:
/// ```dart
/// class _OtpPageState extends State<OtpPage> with OtpAutoFillMixin {
///   @override
///   void initState() {
///     super.initState();
///     listenForOtp();
///   }
///
///   @override
///   void onOtpReceived(String otp) {
///     // Fill OTP in text field
///     otpController.text = otp;
///   }
/// }
/// ```
mixin OtpAutoFillMixin<T extends StatefulWidget> on State<T> {
  /// Override this method to handle received OTP
  void onOtpReceived(String otp);

  /// Start listening for OTP
  void listenForOtp() {
    SmsAutofillService.startListening();
    SmsAutofillService.otpStream.listen((otp) {
      if (mounted) {
        onOtpReceived(otp);
      }
    });
  }

  @override
  void dispose() {
    SmsAutofillService.stopListening();
    super.dispose();
  }
}
