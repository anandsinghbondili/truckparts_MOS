import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../home/data/services/parts_service.dart';

class SizeSelectionDialog extends StatefulWidget {
  final String? selectedType; // Can be null if user skips Type selection
  final String? selectedSize;
  final Function(String?) onSizeSelected;
  final VoidCallback? onBackPressed;
  final String? selectedVehicleMake;
  final String? selectedVehicleModel;
  final String? selectedSubCategory;

  const SizeSelectionDialog({
    super.key,
    this.selectedType, // Optional - user can select Size without Type
    required this.selectedSize,
    required this.onSizeSelected,
    this.onBackPressed,
    this.selectedVehicleMake,
    this.selectedVehicleModel,
    this.selectedSubCategory,
  });

  @override
  State<SizeSelectionDialog> createState() => _SizeSelectionDialogState();
}

class _SizeSelectionDialogState extends State<SizeSelectionDialog> {
  String? _selectedSize;
  List<String> _sizes = [];
  List<String> _filteredSizes = [];
  bool _isLoading = true;
  bool _isEmpty = false; // ✅ NEW: Track if sizes list is empty
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedSize = widget.selectedSize;
    _loadSizes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSizes() async {
    try {
      // Apply cascading filters
      final sizes = await PartsService.getSizes(
        vehicleMake: widget.selectedVehicleMake,
        vehicleModel: widget.selectedVehicleModel,
        subCategory: widget.selectedSubCategory,
        type: widget.selectedType,
      );

      setState(() {
        if (sizes.isEmpty) {
          // ✅ NEW: Handle empty sizes - show "Any" only
          _isEmpty = true;
          _sizes = ['Any'];
          _filteredSizes = ['Any'];
          _selectedSize = _selectedSize ?? 'Any'; // Auto-select "Any"
          print(
            '⚠️ SizeSelectionDialog: No sizes available - showing "Any" option',
          );
        } else {
          _isEmpty = false;
          _sizes = sizes;
          _filteredSizes = sizes;
        }
        _isLoading = false;
      });

      print('🔍 SizeSelectionDialog: Loaded ${sizes.length} sizes');
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isEmpty = true;
        _sizes = ['Any'];
        _filteredSizes = ['Any'];
        print(
          '❌ SizeSelectionDialog: Error loading sizes - showing "Any" option',
        );
      });
    }
  }

  void _filterSizes(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSizes = _sizes;
      } else {
        _filteredSizes = _sizes
            .where((size) => size.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _onSizeSelected(String size) {
    setState(() {
      // Toggle selection: if same size is clicked, deselect it
      if (_selectedSize == size) {
        _selectedSize = null;
        print('🔄 Size deselected: $size');
      } else {
        _selectedSize = size;
        print('✅ Size selected: $size');
      }
    });
  }

  void _onApply() {
    widget.onSizeSelected(_selectedSize);
    Navigator.pop(context);
  }

  void _onBack() {
    if (widget.onBackPressed != null) {
      widget.onBackPressed!();
    } else {
      Navigator.pop(context);
    }
  }

  void _onCancel() {
    Navigator.pop(context, 'cancel'); // Return 'cancel' to stop the flow
  }

  @override
  Widget build(BuildContext context) {
    // Responsive sizing - 80% width, 70% height
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = screenSize.width * 0.8;
    final dialogHeight = screenSize.height * 0.7;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(
                  Icons.straighten,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Size',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        widget.selectedType != null
                            ? 'Type: ${widget.selectedType}'
                            : 'Type: Not selected',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Search Field
            TextField(
              controller: _searchController,
              onChanged: _filterSizes,
              decoration: InputDecoration(
                hintText: 'Search sizes...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppTheme.primaryColor,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Sizes Table
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                      ),
                    )
                  : _filteredSizes.isEmpty
                  ? const Center(
                      child: Text(
                        'No sizes found',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.borderColor),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          // Table Header
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: const BoxDecoration(
                              color: AppTheme.backgroundColor,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.straighten,
                                  color: AppTheme.primaryColor,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Size',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Table Body
                          Expanded(
                            child: ListView.builder(
                              itemCount: _filteredSizes.length,
                              itemBuilder: (context, index) {
                                final size = _filteredSizes[index];
                                final isSelected = _selectedSize == size;

                                return Container(
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppTheme.primaryColor.withOpacity(0.1)
                                        : Colors.transparent,
                                    border: Border(
                                      left: isSelected
                                          ? BorderSide(
                                              color: AppTheme.primaryColor,
                                              width: 3,
                                            )
                                          : BorderSide.none,
                                      bottom: BorderSide(
                                        color: AppTheme.borderColor.withOpacity(
                                          0.3,
                                        ),
                                      ),
                                    ),
                                  ),
                                  child: ListTile(
                                    title: Text(
                                      size,
                                      style: TextStyle(
                                        color: isSelected
                                            ? AppTheme.primaryColor
                                            : Colors.black,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                        fontSize: 14,
                                        height: 1.2,
                                      ),
                                    ),
                                    trailing: isSelected
                                        ? const Icon(
                                            Icons.check_circle,
                                            color: AppTheme.primaryColor,
                                            size: 20,
                                          )
                                        : null,
                                    onTap: () => _onSizeSelected(size),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 2,
                                    ),
                                    dense: true,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
            ),

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _onBack,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Back',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton(
                    onPressed: _onCancel,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  // ✅ NEW: Disable Apply button when no selection
                  child: ElevatedButton(
                    onPressed: _selectedSize != null ? _onApply : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedSize != null
                          ? AppTheme.primaryColor
                          : Colors.grey[400],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: _selectedSize != null ? 2 : 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Apply',
                          style: TextStyle(
                            fontSize: 13,
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
    );
  }
}
