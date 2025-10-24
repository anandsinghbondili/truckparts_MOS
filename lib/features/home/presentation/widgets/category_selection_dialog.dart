import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../home/data/services/parts_service.dart';

class CategorySelectionDialog extends StatefulWidget {
  final String? selectedSubCategory;
  final Function(String?) onSubCategorySelected;
  final String? selectedVehicleMake;
  final String? selectedVehicleModel;
  final String? selectedSize;

  const CategorySelectionDialog({
    super.key,
    required this.selectedSubCategory,
    required this.onSubCategorySelected,
    this.selectedVehicleMake,
    this.selectedVehicleModel,
    this.selectedSize,
  });

  @override
  State<CategorySelectionDialog> createState() =>
      _CategorySelectionDialogState();
}

class _CategorySelectionDialogState extends State<CategorySelectionDialog> {
  String? _selectedSubCategory;
  List<String> _subCategories = [];
  List<String> _filteredSubCategories = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedSubCategory = widget.selectedSubCategory;
    _loadSubCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSubCategories() async {
    try {
      // Apply cascading filters
      final subCategories = await PartsService.getSubCategories(
        vehicleMake: widget.selectedVehicleMake,
        vehicleModel: widget.selectedVehicleModel,
        size: widget.selectedSize,
      );

      setState(() {
        _subCategories = subCategories;
        _filteredSubCategories = subCategories;
        _isLoading = false;
      });

      print('🔍 CategorySelectionDialog: Loaded ${subCategories.length} parts');
      if (widget.selectedVehicleMake != null) {
        print('   - Filtered by Make: ${widget.selectedVehicleMake}');
      }
      if (widget.selectedVehicleModel != null) {
        print('   - Filtered by Model: ${widget.selectedVehicleModel}');
      }
      if (widget.selectedSize != null) {
        print('   - Filtered by Size: ${widget.selectedSize}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterSubCategories(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSubCategories = _subCategories;
      } else {
        _filteredSubCategories = _subCategories
            .where(
              (subCategory) =>
                  subCategory.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  void _onSubCategorySelected(String subCategory) {
    setState(() {
      // Toggle selection: if same part is clicked, deselect it
      if (_selectedSubCategory == subCategory) {
        _selectedSubCategory = null;
        print('🔄 Part deselected: $subCategory');
      } else {
        _selectedSubCategory = subCategory;
        print('✅ Part selected: $subCategory');
      }
    });
  }

  void _onApply() {
    widget.onSubCategorySelected(_selectedSubCategory);
    Navigator.pop(context, 'apply'); // Return 'apply' to indicate user applied
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
                  Icons.inventory_2,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Select Part',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Search Field
            TextField(
              controller: _searchController,
              onChanged: _filterSubCategories,
              decoration: InputDecoration(
                hintText: 'Search parts...',
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

            // Parts Table
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                      ),
                    )
                  : _filteredSubCategories.isEmpty
                  ? const Center(
                      child: Text(
                        'No parts found',
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
                                  Icons.inventory_2,
                                  color: AppTheme.primaryColor,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Part',
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
                              itemCount: _filteredSubCategories.length,
                              itemBuilder: (context, index) {
                                final subCategory =
                                    _filteredSubCategories[index];
                                final isSelected =
                                    _selectedSubCategory == subCategory;

                                return Container(
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppTheme.primaryColor.withValues(
                                            alpha: 0.1,
                                          )
                                        : Colors.transparent,
                                    border: Border(
                                      left: isSelected
                                          ? BorderSide(
                                              color: AppTheme.primaryColor,
                                              width: 3,
                                            )
                                          : BorderSide.none,
                                      bottom: BorderSide(
                                        color: AppTheme.borderColor.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                  ),
                                  child: ListTile(
                                    title: Text(
                                      subCategory,
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
                                    onTap: () =>
                                        _onSubCategorySelected(subCategory),
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
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _onCancel,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _selectedSubCategory != null ? _onApply : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Apply',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
