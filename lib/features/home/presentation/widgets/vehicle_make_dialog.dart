import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../home/data/services/parts_service.dart';

class VehicleMakeDialog extends StatefulWidget {
  final String? selectedVehicleMake;
  final Function(String?) onVehicleMakeSelected;
  final String? selectedSubCategory;
  final String? selectedSize;

  const VehicleMakeDialog({
    super.key,
    required this.selectedVehicleMake,
    required this.onVehicleMakeSelected,
    this.selectedSubCategory,
    this.selectedSize,
  });

  @override
  State<VehicleMakeDialog> createState() => _VehicleMakeDialogState();
}

class _VehicleMakeDialogState extends State<VehicleMakeDialog> {
  String? _selectedVehicleMake;
  List<String> _vehicleMakes = [];
  List<String> _filteredVehicleMakes = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedVehicleMake = widget.selectedVehicleMake;
    _loadVehicleMakes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVehicleMakes() async {
    try {
      // Apply cascading filters
      final makes = await PartsService.getVehicleMakes(
        subCategory: widget.selectedSubCategory,
        size: widget.selectedSize,
      );
      setState(() {
        _vehicleMakes = makes;
        _filteredVehicleMakes = makes;
        _isLoading = false;
      });

      print('🔍 VehicleMakeDialog: Loaded ${makes.length} makes');
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

  void _filterVehicleMakes(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredVehicleMakes = _vehicleMakes;
      } else {
        _filteredVehicleMakes = _vehicleMakes
            .where((make) => make.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _onVehicleMakeSelected(String make) {
    setState(() {
      // Toggle selection: if same make is clicked, deselect it
      if (_selectedVehicleMake == make) {
        _selectedVehicleMake = null;
        print('🔄 Vehicle Make deselected: $make');
      } else {
        _selectedVehicleMake = make;
        print('✅ Vehicle Make selected: $make');
      }
    });
  }

  void _onNext() {
    if (_selectedVehicleMake != null) {
      widget.onVehicleMakeSelected(_selectedVehicleMake);
      Navigator.pop(
        context,
        'next',
      ); // Return 'next' to indicate user proceeded
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

    return WillPopScope(
      onWillPop: () async => true, // Allow ESC key to close dialog
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Material(
          type: MaterialType.card,
          borderRadius: BorderRadius.circular(16),
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
                        Icons.directions_car,
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Select Vehicle Make',
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
                    onChanged: _filterVehicleMakes,
                    decoration: InputDecoration(
                      hintText: 'Search vehicle make...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppTheme.borderColor,
                        ),
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

                  // Vehicle Makes Table
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.primaryColor,
                            ),
                          )
                        : _filteredVehicleMakes.isEmpty
                        ? const Center(
                            child: Text(
                              'No vehicle makes found',
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
                                        Icons.directions_car,
                                        color: AppTheme.primaryColor,
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Vehicle Make',
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
                                    itemCount: _filteredVehicleMakes.length,
                                    itemBuilder: (context, index) {
                                      final make = _filteredVehicleMakes[index];
                                      final isSelected =
                                          _selectedVehicleMake == make;

                                      return Container(
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppTheme.primaryColor
                                                    .withOpacity(0.1)
                                              : Colors.transparent,
                                          border: Border(
                                            left: isSelected
                                                ? BorderSide(
                                                    color:
                                                        AppTheme.primaryColor,
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
                                            make,
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
                                              _onVehicleMakeSelected(make),
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
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () {
                          // Prevent event propagation to YouTube video
                          _onCancel();
                        },
                        child: TextButton(
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
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          // Prevent event propagation to YouTube video
                          if (_selectedVehicleMake != null) {
                            _onNext();
                          }
                        },
                        child: ElevatedButton(
                          onPressed: _selectedVehicleMake != null
                              ? _onNext
                              : null,
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
                              Text(
                                'Next',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 6),
                              Icon(Icons.arrow_forward, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
