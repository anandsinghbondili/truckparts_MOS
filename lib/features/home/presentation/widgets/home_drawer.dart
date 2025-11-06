import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/router/app_router.dart';

class HomeDrawer extends StatefulWidget {
  final VoidCallback onLogoutPressed;

  const HomeDrawer({super.key, required this.onLogoutPressed});

  @override
  State<HomeDrawer> createState() => _HomeDrawerState();
}

class _HomeDrawerState extends State<HomeDrawer> {
  String _appVersion = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = 'v${packageInfo.version} (${packageInfo.buildNumber})';
      });
    } catch (e) {
      // ✅ NEW: Show clear error message instead of empty string
      setState(() {
        _appVersion = 'Version unavailable';
      });
      print('❌ Error loading app version: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppTheme.primaryColor),
            child: Center(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: Image.asset(
                  'assets/logos/truckparts_logo.png',
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: 100,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(
              Icons.home_outlined,
              color: AppTheme.primaryColor,
            ),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
              context.go(AppRouter.home);
            },
          ),
          // DISABLED: All other menu options hidden - only Home is visible
          // TODO: Re-enable menu options when needed
          // const Divider(height: 1, indent: 16, endIndent: 16),
          // ListTile(
          //   leading: const Icon(
          //     Icons.inventory_2_outlined,
          //     color: AppTheme.primaryColor,
          //   ),
          //   title: const Text('All Parts'),
          //   onTap: () {
          //     Navigator.pop(context);
          //     context.push(AppRouter.items);
          //   },
          // ),
          // const Divider(height: 1, indent: 16, endIndent: 16),
          // ListTile(
          //   leading: const Icon(
          //     Icons.shopping_cart_outlined,
          //     color: AppTheme.primaryColor,
          //   ),
          //   title: const Text('Cart'),
          //   onTap: () {
          //     Navigator.pop(context);
          //     context.go(AppRouter.cart);
          //   },
          // ),
          // const Divider(height: 1, indent: 16, endIndent: 16),
          // ListTile(
          //   leading: const Icon(
          //     Icons.receipt_long_outlined,
          //     color: AppTheme.primaryColor,
          //   ),
          //   title: const Text('My Orders'),
          //   onTap: () {
          //     Navigator.pop(context);
          //     context.go(AppRouter.orders);
          //   },
          // ),
          // const Divider(height: 1, indent: 16, endIndent: 16),
          // ListTile(
          //   leading: const Icon(
          //     Icons.account_balance_outlined,
          //     color: AppTheme.primaryColor,
          //   ),
          //   title: const Text('Account Summary'),
          //   onTap: () {
          //     Navigator.pop(context);
          //     // Navigate to account summary (placeholder for now)
          //     ScaffoldMessenger.of(context).showSnackBar(
          //       const SnackBar(
          //         content: Text('Account Summary - Coming Soon'),
          //         duration: Duration(seconds: 2),
          //       ),
          //     );
          //   },
          // ),
          // const Divider(height: 1, indent: 16, endIndent: 16),
          // ListTile(
          //   leading: const Icon(
          //     Icons.person_outlined,
          //     color: AppTheme.primaryColor,
          //   ),
          //   title: const Text('My Profile'),
          //   onTap: () {
          //     Navigator.pop(context);
          //     context.go(AppRouter.profile);
          //   },
          // ),
          // const Divider(height: 1, indent: 16, endIndent: 16),
          // ListTile(
          //   leading: const Icon(
          //     Icons.contact_support_outlined,
          //     color: AppTheme.primaryColor,
          //   ),
          //   title: const Text('Contact Us'),
          //   onTap: () {
          //     Navigator.pop(context);
          //     context.push(AppRouter.contactUs);
          //   },
          // ),
          // const Divider(height: 16, thickness: 2, indent: 16, endIndent: 16),
          // const SizedBox(height: 8),
          // ListTile(
          //   leading: const Icon(
          //     Icons.logout_outlined,
          //     color: AppTheme.errorColor,
          //   ),
          //   title: const Text(
          //     'Logout',
          //     style: TextStyle(color: AppTheme.errorColor),
          //   ),
          //   onTap: () {
          //     Navigator.pop(context);
          //     widget.onLogoutPressed();
          //   },
          // ),
          // const Divider(height: 1, indent: 16, endIndent: 16),
          // App Version Display
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppTheme.textSecondary.withOpacity(0.7),
                ),
                const SizedBox(width: 8),
                Text(
                  _appVersion,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary.withOpacity(0.7),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
