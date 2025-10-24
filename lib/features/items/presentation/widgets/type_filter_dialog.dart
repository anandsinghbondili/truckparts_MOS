import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class TypeFilterDialog extends StatefulWidget {
  final List<String> types;
  final String? selectedType;
  final Function(String?) onTypeSelected;

  const TypeFilterDialog({
    super.key,
    required this.types,
    this.selectedType,
    required this.onTypeSelected,
  });

  @override
  State<TypeFilterDialog> createState() => _TypeFilterDialogState();
}

class _TypeFilterDialogState extends State<TypeFilterDialog> {
  String? _selectedType;
  String _searchQuery = '';
  late List<String> _filteredTypes;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.selectedType;
    _filteredTypes = widget.types;
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
                Icon(Icons.category, color: AppTheme.primaryColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Select Type',
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
                hintText: 'Search types...',
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
                  _filteredTypes = widget.types
                      .where(
                        (type) => type.toLowerCase().contains(_searchQuery),
                      )
                      .toList();
                });
              },
            ),
            const SizedBox(height: 16),

            // Types List
            Expanded(
              child: _filteredTypes.isEmpty
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
                            'No types found',
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
                      itemCount: _filteredTypes.length,
                      itemBuilder: (context, index) {
                        final type = _filteredTypes[index];
                        final isSelected = _selectedType == type;

                        return ListTile(
                          leading: Icon(
                            Icons.category,
                            color: isSelected ? AppTheme.primaryColor : null,
                          ),
                          title: Text(
                            type,
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
                              _selectedType = isSelected ? null : type;
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
                      widget.onTypeSelected(null);
                      Navigator.pop(context);
                    },
                    child: const Text('Clear'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onTypeSelected(_selectedType);
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
