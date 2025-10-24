# Truck Parts Mobile App - Testing Guide

## Overview

This document provides comprehensive guidance for testing the Truck Parts mobile application. The test suite includes unit tests, widget tests, and integration tests covering all major features and workflows.

---

## Table of Contents

1. [Test Documentation](#test-documentation)
2. [Test Structure](#test-structure)
3. [Running Tests](#running-tests)
4. [Writing Tests](#writing-tests)
5. [Test Data Setup](#test-data-setup)
6. [CI/CD Integration](#cicd-integration)
7. [Best Practices](#best-practices)
8. [Troubleshooting](#troubleshooting)

---

## Test Documentation

### Available Test Documents

1. **TEST_CASES.md** - Comprehensive test cases covering all functionality

   - Detailed step-by-step test procedures
   - Expected results for each test
   - Priority levels and test data
   - Bug reporting templates

2. **TEST_CHECKLIST.md** - Quick reference checklist

   - Pre-release smoke tests
   - Critical flow verification
   - Platform-specific testing
   - Sign-off checklist

3. **Integration Tests** - Automated test suites
   - `test/integration/auth_flow_test.dart` - Authentication tests
   - `test/integration/cart_flow_test.dart` - Shopping cart tests
   - `test/integration/search_flow_test.dart` - Search and filter tests

---

## Test Structure

```
test/
├── TESTING_README.md              # This file
├── integration/                   # Integration tests
│   ├── auth_flow_test.dart       # Authentication flow tests
│   ├── cart_flow_test.dart       # Cart and checkout tests
│   ├── search_flow_test.dart     # Search and filter tests
│   └── order_flow_test.dart      # Order management tests (to be added)
├── unit/                          # Unit tests
│   ├── models/                   # Model tests
│   ├── repositories/             # Repository tests
│   ├── services/                 # Service tests
│   └── utils/                    # Utility tests
└── widget/                        # Widget tests
    ├── auth/                     # Auth widget tests
    ├── cart/                     # Cart widget tests
    ├── home/                     # Home widget tests
    └── common/                   # Common widget tests

../TEST_CASES.md                   # Comprehensive test cases
../TEST_CHECKLIST.md               # Quick test checklist
```

---

## Running Tests

### Prerequisites

1. **Install Dependencies**

   ```bash
   flutter pub get
   ```

2. **Setup Test Environment**
   - Configure test API endpoints (if different from production)
   - Prepare test user accounts
   - Ensure test data is available

### Run All Tests

```bash
# Run all tests (unit, widget, integration)
flutter test

# Run with coverage
flutter test --coverage

# View coverage report
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Run Specific Test Suites

```bash
# Run only integration tests
flutter test test/integration/

# Run specific test file
flutter test test/integration/auth_flow_test.dart

# Run unit tests only
flutter test test/unit/

# Run widget tests only
flutter test test/widget/
```

### Run Integration Tests on Devices

```bash
# List available devices
flutter devices

# Run on specific device
flutter test test/integration/auth_flow_test.dart -d <device-id>

# Run on Android emulator
flutter test test/integration/ -d emulator-5554

# Run on iOS simulator
flutter test test/integration/ -d iPhone-14
```

### Run Tests with Specific Tags

```bash
# Run only critical tests
flutter test --tags critical

# Exclude slow tests
flutter test --exclude-tags slow

# Run smoke tests
flutter test --tags smoke
```

---

## Writing Tests

### Test Naming Conventions

- **Test files**: `*_test.dart`
- **Test names**: Should match test case IDs from TEST_CASES.md
- **Groups**: Logical grouping by feature or flow

### Example Test Structure

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Feature Name Tests', () {

    // Setup that runs before each test
    setUp(() {
      // Initialize mocks, test data, etc.
    });

    // Cleanup after each test
    tearDown(() {
      // Clean up resources
    });

    test('TC-XXX-001: Descriptive test name', () {
      // Arrange
      // Set up test conditions

      // Act
      // Perform the action being tested

      // Assert
      // Verify expected results
    });

    testWidgets('TC-XXX-002: Widget test', (WidgetTester tester) async {
      // Build widget
      await tester.pumpWidget(MyWidget());

      // Interact
      await tester.tap(find.text('Button'));
      await tester.pump();

      // Verify
      expect(find.text('Result'), findsOneWidget);
    });
  });
}
```

### Unit Test Example

```dart
// test/unit/services/cart_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

void main() {
  group('CartService', () {
    late CartService cartService;
    late MockCartRepository mockRepository;

    setUp(() {
      mockRepository = MockCartRepository();
      cartService = CartService(mockRepository);
    });

    test('addItem increases cart count', () async {
      // Arrange
      final item = CartItem(id: '1', name: 'Brake Pad', price: 500);

      // Act
      await cartService.addItem(item);

      // Assert
      expect(cartService.itemCount, 1);
      verify(mockRepository.saveCart(any)).called(1);
    });

    test('removeItem decreases cart count', () async {
      // Arrange
      final item = CartItem(id: '1', name: 'Brake Pad', price: 500);
      await cartService.addItem(item);

      // Act
      await cartService.removeItem('1');

      // Assert
      expect(cartService.itemCount, 0);
    });
  });
}
```

### Widget Test Example

```dart
// test/widget/common/custom_button_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CustomButton displays label', (WidgetTester tester) async {
    // Build widget
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomButton(
            label: 'Click Me',
            onPressed: () {},
          ),
        ),
      ),
    );

    // Verify
    expect(find.text('Click Me'), findsOneWidget);
  });

  testWidgets('CustomButton calls onPressed when tapped', (WidgetTester tester) async {
    bool pressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomButton(
            label: 'Click Me',
            onPressed: () => pressed = true,
          ),
        ),
      ),
    );

    // Tap button
    await tester.tap(find.text('Click Me'));
    await tester.pump();

    // Verify callback called
    expect(pressed, true);
  });
}
```

### Integration Test Example

```dart
// test/integration/login_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Complete login flow', (WidgetTester tester) async {
    // Launch app
    app.main();
    await tester.pumpAndSettle();

    // Find widgets
    final phoneField = find.byKey(Key('phone_field'));
    final passwordField = find.byKey(Key('password_field'));
    final loginButton = find.byKey(Key('login_button'));

    // Enter credentials
    await tester.enterText(phoneField, '9876543210');
    await tester.enterText(passwordField, 'Password123');
    await tester.tap(loginButton);

    // Wait for navigation
    await tester.pumpAndSettle(Duration(seconds: 5));

    // Verify home page
    expect(find.text('Home'), findsOneWidget);
  });
}
```

---

## Test Data Setup

### Test User Accounts

Create test accounts for different scenarios:

```dart
class TestData {
  static const validUser = {
    'phone': '9876543210',
    'password': 'TestPassword@123',
  };

  static const invalidUser = {
    'phone': '9999999999',
    'password': 'WrongPassword',
  };

  static const blockedUser = {
    'phone': '1111111111',
    'password': 'BlockedUser@123',
  };
}
```

### Mock Data

```dart
// test/mocks/mock_data.dart
class MockData {
  static List<Product> get products => [
    Product(
      id: '1',
      name: 'Brake Pad',
      price: 500,
      brand: 'Bosch',
      category: 'Brakes',
    ),
    Product(
      id: '2',
      name: 'Oil Filter',
      price: 200,
      brand: 'Mann',
      category: 'Filters',
    ),
  ];

  static List<Order> get orders => [
    Order(
      id: 'ORD001',
      date: DateTime.now(),
      status: 'Delivered',
      total: 1500,
    ),
  ];
}
```

### Mock Services

Use `mockito` or `mocktail` for mocking dependencies:

```bash
# Add to pubspec.yaml
dev_dependencies:
  mockito: ^5.4.0
  build_runner: ^2.4.0
```

Generate mocks:

```bash
flutter pub run build_runner build
```

---

## CI/CD Integration

### GitHub Actions

Create `.github/workflows/test.yml`:

```yaml
name: Run Tests

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: "3.9.2"

      - name: Install dependencies
        run: flutter pub get

      - name: Run tests
        run: flutter test --coverage

      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          file: coverage/lcov.info
```

### Gitlab CI

Create `.gitlab-ci.yml`:

```yaml
stages:
  - test

test:
  stage: test
  image: cirrusci/flutter:stable
  script:
    - flutter pub get
    - flutter test --coverage
  coverage: '/lines\.*: \d+\.\d+%/'
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage/cobertura.xml
```

---

## Best Practices

### General

1. **Write Tests First** (TDD)

   - Define expected behavior
   - Write failing test
   - Implement feature
   - Refactor

2. **Keep Tests Independent**

   - Each test should run in isolation
   - Don't depend on test execution order
   - Clean up after each test

3. **Use Descriptive Names**

   - Test names should clearly describe what is being tested
   - Include test case IDs for traceability

4. **Follow AAA Pattern**

   - **Arrange**: Set up test conditions
   - **Act**: Execute the code being tested
   - **Assert**: Verify expected results

5. **Test Edge Cases**
   - Empty inputs
   - Null values
   - Maximum/minimum values
   - Error conditions

### Widget Tests

1. **Use Keys for Critical Widgets**

   ```dart
   TextField(key: Key('phone_field'))
   ```

2. **Pump Appropriately**

   - `pump()` - Single frame
   - `pumpAndSettle()` - Wait for animations
   - `pumpWidget()` - Build widget tree

3. **Test Accessibility**
   - Verify semantic labels
   - Test with screen readers
   - Check contrast ratios

### Integration Tests

1. **Keep Tests Focused**

   - One user flow per test
   - Don't try to test everything in one test

2. **Use Realistic Delays**

   ```dart
   await tester.pumpAndSettle(Duration(seconds: 3));
   ```

3. **Handle Flakiness**

   - Wait for specific conditions
   - Use retry logic for network calls
   - Clear state between tests

4. **Clean Up**
   - Logout after each test
   - Clear cart
   - Reset app state

---

## Test Coverage

### Coverage Goals

- **Overall**: > 80%
- **Critical paths**: > 95%
- **Business logic**: > 90%
- **UI widgets**: > 70%

### Generate Coverage Report

```bash
# Generate coverage
flutter test --coverage

# Convert to HTML
genhtml coverage/lcov.info -o coverage/html

# Open in browser
open coverage/html/index.html
```

### Exclude Files from Coverage

Create `coverage_excludes.txt`:

```
lib/core/config/*
lib/**/*.g.dart
lib/**/*.freezed.dart
```

---

## Troubleshooting

### Common Issues

#### 1. Tests Timing Out

```dart
// Increase timeout
testWidgets('My test', (tester) async {
  // Test code
}, timeout: Timeout(Duration(seconds: 30)));
```

#### 2. Pump Not Settling

```dart
// Use pump with specific duration
await tester.pump(Duration(seconds: 1));

// Or pump multiple times
for (int i = 0; i < 5; i++) {
  await tester.pump(Duration(milliseconds: 100));
}
```

#### 3. Widget Not Found

```dart
// Wait for widget to appear
await tester.pumpAndSettle();

// Use find.byKey instead of find.text
expect(find.byKey(Key('my_widget')), findsOneWidget);

// Print widget tree for debugging
debugDumpApp();
```

#### 4. Mock Not Working

```dart
// Verify mock is being called
verify(mockRepository.getData()).called(1);

// Use any() for flexible matching
when(mockRepository.getData(any)).thenAnswer((_) async => data);
```

#### 5. Integration Test Flaky

```dart
// Wait for specific condition
await tester.pumpAndSettle();
await Future.delayed(Duration(seconds: 1));

// Use runAsync for real async operations
await tester.runAsync(() async {
  await Future.delayed(Duration(seconds: 2));
});
```

### Debug Tests

```dart
// Print widget tree
debugDumpApp();

// Print render tree
debugDumpRenderTree();

// Print semantics
debugDumpSemanticsTree();

// Print during test
print('Current state: $myVariable');
```

---

## Continuous Improvement

### Regular Tasks

1. **Weekly**

   - Review failing tests
   - Update test data
   - Check coverage metrics

2. **Monthly**

   - Review and update test cases
   - Refactor flaky tests
   - Add tests for new features

3. **Quarterly**
   - Performance test review
   - Security test review
   - Accessibility audit

### Metrics to Track

- Test count (unit, widget, integration)
- Code coverage percentage
- Test execution time
- Flaky test rate
- Bug escape rate

---

## Resources

### Flutter Testing Documentation

- [Flutter Testing Guide](https://docs.flutter.dev/testing)
- [Widget Testing](https://docs.flutter.dev/cookbook/testing/widget/introduction)
- [Integration Testing](https://docs.flutter.dev/testing/integration-tests)
- [Mockito Documentation](https://pub.dev/packages/mockito)

### Useful Packages

- `flutter_test` - Core testing framework
- `integration_test` - Integration testing
- `mockito` - Mocking framework
- `bloc_test` - BLoC testing utilities
- `golden_toolkit` - Golden image testing
- `patrol` - Advanced integration testing

### Test Case References

- `../TEST_CASES.md` - Detailed test case documentation
- `../TEST_CHECKLIST.md` - Quick test checklist

---

## Contact

For questions or issues with tests:

- Create an issue in the project repository
- Contact the QA team
- Review test documentation

---

**Last Updated**: [Current Date]  
**Maintained By**: QA Team  
**Version**: 1.0
