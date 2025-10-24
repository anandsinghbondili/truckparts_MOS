import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class ItemsFilterButtonsSection extends StatelessWidget {
  final String? selectedVehicleMake;
  final String? selectedVehicleModel;
  final String? selectedPart;
  final String? selectedType;
  final String? selectedSize;
  final VoidCallback onVehicleMakeTap;
  final VoidCallback onVehicleModelTap;
  final VoidCallback onPartTap;
  final VoidCallback onTypeTap;
  final VoidCallback onSizeTap;
  final VoidCallback onResetFilters;

  const ItemsFilterButtonsSection({
    super.key,
    required this.selectedVehicleMake,
    required this.selectedVehicleModel,
    required this.selectedPart,
    required this.selectedType,
    required this.selectedSize,
    required this.onVehicleMakeTap,
    required this.onVehicleModelTap,
    required this.onPartTap,
    required this.onTypeTap,
    required this.onSizeTap,
    required this.onResetFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'Filter by:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),

          // Filter Buttons Row 1
          Row(
            children: [
              Expanded(
                child: _buildFilterButton(
                  context,
                  'Vehicle Make',
                  selectedVehicleMake ?? 'Select Make',
                  Icons.directions_car,
                  onVehicleMakeTap,
                  isSelected: selectedVehicleMake != null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterButton(
                  context,
                  'Vehicle Model',
                  selectedVehicleModel ?? 'Select Model',
                  Icons.model_training,
                  onVehicleModelTap,
                  isSelected: selectedVehicleModel != null,
                  enabled: selectedVehicleMake != null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Filter Buttons Row 2
          Row(
            children: [
              Expanded(
                child: _buildFilterButton(
                  context,
                  'Part',
                  selectedPart ?? 'Select Part',
                  Icons.inventory_2,
                  onPartTap,
                  isSelected: selectedPart != null,
                  enabled:
                      selectedVehicleMake != null &&
                      selectedVehicleModel != null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterButton(
                  context,
                  'Type',
                  selectedType ?? 'Select Type',
                  Icons.category,
                  onTypeTap,
                  isSelected: selectedType != null,
                  enabled:
                      selectedVehicleMake != null &&
                      selectedVehicleModel != null &&
                      selectedPart != null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Filter Buttons Row 3
          Row(
            children: [
              Expanded(
                child: _buildFilterButton(
                  context,
                  'Size',
                  selectedSize ?? 'Select Size',
                  Icons.straighten,
                  onSizeTap,
                  isSelected: selectedSize != null,
                  enabled:
                      selectedVehicleMake != null &&
                      selectedVehicleModel != null &&
                      selectedPart != null &&
                      selectedType != null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: _buildResetButton(context)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    VoidCallback onTap, {
    required bool isSelected,
    bool enabled = true,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: enabled
              ? (isSelected
                    ? AppTheme.primaryColor.withValues(alpha: 0.1)
                    : Theme.of(context).colorScheme.surfaceContainerHighest)
              : Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled
                ? (isSelected
                      ? AppTheme.primaryColor
                      : Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.3))
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: enabled
                  ? (isSelected
                        ? AppTheme.primaryColor
                        : Theme.of(context).colorScheme.onSurfaceVariant)
                  : Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: enabled
                    ? (isSelected
                          ? AppTheme.primaryColor
                          : Theme.of(context).colorScheme.onSurfaceVariant)
                    : Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: enabled
                    ? (isSelected
                          ? AppTheme.primaryColor
                          : Theme.of(context).colorScheme.onSurface)
                    : Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResetButton(BuildContext context) {
    return GestureDetector(
      onTap: onResetFilters,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.errorColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.errorColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(Icons.refresh, size: 20, color: AppTheme.errorColor),
            const SizedBox(height: 4),
            Text(
              'Reset',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppTheme.errorColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'All Filters',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.errorColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
