import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:truckparts_new/main.dart' as app;

/// Integration tests for shopping cart functionality
///
/// Run these tests using:
/// flutter test integration_test/cart_flow_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Shopping Cart Flow Tests', () {
    // Helper function to login before each test
    Future<void> loginUser(WidgetTester tester) async {
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final phoneField = find.byType(TextField).first;
      final passwordField = find.byType(TextField).last;
      final loginButton = find.widgetWithText(ElevatedButton, 'Login');

      await tester.enterText(phoneField, '9876543210');
      await tester.enterText(passwordField, 'TestPassword@123');
      await tester.tap(loginButton);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    }

    // Test TC-CART-001: Add First Item to Cart
    testWidgets('TC-CART-001: Add first item to cart successfully', (
      WidgetTester tester,
    ) async {
      app.main();
      await tester.pumpAndSettle();
      await loginUser(tester);

      // Navigate to search or browse products
      // Adjust based on your app's flow
      final searchBar = find.byType(TextField).first;
      await tester.tap(searchBar);
      await tester.pumpAndSettle();

      // Search for a product
      await tester.enterText(searchBar, 'brake');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Find and tap first product in results
      final firstProduct = find.byType(Card).first;
      expect(firstProduct, findsOneWidget);

      await tester.tap(firstProduct);
      await tester.pumpAndSettle();

      // Find and tap "Add to Cart" button
      final addToCartButton = find.text('Add to Cart');
      expect(addToCartButton, findsOneWidget);

      await tester.tap(addToCartButton);
      await tester.pumpAndSettle();

      // Verify success message or cart badge update
      expect(find.text('Added to cart'), findsOneWidget);

      // Verify cart badge shows "1"
      expect(find.text('1'), findsOneWidget);
    });

    // Test TC-CART-002: Add Multiple Items
    testWidgets('TC-CART-002: Add multiple different items to cart', (
      WidgetTester tester,
    ) async {
      app.main();
      await tester.pumpAndSettle();
      await loginUser(tester);

      // Add first item
      await tester.tap(find.byType(TextField).first);
      await tester.enterText(find.byType(TextField).first, 'brake');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.byType(Card).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add to Cart'));
      await tester.pumpAndSettle();

      // Go back to search
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Add second item
      await tester.enterText(find.byType(TextField).first, 'filter');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.byType(Card).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add to Cart'));
      await tester.pumpAndSettle();

      // Verify cart badge shows "2"
      expect(find.text('2'), findsOneWidget);
    });

    // Test TC-CART-005: View Cart Page
    testWidgets('TC-CART-005: View cart page displays all items', (
      WidgetTester tester,
    ) async {
      app.main();
      await tester.pumpAndSettle();
      await loginUser(tester);

      // Add an item first
      await tester.tap(find.byType(TextField).first);
      await tester.enterText(find.byType(TextField).first, 'brake');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.byType(Card).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add to Cart'));
      await tester.pumpAndSettle();

      // Navigate to cart page via bottom navigation
      final cartTab = find.text('Cart');
      expect(cartTab, findsOneWidget);

      await tester.tap(cartTab);
      await tester.pumpAndSettle();

      // Verify cart page elements
      expect(find.text('Shopping Cart'), findsOneWidget);
      expect(find.text('Checkout'), findsOneWidget);

      // Verify cart items are displayed
      expect(find.byType(ListTile), findsWidgets);

      // Verify price summary
      expect(find.textContaining('Subtotal'), findsOneWidget);
      expect(find.textContaining('Total'), findsOneWidget);
    });

    // Test TC-CART-006: Empty Cart Display
    testWidgets('TC-CART-006: Empty cart shows appropriate message', (
      WidgetTester tester,
    ) async {
      app.main();
      await tester.pumpAndSettle();
      await loginUser(tester);

      // Navigate to cart (assuming it's empty)
      await tester.tap(find.text('Cart'));
      await tester.pumpAndSettle();

      // Verify empty state
      expect(find.text('Your cart is empty'), findsOneWidget);
      expect(find.text('Continue Shopping'), findsOneWidget);

      // Verify checkout is disabled or not visible
      expect(find.text('Checkout'), findsNothing);
    });

    // Test TC-CART-007: Increase Item Quantity
    testWidgets('TC-CART-007: Increase item quantity updates total', (
      WidgetTester tester,
    ) async {
      app.main();
      await tester.pumpAndSettle();
      await loginUser(tester);

      // Add item and navigate to cart
      await tester.tap(find.byType(TextField).first);
      await tester.enterText(find.byType(TextField).first, 'brake');
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await tester.tap(find.byType(Card).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add to Cart'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cart'));
      await tester.pumpAndSettle();

      // Find initial total
      final initialTotal = find.textContaining('₹');
      final initialTotalText = tester.widget<Text>(initialTotal.first).data;

      // Tap increase quantity button
      final increaseButton = find.byIcon(Icons.add);
      expect(increaseButton, findsOneWidget);

      await tester.tap(increaseButton);
      await tester.pumpAndSettle();

      // Verify quantity increased
      expect(find.text('2'), findsOneWidget);

      // Verify total updated
      final newTotal = find.textContaining('₹');
      final newTotalText = tester.widget<Text>(newTotal.first).data;

      expect(newTotalText != initialTotalText, isTrue);
    });

    // Test TC-CART-008: Decrease Item Quantity
    testWidgets('TC-CART-008: Decrease item quantity updates total', (
      WidgetTester tester,
    ) async {
      app.main();
      await tester.pumpAndSettle();
      await loginUser(tester);

      // Add item and navigate to cart
      await tester.tap(find.byType(TextField).first);
      await tester.enterText(find.byType(TextField).first, 'brake');
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await tester.tap(find.byType(Card).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add to Cart'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cart'));
      await tester.pumpAndSettle();

      // Increase quantity first
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.text('2'), findsOneWidget);

      // Now decrease
      final decreaseButton = find.byIcon(Icons.remove);
      await tester.tap(decreaseButton);
      await tester.pumpAndSettle();

      // Verify quantity decreased back to 1
      expect(find.text('1'), findsOneWidget);
    });

    // Test TC-CART-009: Remove Item from Cart
    testWidgets('TC-CART-009: Remove item from cart', (
      WidgetTester tester,
    ) async {
      app.main();
      await tester.pumpAndSettle();
      await loginUser(tester);

      // Add item and navigate to cart
      await tester.tap(find.byType(TextField).first);
      await tester.enterText(find.byType(TextField).first, 'brake');
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await tester.tap(find.byType(Card).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add to Cart'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cart'));
      await tester.pumpAndSettle();

      // Find and tap remove/delete button
      final removeButton = find.byIcon(Icons.delete);
      expect(removeButton, findsOneWidget);

      await tester.tap(removeButton);
      await tester.pumpAndSettle();

      // Confirm removal if dialog appears
      if (find.text('Remove').evaluate().isNotEmpty) {
        await tester.tap(find.text('Remove'));
        await tester.pumpAndSettle();
      }

      // Verify item removed - should show empty cart
      expect(find.text('Your cart is empty'), findsOneWidget);
    });

    // Test TC-CART-011: Cart Persistence
    testWidgets('TC-CART-011: Cart persists after app restart', (
      WidgetTester tester,
    ) async {
      app.main();
      await tester.pumpAndSettle();
      await loginUser(tester);

      // Add item to cart
      await tester.tap(find.byType(TextField).first);
      await tester.enterText(find.byType(TextField).first, 'brake');
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await tester.tap(find.byType(Card).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add to Cart'));
      await tester.pumpAndSettle();

      // Verify cart badge
      expect(find.text('1'), findsOneWidget);

      // Simulate app restart
      await tester.restartAndRestore();
      await tester.pumpAndSettle();

      // Cart should still have item
      expect(find.text('1'), findsOneWidget);

      // Navigate to cart to verify
      await tester.tap(find.text('Cart'));
      await tester.pumpAndSettle();

      // Verify item still in cart
      expect(find.byType(ListTile), findsOneWidget);
    });

    // Test TC-CART-013: Initiate Checkout
    testWidgets('TC-CART-013: Checkout flow initiates correctly', (
      WidgetTester tester,
    ) async {
      app.main();
      await tester.pumpAndSettle();
      await loginUser(tester);

      // Add item and navigate to cart
      await tester.tap(find.byType(TextField).first);
      await tester.enterText(find.byType(TextField).first, 'brake');
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await tester.tap(find.byType(Card).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add to Cart'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cart'));
      await tester.pumpAndSettle();

      // Tap checkout button
      final checkoutButton = find.text('Checkout');
      expect(checkoutButton, findsOneWidget);

      await tester.tap(checkoutButton);
      await tester.pumpAndSettle();

      // Verify navigation to OTP confirmation page
      expect(find.text('Confirm Order'), findsOneWidget);
      expect(find.text('Send OTP'), findsOneWidget);
    });

    // Test TC-CART-014: Checkout with Empty Cart
    testWidgets('TC-CART-014: Cannot checkout with empty cart', (
      WidgetTester tester,
    ) async {
      app.main();
      await tester.pumpAndSettle();
      await loginUser(tester);

      // Navigate to cart (empty)
      await tester.tap(find.text('Cart'));
      await tester.pumpAndSettle();

      // Verify checkout button is not present or disabled
      expect(find.text('Checkout'), findsNothing);
    });
  });

  group('Cart Edge Cases', () {
    testWidgets('Handle adding out of stock item', (WidgetTester tester) async {
      // This test would require mocking an out-of-stock item
      // Implementation depends on your data layer
    });

    testWidgets('Handle maximum quantity limit', (WidgetTester tester) async {
      // Test adding items beyond available stock or configured limits
    });

    testWidgets('Handle price updates in cart', (WidgetTester tester) async {
      // Test that cart reflects current prices if they change
    });
  });
}
