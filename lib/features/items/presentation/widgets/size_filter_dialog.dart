import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class SizeFilterDialog extends StatefulWidget {
  final List<String> sizes;
  final String? selectedSize;
  final Function(String?) onSizeSelected;

  const SizeFilterDialog({
    super.key,
    required this.sizes,
    this.selectedSize,
    required this.onSizeSelected,
  });

  @override
  State<SizeFilterDialog> createState() => _SizeFilterDialogState();
}

class _SizeFilterDialogState extends State<SizeFilterDialog> {
  String? _selectedSize;
  String _searchQuery = '';
  late List<String> _filteredSizes;

  @override
  void initState() {
    super.initState();
    _selectedSize = widget.selectedSize;
    _filteredSizes = widget.sizes;
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
                Icon(Icons.straighten, color: AppTheme.primaryColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Select Size',
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
                hintText: 'Search sizes...',
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
                  _filteredSizes = widget.sizes
                      .where(
                        (size) => size.toLowerCase().contains(_searchQuery),
                      )
                      .toList();
                });
              },
            ),
            const SizedBox(height: 16),

            // Sizes List
            Expanded(
              child: _filteredSizes.isEmpty
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
                            'No sizes found',
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
                      itemCount: _filteredSizes.length,
                      itemBuilder: (context, index) {
                        final size = _filteredSizes[index];
                        final isSelected = _selectedSize == size;

                        return ListTile(
                          leading: Icon(
                            Icons.straighten,
                            color: isSelected ? AppTheme.primaryColor : null,
                          ),
                          title: Text(
                            size,
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
                              _selectedSize = isSelected ? null : size;
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
                      widget.onSizeSelected(null);
                      Navigator.pop(context);
                    },
                    child: const Text('Clear'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onSizeSelected(_selectedSize);
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
