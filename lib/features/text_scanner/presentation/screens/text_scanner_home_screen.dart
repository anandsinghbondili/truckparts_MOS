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
import '../../data/services/text_match_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../home/domain/entities/part.dart';
import '../../../home/data/models/part_model.dart';

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

class _HomeContent extends StatefulWidget {
  const _HomeContent();

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  final TextEditingController _searchController = TextEditingController();
  final TextMatchService _searchService = TextMatchService();
  bool _isSearching = false;
  OverlayEntry? _overlayEntry;
  final GlobalKey _searchFieldKey = GlobalKey();

  @override
  void dispose() {
    _searchController.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Future<void> _onSearchChanged(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _isSearching = false;
      });
      _removeOverlay();
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final results = await _searchService.searchParts(query);

    if (mounted) {
      setState(() {
        _isSearching = false;
      });

      if (results.isNotEmpty) {
        _showSearchDropdown(context, results);
      } else {
        _removeOverlay();
      }
    }
  }

  void _showSearchDropdown(
    BuildContext context,
    List<Map<String, dynamic>> results,
  ) {
    _removeOverlay();

    // Get the position of the search field using GlobalKey
    final RenderBox? searchFieldBox =
        _searchFieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (searchFieldBox == null) return;

    final searchFieldSize = searchFieldBox.size;
    final searchFieldOffset = searchFieldBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: searchFieldOffset.dx, // Same left position as search field
        top:
            searchFieldOffset.dy +
            searchFieldSize.height +
            4, // Just below search field with 4px gap
        width: searchFieldSize.width, // Same width as search field
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 300),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: results.length,
              itemBuilder: (context, index) {
                final part = results[index];
                final itemname = part['itemname']?.toString() ?? '';
                return ListTile(
                  title: Text(
                    itemname,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: part['itemdesc'] != null
                      ? Text(part['itemdesc'].toString())
                      : null,
                  onTap: () {
                    _onPartSelected(context, part);
                  },
                );
              },
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _onPartSelected(BuildContext context, Map<String, dynamic> partData) {
    _searchController.clear();
    _removeOverlay();

    try {
      final part = PartModel.fromApiJson(partData);
      _showItemDetailsDialog(context, part);
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(
          context,
          message: 'Unable to display item details',
        );
      }
    }
  }

  void _showItemDetailsDialog(BuildContext context, Part part) {
    showDialog(
      context: context,
      builder: (context) => _ItemDetailsDialog(
        part: part,
        onAddToCart: (part, quantity) {
          // Only show message, no API functionality
          if (mounted) {
            SnackBarUtils.showSuccess(
              context,
              message: 'Part: ${part.item} (Qty: $quantity) added to cart',
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // Global Search Field
          Container(
            key: _searchFieldKey,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by part/item number...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _removeOverlay();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              onChanged: _onSearchChanged,
            ),
          ),

          // OR Text
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Divider(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withOpacity(0.3),
                    thickness: 1,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'OR',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withOpacity(0.3),
                    thickness: 1,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

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

/// Item Details Dialog for search results
class _ItemDetailsDialog extends StatefulWidget {
  final Part part;
  final Function(Part, int) onAddToCart;

  const _ItemDetailsDialog({required this.part, required this.onAddToCart});

  @override
  State<_ItemDetailsDialog> createState() => _ItemDetailsDialogState();
}

class _ItemDetailsDialogState extends State<_ItemDetailsDialog> {
  int _quantity = 1;
  late TextEditingController _quantityController;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: _quantity.toString());
    _focusNode = FocusNode();

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        final int? parsedQuantity = int.tryParse(_quantityController.text);
        if (parsedQuantity != null &&
            parsedQuantity >= 1 &&
            parsedQuantity <= 999) {
          _updateQuantity(parsedQuantity);
        } else {
          _quantityController.text = _quantity.toString();
        }
      }
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _updateQuantity(int newQuantity) {
    if (newQuantity >= 1 && newQuantity <= 999) {
      setState(() {
        _quantity = newQuantity;
        _quantityController.text = _quantity.toString();
      });
    }
  }

  void _updateQuantityByDelta(int delta) {
    final newQuantity = (_quantity + delta).clamp(1, 999);
    _updateQuantity(newQuantity);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Item Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: double.infinity,
                        height: 100,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: Image.asset(
                          'assets/logos/shortform.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildInfoRow('Part Number', widget.part.item),
                    if (widget.part.description.isNotEmpty)
                      _buildInfoRow('Description', widget.part.description),
                    if (widget.part.brand.isNotEmpty)
                      _buildInfoRow('Brand', widget.part.brand),
                    if (widget.part.vehicleMake.isNotEmpty)
                      _buildInfoRow('Vehicle Make', widget.part.vehicleMake),
                    if (widget.part.model.isNotEmpty)
                      _buildInfoRow('Vehicle Model', widget.part.model),
                    if (widget.part.category.isNotEmpty)
                      _buildInfoRow('Category', widget.part.category),
                    if (widget.part.subCategory.isNotEmpty)
                      _buildInfoRow('Sub Category', widget.part.subCategory),
                    if (widget.part.type.isNotEmpty)
                      _buildInfoRow('Type', widget.part.type),
                    if (widget.part.size.isNotEmpty)
                      _buildInfoRow('Size', widget.part.size),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                border: Border(top: BorderSide(color: AppTheme.borderColor)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Quantity',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              height: 40,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppTheme.borderColor,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _quantity > 1
                                          ? () => _updateQuantityByDelta(-1)
                                          : null,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(7),
                                        bottomLeft: Radius.circular(7),
                                      ),
                                      child: Container(
                                        width: 36,
                                        height: 40,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: _quantity > 1
                                              ? AppTheme.primaryColor
                                                    .withOpacity(0.05)
                                              : Colors.grey.withOpacity(0.05),
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(7),
                                            bottomLeft: Radius.circular(7),
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.remove,
                                          size: 16,
                                          color: _quantity > 1
                                              ? AppTheme.primaryColor
                                              : AppTheme.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 50,
                                    height: 40,
                                    child: TextField(
                                      controller: _quantityController,
                                      focusNode: _focusNode,
                                      textAlign: TextAlign.center,
                                      keyboardType: TextInputType.number,
                                      textInputAction: TextInputAction.done,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                      ),
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(
                                          borderSide: BorderSide.none,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide.none,
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide.none,
                                        ),
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      onSubmitted: (value) {
                                        final int? parsedQuantity =
                                            int.tryParse(value);
                                        if (parsedQuantity != null &&
                                            parsedQuantity >= 1 &&
                                            parsedQuantity <= 999) {
                                          _updateQuantity(parsedQuantity);
                                        } else {
                                          _quantityController.text = _quantity
                                              .toString();
                                        }
                                        _focusNode.unfocus();
                                      },
                                      onTap: () {
                                        _quantityController
                                            .selection = TextSelection(
                                          baseOffset: 0,
                                          extentOffset:
                                              _quantityController.text.length,
                                        );
                                      },
                                    ),
                                  ),
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => _updateQuantityByDelta(1),
                                      borderRadius: const BorderRadius.only(
                                        topRight: Radius.circular(7),
                                        bottomRight: Radius.circular(7),
                                      ),
                                      child: Container(
                                        width: 36,
                                        height: 40,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor
                                              .withOpacity(0.05),
                                          borderRadius: const BorderRadius.only(
                                            topRight: Radius.circular(7),
                                            bottomRight: Radius.circular(7),
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.add,
                                          size: 16,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (widget.part.mrp != null)
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'MRP',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                PriceFormatter.formatPriceWithCurrency(
                                  widget.part.mrp,
                                ),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Net Price',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                PriceFormatter.formatPriceWithCurrency(
                                  widget.part.netPrice ?? widget.part.mrp,
                                ),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF00A000),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.errorColor,
                            side: BorderSide(color: AppTheme.errorColor),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.close_outlined, size: 18),
                              SizedBox(width: 6),
                              Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: ElevatedButton(
                          onPressed: () {
                            widget.onAddToCart(widget.part, _quantity);
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.shopping_cart_outlined, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Add to Cart',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
