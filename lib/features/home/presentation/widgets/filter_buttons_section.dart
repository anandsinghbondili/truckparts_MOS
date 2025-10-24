import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class FilterButtonsSection extends StatelessWidget {
  final String? selectedVehicleMake;
  final String? selectedVehicleModel;
  final String? selectedSubCategory;
  final String? selectedType;
  final String? selectedSize;
  final VoidCallback onVehicleSelected;
  final VoidCallback onCategorySelected;
  final VoidCallback onSizeSelected;
  final VoidCallback? onSearch;
  final VoidCallback? onReset;

  // ✅ NEW: Filter state parameters
  final bool isVehicleMakeSelected;
  final bool isVehicleModelSelected;
  final bool isSubCategorySelected;
  final bool isTypeSelected;
  final bool isSizeSelected;

  const FilterButtonsSection({
    super.key,
    required this.selectedVehicleMake,
    required this.selectedVehicleModel,
    required this.selectedSubCategory,
    this.selectedType,
    required this.selectedSize,
    required this.onVehicleSelected,
    required this.onCategorySelected,
    required this.onSizeSelected,
    this.onSearch,
    this.onReset,
    // ✅ NEW: Filter state parameters
    this.isVehicleMakeSelected = false,
    this.isVehicleModelSelected = false,
    this.isSubCategorySelected = false,
    this.isTypeSelected = false,
    this.isSizeSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 2, 8, 2),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.filter_list_outlined,
                size: 13,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 5),
              Text(
                'Filter by:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Opacity(
                  opacity: 1.0, // Always enabled
                  child: _buildFilterButton(
                    context,
                    'Vehicle - Make & Model',
                    _getVehicleLabel(),
                    Icons.directions_car_outlined,
                    onVehicleSelected,
                    isEnabled: true,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Opacity(
                  opacity: isVehicleModelSelected ? 1.0 : 0.5,
                  child: _buildFilterButton(
                    context,
                    'Part',
                    selectedSubCategory,
                    Icons.inventory_2_outlined,
                    isVehicleModelSelected ? onCategorySelected : () {},
                    isEnabled: isVehicleModelSelected,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Opacity(
                  opacity: isSubCategorySelected ? 1.0 : 0.5,
                  child: _buildFilterButton(
                    context,
                    'Type & Size',
                    _getTypeSizeLabel(),
                    Icons.straighten_outlined,
                    isSubCategorySelected ? onSizeSelected : () {},
                    isEnabled: isSubCategorySelected,
                  ),
                ),
              ),
            ],
          ),
          if (onSearch != null && onReset != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: _buildActionButton(
                    context,
                    'Reset',
                    Icons.refresh_outlined,
                    onReset!,
                    isPrimary: false,
                    isEnabled: true, // ✅ Reset always enabled
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 2,
                  child: _buildActionButton(
                    context,
                    'Search',
                    Icons.search_outlined,
                    // ✅ NEW: Only enable if all filters complete
                    (isVehicleMakeSelected &&
                            isVehicleModelSelected &&
                            isSubCategorySelected &&
                            isTypeSelected &&
                            isSizeSelected)
                        ? onSearch!
                        : () {},
                    isPrimary: true,
                    isEnabled:
                        isVehicleMakeSelected &&
                        isVehicleModelSelected &&
                        isSubCategorySelected &&
                        isTypeSelected &&
                        isSizeSelected,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String? _getVehicleLabel() {
    if (selectedVehicleMake != null && selectedVehicleModel != null) {
      return '$selectedVehicleMake | $selectedVehicleModel';
    } else if (selectedVehicleMake != null) {
      return selectedVehicleMake;
    } else if (selectedVehicleModel != null) {
      return selectedVehicleModel;
    }
    return null;
  }

  String? _getTypeSizeLabel() {
    if (selectedType != null && selectedSize != null) {
      return '$selectedType | $selectedSize';
    } else if (selectedType != null) {
      return selectedType;
    } else if (selectedSize != null) {
      return selectedSize;
    }
    return null;
  }

  Widget _buildFilterButton(
    BuildContext context,
    String label,
    String? selectedValue,
    IconData icon,
    VoidCallback onTap, {
    required bool isEnabled,
  }) {
    final isActive = selectedValue != null;
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? onTap : () {},
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive
                  ? AppTheme.primaryColor
                  : colorScheme.outline.withValues(alpha: 0.25),
              width: isActive ? 2 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isActive
                    ? AppTheme.primaryColor.withOpacity(0.25)
                    : Colors.black.withOpacity(0.06),
                blurRadius: isActive ? 8 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isActive ? Colors.white : AppTheme.primaryColor,
                size: 16,
              ),
              const SizedBox(height: 2),
              Flexible(
                child: Text(
                  selectedValue ?? label,
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.black,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 10,
                    height: 1.1,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String text,
    IconData icon,
    VoidCallback onPressed, {
    required bool isPrimary,
    required bool isEnabled,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? onPressed : () {},
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: isPrimary ? AppTheme.primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppTheme.primaryColor,
              width: isPrimary ? 0 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: isPrimary
                    ? AppTheme.primaryColor.withOpacity(0.3)
                    : Colors.black.withOpacity(0.05),
                blurRadius: isPrimary ? 6 : 3,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isPrimary ? Colors.white : AppTheme.primaryColor,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  text,
                  style: TextStyle(
                    color: isPrimary ? Colors.white : AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
