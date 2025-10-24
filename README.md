# Truck Parts - B2B Auto Parts Ordering App

A comprehensive Flutter application for B2B automobile parts ordering, built with clean architecture principles and modern development practices.

## 🏗️ Architecture Overview

This project implements **Clean Architecture** with the following layers:

### 1. **Domain Layer** (`lib/features/*/domain/`)

- **Entities**: Core business objects
- **Repositories**: Abstract interfaces for data access
- **Use Cases**: Business logic implementation

### 2. **Data Layer** (`lib/features/*/data/`)

- **Models**: Data transfer objects with JSON serialization
- **Data Sources**: Remote (API) and Local (Storage) implementations
- **Repository Implementations**: Concrete implementations of domain repositories

### 3. **Presentation Layer** (`lib/features/*/presentation/`)

- **BLoC**: State management using BLoC pattern
- **Pages**: Screen implementations
- **Widgets**: Reusable UI components

### 4. **Core Layer** (`lib/core/`)

- **Constants**: App-wide constants and configuration
- **Errors**: Custom failure classes
- **Network**: API client and network utilities
- **Theme**: Consistent UI theme and styling
- **Router**: Navigation configuration

## 🚀 Key Features

### ✅ Implemented

- **Authentication System**: Login, forgot password, OTP verification, password reset
- **Clean Architecture**: Proper separation of concerns with dependency injection
- **State Management**: BLoC pattern for predictable state management
- **API Integration**: RESTful API client with error handling and JWT token management
- **UI/UX Design**: Modern, responsive design system with custom components
- **Navigation**: Type-safe routing with GoRouter
- **Security**: Secure token storage and automatic refresh logic

### 🔄 In Progress

- **Home Screen**: Product search, filters, and promotional content
- **Search Results**: Product listing with advanced filtering
- **Shopping Cart**: Add/remove items, quantity management
- **Orders**: Order history and tracking
- **User Profile**: Account management and settings

## 📱 Core Modules

### 1. Authentication Module

- **Login**: Phone number and password authentication
- **Forgot Password**: OTP-based password reset flow
- **JWT Management**: Automatic token refresh and secure storage
- **Session Management**: Persistent login state

### 2. API Layer

- **Retrofit Integration**: Type-safe API client generation
- **Error Handling**: Comprehensive error management
- **Token Interceptor**: Automatic JWT token attachment
- **Network Monitoring**: Connectivity status tracking

### 3. UI Components

- **Custom Button**: Multiple variants with loading states
- **Custom Text Field**: Form validation and styling
- **Theme System**: Light/dark mode support
- **Responsive Design**: Cross-platform compatibility

## 🛠️ Technology Stack

### Core Dependencies

- **Flutter**: ^3.9.2
- **Dart**: Latest stable

### State Management

- **flutter_bloc**: ^8.1.6 - BLoC pattern implementation
- **equatable**: ^2.0.5 - Value equality

### Networking

- **dio**: ^5.7.0 - HTTP client
- **retrofit**: ^4.4.1 - API client generation
- **json_annotation**: ^4.9.0 - JSON serialization

### Navigation

- **go_router**: ^14.6.2 - Declarative routing

### Storage & Security

- **shared_preferences**: ^2.3.2 - Local preferences
- **flutter_secure_storage**: ^9.2.2 - Secure token storage
- **hive**: ^2.2.3 - Local database

### Dependency Injection

- **get_it**: ^8.0.0 - Service locator
- **injectable**: ^2.5.0 - Code generation

### UI/UX

- **google_fonts**: ^6.2.1 - Typography
- **cached_network_image**: ^3.4.1 - Image caching
- **shimmer**: ^3.0.0 - Loading animations
- **flutter_spinkit**: ^5.2.1 - Loading indicators

### Utilities

- **intl**: ^0.19.0 - Internationalization
- **connectivity_plus**: ^6.1.0 - Network status
- **dartz**: ^0.10.1 - Functional programming

## 📁 Project Structure

```
lib/
├── core/                           # Core functionality
│   ├── constants/                  # App constants
│   ├── errors/                     # Error handling
│   ├── network/                    # API client
│   ├── router/                     # Navigation
│   ├── theme/                      # UI theme
│   ├── utils/                      # Utilities
│   └── widgets/                    # Shared widgets
├── features/                       # Feature modules
│   ├── auth/                       # Authentication
│   │   ├── data/                   # Data layer
│   │   ├── domain/                 # Domain layer
│   │   └── presentation/           # Presentation layer
│   ├── home/                       # Home screen
│   ├── search/                     # Search functionality
│   ├── cart/                       # Shopping cart
│   ├── orders/                     # Order management
│   └── profile/                    # User profile
└── main.dart                       # App entry point
```

## 🔧 Setup & Installation

### Prerequisites

- Flutter SDK (3.9.2 or higher)
- Dart SDK
- Android Studio / VS Code
- Git

### Installation Steps

1. **Clone the repository**

   ```bash
   git clone <repository-url>
   cd truckparts_new
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Generate code**

   ```bash
   flutter packages pub run build_runner build
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

### Code Generation Commands

```bash
# Generate all code
flutter packages pub run build_runner build

# Watch for changes
flutter packages pub run build_runner watch

# Clean and rebuild
flutter packages pub run build_runner build --delete-conflicting-outputs
```

## 🔐 API Configuration

Update the API base URL in `lib/core/constants/app_constants.dart`:

```dart
static const String baseUrl = 'https://your-api-domain.com';
```

## 🎨 Theming

The app supports both light and dark themes. Theme configuration is in `lib/core/theme/app_theme.dart`:

- **Primary Color**: Blue (#2563EB)
- **Secondary Color**: Green (#10B981)
- **Error Color**: Red (#EF4444)
- **Typography**: Inter font family

## 🧪 Testing

### Unit Tests

```bash
flutter test
```

### Integration Tests

```bash
flutter drive --target=test_driver/app.dart
```

## 📱 Platform Support

- ✅ **Android** (API 21+)
- ✅ **iOS** (iOS 11+)
- ✅ **Web** (Modern browsers)
- ✅ **Desktop** (Windows, macOS, Linux)

## 🚀 Deployment

### Android

```bash
flutter build apk --release
flutter build appbundle --release
```

### iOS

```bash
flutter build ios --release
```

### Web

```bash
flutter build web --release
```

## 📋 Development Guidelines

### Code Style

- Follow Dart/Flutter conventions
- Use meaningful variable and function names
- Add comprehensive documentation
- Implement proper error handling

### Architecture Principles

- **Single Responsibility**: Each class has one reason to change
- **Dependency Inversion**: Depend on abstractions, not concretions
- **Interface Segregation**: Use focused interfaces
- **Open/Closed**: Open for extension, closed for modification

### State Management

- Use BLoC for complex state management
- Keep UI components stateless when possible
- Handle loading, success, and error states consistently

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is proprietary software. All rights reserved.

## 📞 Support

For technical support or questions, please contact the development team.

---

**Built with ❤️ using Flutter**

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
