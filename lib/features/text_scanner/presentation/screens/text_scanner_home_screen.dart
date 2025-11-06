import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import '../bloc/text_scanner_bloc.dart';
import '../bloc/text_scanner_event.dart';
import '../bloc/text_scanner_state.dart';
import '../widgets/loading_overlay.dart';
import '../../../home/presentation/widgets/home_drawer.dart';
import '../../../../core/router/app_router.dart';
import '../../../home/data/services/item_details_by_customer_service.dart';
import '../../../home/data/services/parts_data_service.dart';

class TextScannerHomeScreen extends StatelessWidget {
  const TextScannerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Truck Parts - MOS',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_outlined),
            iconSize: 24,
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        // DISABLED: Refresh button hidden from header
        // TODO: Re-enable refresh button when needed
        // actions: [
        //   Padding(
        //     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        //     child: IconButton(
        //       onPressed: () => _refreshParts(context),
        //       icon: const Icon(Icons.refresh, size: 24),
        //       tooltip: 'Refresh Parts Database',
        //       style: IconButton.styleFrom(
        //         backgroundColor: Colors.white.withOpacity(0.2),
        //         foregroundColor: Colors.white,
        //         shape: RoundedRectangleBorder(
        //           borderRadius: BorderRadius.circular(8),
        //         ),
        //       ),
        //     ),
        //   ),
        // ],
      ),
      drawer: HomeDrawer(onLogoutPressed: () => _showLogoutDialog(context)),
      body: BlocConsumer<TextScannerBloc, TextScannerState>(
        listener: (context, state) {
          if (state is TextScannerSuccess) {
            context.push('/text-result', extra: state.recognizedText);
          } else if (state is TextScannerError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          } else if (state is TextScannerPermissionDenied) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
                action: SnackBarAction(
                  label: 'Settings',
                  onPressed: () {
                    // Open app settings
                  },
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is TextScannerLoading) {
            return const LoadingOverlay(
              message: 'Processing image...',
              child: _HomeContent(),
            );
          }

          return const _HomeContent();
        },
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              // DISABLED: Login disabled, go to home
              // TODO: Re-enable login redirect when authentication is needed
              // context.go(AppRouter.login);
              context.go(AppRouter.home);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  // DISABLED: Refresh button hidden, method preserved for future use
  // TODO: Re-enable when refresh button is needed
  // ignore: unused_element
  Future<void> _refreshParts(BuildContext context) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => const AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Refreshing parts database...'),
            ],
          ),
        ),
      );

      // Get services from GetIt
      final itemDetailsService = GetIt.instance<ItemDetailsByCustomerService>();
      final partsDataService = GetIt.instance<PartsDataService>();

      print('');
      print(
        '╔════════════════════════════════════════════════════════════════╗',
      );
      print(
        '║  🔄 TEXT SCANNER: Refreshing Parts from API                     ║',
      );
      print(
        '╚════════════════════════════════════════════════════════════════╝',
      );

      final refreshStartTime = DateTime.now();
      print('🔄 REFRESH STARTED at: ${refreshStartTime.toIso8601String()}');
      print('');

      final apiStartTime = DateTime.now();
      print('🌐 Calling ItemDetailsbyCustomer API...');

      final items = await itemDetailsService.getItemsByCustomer();

      final apiEndTime = DateTime.now();
      final apiDuration = apiEndTime.difference(apiStartTime);
      print('📥 API Response received in ${apiDuration.inMilliseconds}ms');

      if (items.isNotEmpty) {
        partsDataService.storeParts(items);
        print('✅ Stored ${items.length} items in PartsDataService');
      }

      final refreshEndTime = DateTime.now();
      final totalDuration = refreshEndTime.difference(refreshStartTime);

      print('');
      print('=' * 70);
      print('✅ REFRESH COMPLETED SUCCESSFULLY!');
      print('   - Total items: ${items.length}');
      print(
        '   - API call time: ${apiDuration.inMilliseconds}ms (${(apiDuration.inMilliseconds / 1000).toStringAsFixed(2)}s)',
      );
      print(
        '   - Total refresh time: ${totalDuration.inMilliseconds}ms (${(totalDuration.inMilliseconds / 1000).toStringAsFixed(2)}s)',
      );
      print('=' * 70);
      print('✅ REFRESH ENDED at: ${refreshEndTime.toIso8601String()}');
      print('');

      // Close loading dialog
      Navigator.of(context).pop();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Refreshed ${items.length} parts from API'),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();

      print('');
      print('=' * 70);
      print('❌ REFRESH FAILED: $e');
      print('=' * 70);
      print('');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text('Failed to refresh parts: ${e.toString()}'),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // Hero Section with Enhanced Design
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.1),
                  Theme.of(context).colorScheme.secondary.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).primaryColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                // Enhanced Icon with Animation
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner,
                    size: 35,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 16),

                // Enhanced Title
                Text(
                  'Scan Parts',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                // Enhanced Description
                Text(
                  'Quickly identify truck parts and components using advanced ML technology',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.8),
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Quick Stats Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  'Fast',
                  'Instant recognition',
                  Icons.speed,
                  Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  'Accurate',
                  'High precision',
                  Icons.verified,
                  Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Enhanced Action Buttons
          Column(
            children: [
              // Primary Action - Camera
              Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.read<TextScannerBloc>().add(CaptureImageEvent());
                  },
                  icon: const Icon(Icons.camera_alt, size: 22),
                  label: const Text(
                    'Take Photo',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Secondary Action - Gallery
              Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.secondary,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.read<TextScannerBloc>().add(PickImageEvent());
                  },
                  icon: Icon(
                    Icons.photo_library,
                    size: 22,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  label: Text(
                    'Choose from Gallery',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Tips Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Theme.of(context).colorScheme.secondary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Scanning Tips',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildTipItem(
                  context,
                  'Ensure good lighting for better recognition',
                ),
                _buildTipItem(context, 'Keep the part number clearly visible'),
                _buildTipItem(context, 'Hold the camera steady while scanning'),
              ],
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
              fontSize: 12,
            ),
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.only(top: 8, right: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
