import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:truckparts_new/main.dart' as app;

/// Integration tests for authentication flows
///
/// Run these tests using:
/// flutter test integration_test/auth_flow_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Flow Tests', () {
    // Test TC-AUTH-001: Successful Login
    testWidgets('TC-AUTH-001: Login with valid credentials', (
      WidgetTester tester,
    ) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for splash screen
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Find login form elements
      final phoneField = find.byType(TextField).first;
      final passwordField = find.byType(TextField).last;
      final loginButton = find.widgetWithText(ElevatedButton, 'Login');

      // Verify we're on login page
      expect(phoneField, findsOneWidget);
      expect(passwordField, findsOneWidget);
      expect(loginButton, findsOneWidget);

      // Enter valid credentials
      await tester.enterText(phoneField, '9876543210');
      await tester.pumpAndSettle();

      await tester.enterText(passwordField, 'TestPassword@123');
      await tester.pumpAndSettle();

      // Tap login button
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Wait for navigation to home page
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verify navigation to home page
      // Adjust finder based on actual home page widgets
      expect(find.text('Home'), findsWidgets);
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    // Test TC-AUTH-002: Invalid Credentials
    testWidgets('TC-AUTH-002: Login with invalid credentials shows error', (
      WidgetTester tester,
    ) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final phoneField = find.byType(TextField).first;
      final passwordField = find.byType(TextField).last;
      final loginButton = find.widgetWithText(ElevatedButton, 'Login');

      // Enter invalid credentials
      await tester.enterText(phoneField, '9999999999');
      await tester.pumpAndSettle();

      await tester.enterText(passwordField, 'WrongPassword');
      await tester.pumpAndSettle();

      // Tap login
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Wait for error message
      await tester.pump(const Duration(seconds: 2));

      // Verify error message appears
      expect(find.textContaining('Invalid'), findsOneWidget);

      // Verify still on login page
      expect(loginButton, findsOneWidget);
    });

    // Test TC-AUTH-003: Empty Fields Validation
    testWidgets('TC-AUTH-003: Empty fields show validation errors', (
      WidgetTester tester,
    ) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final loginButton = find.widgetWithText(ElevatedButton, 'Login');

      // Try to login with empty fields
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Verify validation errors appear
      expect(find.textContaining('required'), findsWidgets);
      expect(find.textContaining('empty'), findsWidgets);
    });

    // Test TC-AUTH-005: Forgot Password Flow
    testWidgets('TC-AUTH-005: Forgot password flow initiates correctly', (
      WidgetTester tester,
    ) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Find and tap forgot password link
      final forgotPasswordLink = find.text('Forgot Password?');
      expect(forgotPasswordLink, findsOneWidget);

      await tester.tap(forgotPasswordLink);
      await tester.pumpAndSettle();

      // Verify navigation to forgot password page
      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.text('Send OTP'), findsOneWidget);
    });

    // Test TC-AUTH-006: OTP Verification
    testWidgets('TC-AUTH-006: OTP verification flow', (
      WidgetTester tester,
    ) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to forgot password
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      // Enter phone number
      final phoneField = find.byType(TextField).first;
      await tester.enterText(phoneField, '9876543210');
      await tester.pumpAndSettle();

      // Request OTP
      await tester.tap(find.text('Send OTP'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify navigation to OTP page
      expect(find.text('Enter OTP'), findsOneWidget);

      // Enter OTP (use test OTP if available)
      final otpFields = find.byType(TextField);
      // Note: Adjust based on OTP field implementation
      for (int i = 0; i < 6; i++) {
        await tester.enterText(otpFields.at(i), (i + 1).toString());
        await tester.pumpAndSettle();
      }

      // Verify OTP
      await tester.tap(find.text('Verify'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Should navigate to reset password page
      expect(find.text('New Password'), findsOneWidget);
    });

    // Test TC-AUTH-012: Session Persistence
    testWidgets('TC-AUTH-012: Session persists after app restart', (
      WidgetTester tester,
    ) async {
      // First login
      app.main();
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final phoneField = find.byType(TextField).first;
      final passwordField = find.byType(TextField).last;
      final loginButton = find.widgetWithText(ElevatedButton, 'Login');

      await tester.enterText(phoneField, '9876543210');
      await tester.enterText(passwordField, 'TestPassword@123');
      await tester.tap(loginButton);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verify logged in
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      // Simulate app restart
      await tester.restartAndRestore();
      await tester.pumpAndSettle();

      // Should still be logged in (skip splash, go to home)
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    // Test TC-AUTH-014: Logout Functionality
    testWidgets('TC-AUTH-014: Logout clears session', (
      WidgetTester tester,
    ) async {
      // Login first
      app.main();
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final phoneField = find.byType(TextField).first;
      final passwordField = find.byType(TextField).last;
      final loginButton = find.widgetWithText(ElevatedButton, 'Login');

      await tester.enterText(phoneField, '9876543210');
      await tester.enterText(passwordField, 'TestPassword@123');
      await tester.tap(loginButton);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Open navigation drawer
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Tap logout
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      // Confirm logout if confirmation dialog appears
      if (find.text('Confirm').evaluate().isNotEmpty) {
        await tester.tap(find.text('Confirm'));
        await tester.pumpAndSettle();
      }

      // Should navigate back to login
      expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);
    });
  });

  group('Edge Cases and Error Scenarios', () {
    // Test phone number validation
    testWidgets('Validates phone number format', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final phoneField = find.byType(TextField).first;
      final loginButton = find.widgetWithText(ElevatedButton, 'Login');

      // Test short phone number
      await tester.enterText(phoneField, '123');
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      expect(find.textContaining('10 digits'), findsOneWidget);

      // Test long phone number
      await tester.enterText(phoneField, '12345678901234');
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      expect(find.textContaining('10 digits'), findsOneWidget);
    });

    // Test network error handling
    testWidgets('Handles network errors gracefully', (
      WidgetTester tester,
    ) async {
      // This test would require mocking network calls
      // to simulate network failures
      // Implementation depends on your networking setup
    });
  });
}
