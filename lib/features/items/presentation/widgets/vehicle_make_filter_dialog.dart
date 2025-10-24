import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class VehicleMakeFilterDialog extends StatefulWidget {
  final List<String> vehicleMakes;
  final String? selectedMake;
  final Function(String?) onMakeSelected;

  const VehicleMakeFilterDialog({
    super.key,
    required this.vehicleMakes,
    this.selectedMake,
    required this.onMakeSelected,
  });

  @override
  State<VehicleMakeFilterDialog> createState() =>
      _VehicleMakeFilterDialogState();
}

class _VehicleMakeFilterDialogState extends State<VehicleMakeFilterDialog> {
  String? _selectedMake;
  String _searchQuery = '';
  late List<String> _filteredMakes;

  @override
  void initState() {
    super.initState();
    _selectedMake = widget.selectedMake;
    _filteredMakes = widget.vehicleMakes;
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
                  Icons.directions_car,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Select Vehicle Make',
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
                hintText: 'Search vehicle makes...',
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
                  _filteredMakes = widget.vehicleMakes
                      .where(
                        (make) => make.toLowerCase().contains(_searchQuery),
                      )
                      .toList();
                });
              },
            ),
            const SizedBox(height: 16),

            // Vehicle Makes List
            Expanded(
              child: _filteredMakes.isEmpty
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
                            'No vehicle makes found',
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
                      itemCount: _filteredMakes.length,
                      itemBuilder: (context, index) {
                        final make = _filteredMakes[index];
                        final isSelected = _selectedMake == make;

                        return ListTile(
                          leading: Icon(
                            Icons.directions_car,
                            color: isSelected ? AppTheme.primaryColor : null,
                          ),
                          title: Text(
                            make,
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
                              _selectedMake = isSelected ? null : make;
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
                      widget.onMakeSelected(null);
                      Navigator.pop(context);
                    },
                    child: const Text('Clear'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onMakeSelected(_selectedMake);
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
