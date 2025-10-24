import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../home/data/services/parts_service.dart';

class TypeDialog extends StatefulWidget {
  final String? selectedType;
  final Function(String?) onTypeSelected;
  final String? selectedVehicleMake;
  final String? selectedVehicleModel;
  final String? selectedSubCategory;

  const TypeDialog({
    super.key,
    required this.selectedType,
    required this.onTypeSelected,
    this.selectedVehicleMake,
    this.selectedVehicleModel,
    this.selectedSubCategory,
  });

  @override
  State<TypeDialog> createState() => _TypeDialogState();
}

class _TypeDialogState extends State<TypeDialog> {
  String? _selectedType;
  List<String> _types = [];
  List<String> _filteredTypes = [];
  bool _isLoading = true;
  bool _isEmpty = false; // ✅ NEW: Track if types list is empty
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedType = widget.selectedType;
    _loadTypes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTypes() async {
    try {
      // Apply cascading filters
      final types = await PartsService.getTypes(
        vehicleMake: widget.selectedVehicleMake,
        vehicleModel: widget.selectedVehicleModel,
        subCategory: widget.selectedSubCategory,
      );

      setState(() {
        if (types.isEmpty) {
          // ✅ NEW: Handle empty types - show "Any" only
          _isEmpty = true;
          _types = ['Any'];
          _filteredTypes = ['Any'];
          _selectedType = _selectedType ?? 'Any'; // Auto-select "Any"
          print('⚠️ TypeDialog: No types available - showing "Any" option');
        } else {
          _isEmpty = false;
          _types = types;
          _filteredTypes = types;
        }
        _isLoading = false;
      });

      print('🔍 TypeDialog: Loaded ${types.length} types');
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isEmpty = true;
        _types = ['Any'];
        _filteredTypes = ['Any'];
        print('❌ TypeDialog: Error loading types - showing "Any" option');
      });
    }
  }

  void _filterTypes(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredTypes = _types;
      } else {
        _filteredTypes = _types
            .where((type) => type.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _onTypeSelected(String type) {
    setState(() {
      // Toggle selection: if same type is clicked, deselect it
      if (_selectedType == type) {
        _selectedType = null;
        print('🔄 Type deselected: $type');
      } else {
        _selectedType = type;
        print('✅ Type selected: $type');
      }
    });
  }

  void _onNext() {
    // Allow proceeding even without selection (will pass null)
    widget.onTypeSelected(_selectedType);
    Navigator.pop(context, 'next'); // Return 'next' to indicate user proceeded
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
                const Icon(Icons.build, color: AppTheme.primaryColor, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Select Type',
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
              onChanged: _filterTypes,
              decoration: InputDecoration(
                hintText: 'Search types...',
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

            // Types Table
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                      ),
                    )
                  : _filteredTypes.isEmpty
                  ? const Center(
                      child: Text(
                        'No types found',
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
                                  Icons.build,
                                  color: AppTheme.primaryColor,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Type',
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
                              itemCount: _filteredTypes.length,
                              itemBuilder: (context, index) {
                                final type = _filteredTypes[index];
                                final isSelected = _selectedType == type;

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
                                      type,
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
                                    onTap: () => _onTypeSelected(type),
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
                // ✅ NEW: Disable Next button when no selection
                ElevatedButton(
                  onPressed: _selectedType != null ? _onNext : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedType != null
                        ? AppTheme.primaryColor
                        : Colors.grey[400],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: _selectedType != null ? 2 : 0,
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}
