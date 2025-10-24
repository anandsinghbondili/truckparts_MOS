import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class PartsFilterDialog extends StatefulWidget {
  final List<String> parts;
  final String? selectedPart;
  final Function(String?) onPartSelected;

  const PartsFilterDialog({
    super.key,
    required this.parts,
    this.selectedPart,
    required this.onPartSelected,
  });

  @override
  State<PartsFilterDialog> createState() => _PartsFilterDialogState();
}

class _PartsFilterDialogState extends State<PartsFilterDialog> {
  String? _selectedPart;
  String _searchQuery = '';
  late List<String> _filteredParts;

  @override
  void initState() {
    super.initState();
    _selectedPart = widget.selectedPart;
    _filteredParts = widget.parts;
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
                Icon(Icons.inventory_2, color: AppTheme.primaryColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Select Part',
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
                hintText: 'Search parts...',
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
                  _filteredParts = widget.parts
                      .where(
                        (part) => part.toLowerCase().contains(_searchQuery),
                      )
                      .toList();
                });
              },
            ),
            const SizedBox(height: 16),

            // Parts List
            Expanded(
              child: _filteredParts.isEmpty
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
                            'No parts found',
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
                      itemCount: _filteredParts.length,
                      itemBuilder: (context, index) {
                        final part = _filteredParts[index];
                        final isSelected = _selectedPart == part;

                        return ListTile(
                          leading: Icon(
                            Icons.inventory_2,
                            color: isSelected ? AppTheme.primaryColor : null,
                          ),
                          title: Text(
                            part,
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
                              _selectedPart = isSelected ? null : part;
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
                      widget.onPartSelected(null);
                      Navigator.pop(context);
                    },
                    child: const Text('Clear'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onPartSelected(_selectedPart);
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
