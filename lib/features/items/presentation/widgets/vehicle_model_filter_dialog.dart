import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class VehicleModelFilterDialog extends StatefulWidget {
  final List<String> vehicleModels;
  final String? selectedModel;
  final Function(String?) onModelSelected;

  const VehicleModelFilterDialog({
    super.key,
    required this.vehicleModels,
    this.selectedModel,
    required this.onModelSelected,
  });

  @override
  State<VehicleModelFilterDialog> createState() =>
      _VehicleModelFilterDialogState();
}

class _VehicleModelFilterDialogState extends State<VehicleModelFilterDialog> {
  String? _selectedModel;
  String _searchQuery = '';
  late List<String> _filteredModels;

  @override
  void initState() {
    super.initState();
    _selectedModel = widget.selectedModel;
    _filteredModels = widget.vehicleModels;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.model_training,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Select Vehicle Model',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search Field
            TextField(
              decoration: InputDecoration(
                hintText: 'Search vehicle models...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                  _filteredModels = widget.vehicleModels
                      .where(
                        (model) => model.toLowerCase().contains(_searchQuery),
                      )
                      .toList();
                });
              },
            ),
            const SizedBox(height: 16),

            // Vehicle Models List
            Expanded(
              child: _filteredModels.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 48,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No vehicle models found',
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredModels.length,
                      itemBuilder: (context, index) {
                        final model = _filteredModels[index];
                        final isSelected = _selectedModel == model;

                        return ListTile(
                          leading: Icon(
                            Icons.model_training,
                            color: isSelected ? AppTheme.primaryColor : null,
                          ),
                          title: Text(
                            model,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isSelected ? AppTheme.primaryColor : null,
                            ),
                          ),
                          trailing: isSelected
                              ? Icon(
                                  Icons.check_circle,
                                  color: AppTheme.primaryColor,
                                )
                              : null,
                          onTap: () {
                            setState(() {
                              _selectedModel = isSelected ? null : model;
                            });
                          },
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 4,
                          ),
                        );
                      },
                    ),
            ),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      widget.onModelSelected(null);
                      Navigator.pop(context);
                    },
                    child: const Text('Clear'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onModelSelected(_selectedModel);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Apply'),
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
