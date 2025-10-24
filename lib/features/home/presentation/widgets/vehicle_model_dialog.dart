import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../home/data/services/parts_service.dart';

class VehicleModelDialog extends StatefulWidget {
  final String selectedVehicleMake;
  final String? selectedVehicleModel;
  final Function(String?) onVehicleModelSelected;
  final VoidCallback? onBackPressed;
  final String? selectedSubCategory;
  final String? selectedSize;

  const VehicleModelDialog({
    super.key,
    required this.selectedVehicleMake,
    required this.selectedVehicleModel,
    required this.onVehicleModelSelected,
    this.onBackPressed,
    this.selectedSubCategory,
    this.selectedSize,
  });

  @override
  State<VehicleModelDialog> createState() => _VehicleModelDialogState();
}

class _VehicleModelDialogState extends State<VehicleModelDialog> {
  String? _selectedVehicleModel;
  List<String> _vehicleModels = [];
  List<String> _filteredVehicleModels = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedVehicleModel = widget.selectedVehicleModel;
    _loadVehicleModels();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVehicleModels() async {
    try {
      // Apply cascading filters
      final models = await PartsService.getVehicleModels(
        vehicleMake: widget.selectedVehicleMake,
        subCategory: widget.selectedSubCategory,
        size: widget.selectedSize,
      );
      setState(() {
        _vehicleModels = models;
        _filteredVehicleModels = models;
        _isLoading = false;
      });

      print('🔍 VehicleModelDialog: Loaded ${models.length} models');
      print('   - For Make: ${widget.selectedVehicleMake}');
      if (widget.selectedSubCategory != null) {
        print('   - Filtered by Part: ${widget.selectedSubCategory}');
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

  void _filterVehicleModels(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredVehicleModels = _vehicleModels;
      } else {
        _filteredVehicleModels = _vehicleModels
            .where((model) => model.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _onVehicleModelSelected(String model) {
    setState(() {
      // Toggle selection: if same model is clicked, deselect it
      if (_selectedVehicleModel == model) {
        _selectedVehicleModel = null;
        print('🔄 Vehicle Model deselected: $model');
      } else {
        _selectedVehicleModel = model;
        print('✅ Vehicle Model selected: $model');
      }
    });
  }

  void _onApply() {
    widget.onVehicleModelSelected(_selectedVehicleModel);
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
      child: GestureDetector(
        onTap: () {
          // Prevent event propagation to underlying widgets
        },
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
                    Icons.car_rental,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select Vehicle Model',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'Make: ${widget.selectedVehicleMake}',
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
                onChanged: _filterVehicleModels,
                decoration: InputDecoration(
                  hintText: 'Search vehicle model...',
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

              // Vehicle Models Table
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryColor,
                        ),
                      )
                    : _filteredVehicleModels.isEmpty
                    ? const Center(
                        child: Text(
                          'No vehicle models found',
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
                                    Icons.car_rental,
                                    color: AppTheme.primaryColor,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Vehicle Model',
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
                                itemCount: _filteredVehicleModels.length,
                                itemBuilder: (context, index) {
                                  final model = _filteredVehicleModels[index];
                                  final isSelected =
                                      _selectedVehicleModel == model;

                                  return Container(
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppTheme.primaryColor.withOpacity(
                                              0.1,
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
                                          color: AppTheme.borderColor
                                              .withOpacity(0.3),
                                        ),
                                      ),
                                    ),
                                    child: ListTile(
                                      title: Text(
                                        model,
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
                                          _onVehicleModelSelected(model),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
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
                    child: GestureDetector(
                      onTap: () {
                        // Prevent event propagation to YouTube video
                        _onCancel();
                      },
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
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        // Prevent event propagation to YouTube video
                        if (_selectedVehicleModel != null) {
                          _onApply();
                        }
                      },
                      child: ElevatedButton(
                        onPressed: _selectedVehicleModel != null
                            ? _onApply
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
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
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
