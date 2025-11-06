import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/navigation_utils.dart';
import '../../../../core/services/app_context_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AppContextService _appContext = GetIt.instance<AppContextService>();

  // Employee data from GetEmpLogin API
  String get employeeName => _appContext.empName;
  String get employeeMobile => _appContext.userId;

  // Customer data from CustomerData API
  String get customerName {
    final customerData = _appContext.customerData;
    if (customerData != null) {
      final parameters = customerData['parameters'];
      if (parameters is List && parameters.isNotEmpty) {
        final firstItem = parameters.first;
        if (firstItem is Map) {
          return firstItem['name']?.toString() ??
              firstItem['Name']?.toString() ??
              firstItem['customername']?.toString() ??
              firstItem['CustomerName']?.toString() ??
              'Not available';
        }
      }
    }
    return 'Not available';
  }

  String get customerMobile {
    final customerData = _appContext.customerData;
    if (customerData != null) {
      final parameters = customerData['parameters'];
      if (parameters is List && parameters.isNotEmpty) {
        final firstItem = parameters.first;
        if (firstItem is Map) {
          return firstItem['mobile']?.toString() ??
              firstItem['Mobile']?.toString() ??
              firstItem['contactno']?.toString() ??
              firstItem['ContactNo']?.toString() ??
              'Not available';
        }
      }
    }
    return 'Not available';
  }

  // Company address from GetAddress API
  Map<String, String> get companyAddress {
    final address = _appContext.customerAddress;
    if (address == null) return {};

    // Helper function to extract address fields from a map
    Map<String, String> extractAddressFields(Map addressMap) {
      return {
        'address': addressMap['Address']?.toString() ?? '',
        'address1': addressMap['Address1']?.toString() ?? '',
        'address2': addressMap['Address2']?.toString() ?? '',
        'city': addressMap['City']?.toString() ?? '',
        'state': addressMap['State']?.toString() ?? '',
        'zip': addressMap['Zip']?.toString() ?? '',
      };
    }

    // Try 1: Check if address fields are directly in the response root
    if (address.containsKey('Address') || address.containsKey('address')) {
      return extractAddressFields(address);
    }

    // Try 2: Check for parameters field (could be List or Map)
    final parameters = address['parameters'] ?? address['Parameters'];

    if (parameters != null) {
      // If parameters is a List, get the first item
      if (parameters is List && parameters.isNotEmpty) {
        final firstAddress = parameters.first;
        if (firstAddress is Map) {
          return extractAddressFields(firstAddress);
        }
      }

      // If parameters is a Map, extract directly
      if (parameters is Map) {
        return extractAddressFields(parameters);
      }
    }

    // Try 3: Check for data/result fields
    final data = address['data'] ?? address['Data'];
    if (data is Map) {
      return extractAddressFields(data);
    }

    final result = address['result'] ?? address['Result'];
    if (result is Map) {
      return extractAddressFields(result);
    }

    return {};
  }

  String get formattedAddress {
    final addr = companyAddress;
    final parts = <String>[];

    if (addr['address']?.isNotEmpty == true) parts.add(addr['address']!);
    if (addr['address1']?.isNotEmpty == true) parts.add(addr['address1']!);
    if (addr['address2']?.isNotEmpty == true) parts.add(addr['address2']!);
    if (addr['city']?.isNotEmpty == true) parts.add(addr['city']!);
    if (addr['state']?.isNotEmpty == true) parts.add(addr['state']!);
    if (addr['zip']?.isNotEmpty == true) parts.add(addr['zip']!);

    return parts.isEmpty ? 'Not available' : parts.join(', ');
  }

  @override
  void initState() {
    super.initState();
    _logProfileData();
  }

  void _logProfileData() {
    print('');
    print('╔════════════════════════════════════════════════════════════════╗');
    print('║                    PROFILE PAGE DATA                           ║');
    print('╚════════════════════════════════════════════════════════════════╝');
    print('');
    print('📋 Employee Information (from GetEmpLogin API):');
    print('   - Name: $employeeName');
    print('   - Mobile: $employeeMobile');
    print('');
    print('📋 Customer Information (from CustomerData API):');
    print('   - Customer Name: $customerName');
    print('   - Customer Mobile: $customerMobile');
    print('');
    print('📋 Company Address (from GetAddress API):');

    // Debug: Show raw address data structure
    final rawAddress = _appContext.customerAddress;
    if (rawAddress != null) {
      print('   - Raw address keys: ${rawAddress.keys.join(", ")}');
      final params = rawAddress['parameters'] ?? rawAddress['Parameters'];
      print('   - Parameters type: ${params.runtimeType}');
      if (params is List && params.isNotEmpty) {
        print('   - Parameters count: ${params.length}');
        print(
          '   - First item keys: ${params.first is Map ? (params.first as Map).keys.join(", ") : "N/A"}',
        );
      }
    } else {
      print('   - ⚠️ No address data stored in AppContext');
    }

    final addr = companyAddress;
    print('');
    print('   📍 Extracted Address Fields:');
    print('      - Address: ${addr['address']}');
    print('      - Address1: ${addr['address1']}');
    print('      - Address2: ${addr['address2']}');
    print('      - City: ${addr['city']}');
    print('      - State: ${addr['state']}');
    print('      - Zip: ${addr['zip']}');
    print('      - Formatted: $formattedAddress');
    print('');
    print(
      '═══════════════════════════════════════════════════════════════════',
    );
    print('');
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
          onPressed: () =>
              NavigationUtils.safePop(context, fallbackRoute: AppRouter.home),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person, size: 24),
            const SizedBox(width: 8),
            const Text('My Profile'),
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(),
            _buildUserInfo(),
            _buildLogoutButton(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryVariant],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.person_outlined,
              size: 40,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            employeeName.isNotEmpty ? employeeName : 'User',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Employee Information Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.badge_outlined,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'My Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    icon: Icons.person_outline,
                    label: 'Name',
                    value: employeeName.isNotEmpty
                        ? employeeName
                        : 'Not available',
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1),
                  ),
                  _buildInfoRow(
                    icon: Icons.phone_outlined,
                    label: 'Mobile',
                    value: employeeMobile.isNotEmpty
                        ? employeeMobile
                        : 'Not available',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Customer Information Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.business_outlined,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'My Business Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    icon: Icons.store_outlined,
                    label: 'Business Name',
                    value: customerName,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1),
                  ),
                  _buildInfoRow(
                    icon: Icons.phone_outlined,
                    label: 'Business Mobile',
                    value: customerMobile,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Company Address Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'My Business Address',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildAddressInfo(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressInfo() {
    final addr = companyAddress;

    if (addr.isEmpty || addr.values.every((v) => v.isEmpty)) {
      return const Text(
        'No address available',
        style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (addr['address']?.isNotEmpty == true)
          _buildAddressLine(addr['address']!),
        if (addr['address1']?.isNotEmpty == true)
          _buildAddressLine(addr['address1']!),
        if (addr['address2']?.isNotEmpty == true)
          _buildAddressLine(addr['address2']!),
        if (addr['city']?.isNotEmpty == true ||
            addr['state']?.isNotEmpty == true)
          _buildAddressLine(
            [
              addr['city'],
              addr['state'],
            ].where((s) => s?.isNotEmpty == true).join(', '),
          ),
        if (addr['zip']?.isNotEmpty == true)
          _buildAddressLine('PIN: ${addr['zip']}'),
      ],
    );
  }

  Widget _buildAddressLine(String line) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        line,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _showLogoutDialog(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.errorColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_outlined, size: 20),
              SizedBox(width: 8),
              Text(
                'Logout',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.textSecondary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text(
          'Are you sure you want to logout? This will end your current session.',
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.pop();
              context.go(AppRouter.home); // DISABLED: Login disabled, go to home
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
