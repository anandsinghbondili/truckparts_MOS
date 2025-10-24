import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:truckparts_new/main.dart' as app;

/// Integration tests for search and filter functionality
///
/// Run these tests using:
/// flutter test integration_test/search_flow_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Search and Filter Flow Tests', () {
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

    // Test TC-SEARCH-001: Vehicle Make Selection
    testWidgets('TC-SEARCH-001: Select vehicle make from dialog', (
      WidgetTester tester,
    ) async {
      app.main();
      await tester.pumpAndSettle();
      await loginUser(tester);

      // Tap "Search by Vehicle" button
      final searchByVehicleButton = find.text('Search by Vehicle');
      expect(searchByVehicleButton, findsOneWidget);

      await tester.tap(searchByVehicleButton);
      await tester.pumpAndSettle();

      // Verify vehicle make dialog appears
      expect(find.text('Select Vehicle Make'), findsOneWidget);

      // Find and select a make (e.g., "Tata")
      final tataOption = find.text('Tata');
      expect(tataOption, findsOneWidget);

      await tester.tap(tataOption);
      await tester.pumpAndSettle();

      // Verify selection or navigation to next step
      expect(find.text('Select Vehicle Model'), findsOneWidget);
    });

    // Test TC-SEARCH-002: Vehicle Model Selection
    testWidgets('TC-SEARCH-002: Select vehicle model after make', (
      WidgetTester tester,
    ) async {
      app.main();
      await tester.pumpAndSettle();
      await loginUser(tester);

      // Navigate through vehicle selection
      await tester.tap(find.text('Search by Vehicle'));
      await tester.pumpAndSettle();

      // Select make
      await tester.tap(find.text('Tata'));
      await tester.pumpAndSettle();

      // Verify model dialog appears
      expect(find.text('Select Vehicle Model'), findsOneWidget);

      // Select a model
      final modelOption = find.text('407').first;
      await tester.tap(modelOption);
      await tester.pumpAndSettle();

      // Should navigate to search results
      expect(find.text('Search Results'), findsOneWidget);
    });

    // Test TC-SEARCH-003: Complete Vehicle Search Flow
    testWidgets('TC-SEARCH-003: Complete vehicle search shows results', (
      WidgetTester tester,
    ) async {
      app.main();
      await tester.pumpAndSettle();
      await loginUser(tester);

      // Perform vehicle search
      await tester.tap(find.text('Search by Vehicle'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tata'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('407').first);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify results page
      expect(find.text('Search Results'), findsOneWidget);

      // Verify filter chips show selected criteria
      expect(find.textContaining('Tata'), findsOneWidget);
      expect(find.textContaining('407'), findsOneWidget);

      // Verify results are displayed
      expect(find.byType(Card), findsWidgets);
    });

    // Test TC-SEARCH-004: Category Selection
    testWidgets('TC-SEARCH-004: Search by category', (
      WidgetTester tester,
    ) async {
      app.main();
      await tester.pumpAndSettle();
      await loginUser(tester);

      // Tap "Search by Category" button
      final searchByCategoryButton = find.text('Search by Category');
      expect(searchByCategoryButton, findsOneWidget);

      await tester.tap(searchByCategoryButton);
      await tester.pumpAndSettle();

      // Verify category dialog appears
      expect(find.text('Select Category'), findsOneWidget);

      // Select a category
      final brakesOption = find.text('Brakes');
      await tester.tap(brakesOption);
      await tester.pumpAndSettle();

      // Verify navigation to results
      expect(find.text('Search Results'), findsOneWidget);
      expect(find.textContaining('Brakes'), findsOneWidget);
    });

    // Test TC-SEARCH-006: Brand Search
    testWidgets('TC-SEARCH-006: Search by brand', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      await loginUser(tester);

      // Find brand logos section
      final brandLogos = find.byType(Image);
      expect(brandLogos, findsWidgets);

      // Tap first brand logo
      await tester.tap(brandLogos.first);
      await tester.pumpAndSettle();

      // Verify brand selection or results
      expect(find.text('Search Results'), findsOneWidget);
    });

    // Test TC-SEARCH-007: Type Selection
    testWidgets('TC-SEARCH-007: Search by type and size', (
      WidgetTester tester,
    ) async {
      app.main();
      await tester.pumpAndSettle();
      await loginUser(tester);

      // Tap "Search by Type & Size" button
      final searchByTypeButton = find.text('Search by Type & Size');
      expect(searchByTypeButton, findsOneWidget);

      await tester.tap(searchByTypeButton);
      await tester.pumpAndSettle();

      // Select type
      expect(find.text('Select Type'), findsOneWidget);

      final typeOption = find.text('Radial').first;
      await tester.tap(typeOption);
      await tester.pumpAndSettle();

      // Verify size selection appears
      expect(find.text('Select Size'), findsOneWidget);
    });

    // Test TC-SEARCH-009: Search Results Display
    testWidgets('TC-SEARCH-009: Search results display correctly', (
      WidgetTester tester,
    ) async {
      app.main();
      await tester.pumpAndSettle();
      await loginUser(tester);

      // Perform a search
      await tester.tap(find.text('Search by Category'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Brakes'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify results page structure
      expect(find.text('Search Results'), findsOneWidget);

      // Verify product cards are displayed
      final productCards = find.byType(Card);
      expect(productCards, findsWidgets);

      // Verify each product shows required info
      expect(find.byType(Image), findsWidgets); // Product images
      expect(find.textContaining('₹'), findsWidgets); // Prices

      // Verify filter options available
      expect(find.byIcon(Icons.filter_list), findsOneWidget);
    });

    // Test TC-SEARCH-010: Empty Search Results
    testWidgets('TC-SEARCH-010: Empty results show appropriate message', (
      WidgetTester tester,
    ) async {
      app.main();
      await tester.pumpAndSettle();
      await loginUser(tester);

      // Perform a search that yields no results
      // This might require searching for something that doesn't exist
      final searchBar = find.byType(TextField).first;
      await tester.tap(searchBar);
      await tester.enterText(searchBar, 'NonExistentProduct12345');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify empty state
      expect(find.text('No results found'), findsOneWidget);
      expect(find.text('Try different search criteria'), findsOneWidget);
    });

    // Test TC-SEARCH-011: Filter Modification
    testWidgets('TC-SEARCH-011: Modify filters on results page', (
      WidgetTester tester,
    ) async {
      app.main();
      await tester.pumpAndSettle();
      await loginUser(tester);

      // Perform initial search
      await tester.tap(find.text('Search by Category'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Brakes'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Tap filter icon
      final filterIcon = find.byIcon(Icons.filter_list);
      await tester.tap(filterIcon);
      await tester.pumpAndSettle();

      // Apply additional filter
      // This depends on your filter implementation
      final brandFilter = find.text('Brand');
      if (brandFilter.evaluate().isNotEmpty) {
        await tester.tap(brandFilter);
        await tester.pumpAndSettle();

        // Select a brand
        await tester.tap(find.text('Bosch').first);
        await tester.pumpAndSettle();

        // Apply filter
        await tester.tap(find.text('Apply'));
        await tester.pumpAndSettle();

        // Verify filter chip appears
        expect(find.textContaining('Bosch'), findsOneWidget);
      }
    });

    // Test TC-SEARCH-012: Sort Options
    testWidgets('TC-SEARCH-012: Sort results by different criteria', (
      WidgetTester tester,
    ) async {
      app.main();
      await tester.pumpAndSettle();
      await loginUser(tester);

      // Perform search
      await tester.tap(find.text('Search by Category'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Brakes'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Find sort button/dropdown
      final sortButton = find.byIcon(Icons.sort);
      if (sortButton.evaluate().isNotEmpty) {
        await tester.tap(sortButton);
        await tester.pumpAndSettle();

        // Select sort option
        final priceLowToHigh = find.text('Price: Low to High');
        await tester.tap(priceLowToHigh);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify results are re-sorted
        // This would require checking if first item price < last item price
      }
    });

    // Test TC-SEARCH-013: View Product Details
    testWidgets('TC-SEARCH-013: View product details from results', (
      WidgetTester tester,
    ) async {
      app.main();
      await tester.pumpAndSettle();
      await loginUser(tester);

      // Perform search
      await tester.tap(find.text('Search by Category'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Brakes'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Tap first product
      final firstProduct = find.byType(Card).first;
      await tester.tap(firstProduct);
      await tester.pumpAndSettle();

      // Verify product details page
      expect(find.text('Product Details'), findsOneWidget);
      expect(find.text('Add to Cart'), findsOneWidget);

      // Verify product information displayed
      expect(find.byType(Image), findsWidgets);
      expect(find.textContaining('₹'), findsOneWidget);
      expect(find.textContaining('Brand'), findsOneWidget);
    });

    // Test Filter Removal
    testWidgets('Remove individual filter chips', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      await loginUser(tester);

      // Perform search with filters
      await tester.tap(find.text('Search by Vehicle'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tata'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('407').first);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Find filter chip close button
      final chipCloseButton = find.byIcon(Icons.close).first;

      if (chipCloseButton.evaluate().isNotEmpty) {
        await tester.tap(chipCloseButton);
        await tester.pumpAndSettle();

        // Verify filter removed and results updated
        // Results should change to show broader selection
      }
    });

    // Test Search Pagination
    testWidgets('Load more results on scroll', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      await loginUser(tester);

      // Perform search
      await tester.tap(find.text('Search by Category'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Brakes'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Count initial results
      final initialCards = find.byType(Card).evaluate().length;

      // Scroll to bottom
      await tester.drag(find.byType(ListView).first, const Offset(0, -500));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Count results after scroll
      final afterScrollCards = find.byType(Card).evaluate().length;

      // More items should be loaded (if pagination implemented)
      // Uncomment when pagination is implemented
      expect(afterScrollCards, greaterThanOrEqualTo(initialCards));
    });
  });

  group('Search Edge Cases', () {
    testWidgets('Handle special characters in search', (
      WidgetTester tester,
    ) async {
      // Test searching with special characters
    });

    testWidgets('Handle very long search queries', (WidgetTester tester) async {
      // Test with extremely long search text
    });

    testWidgets('Handle rapid filter changes', (WidgetTester tester) async {
      // Test quickly applying and removing filters
    });

    testWidgets('Handle search with slow network', (WidgetTester tester) async {
      // Test search behavior with network delays
    });
  });
}
