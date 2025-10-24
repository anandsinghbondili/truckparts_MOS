import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../home/data/services/parts_service.dart';

class CategoryDialog extends StatefulWidget {
  final String? selectedCategory;
  final String? selectedSubCategory;
  final Function(String?, String?) onCategorySelected;

  const CategoryDialog({
    super.key,
    required this.selectedCategory,
    required this.selectedSubCategory,
    required this.onCategorySelected,
  });

  @override
  State<CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<CategoryDialog> {
  String? _selectedCategory;
  String? _selectedSubCategory;
  List<String> _categories = [];
  List<String> _subCategories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.selectedCategory;
    _selectedSubCategory = widget.selectedSubCategory;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await PartsService.getCategories();
      setState(() {
        _categories = categories;
        _isLoading = false;
      });

      // Load subcategories if a category is already selected
      if (_selectedCategory != null) {
        _loadSubCategories(_selectedCategory!);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load categories: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _loadSubCategories(String category) async {
    try {
      final subCategories = await PartsService.getSubCategories(
        category: category,
      );
      setState(() {
        _subCategories = subCategories;
        _selectedSubCategory = null; // Reset subcategory when category changes
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load subcategories: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Category'),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Category Dropdown
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    initialValue: _selectedCategory,
                    items: _categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                      if (value != null) {
                        _loadSubCategories(value);
                      }
                    },
                  ),

                  const SizedBox(height: 16),

                  // Subcategory Dropdown
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Sub Category',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.subdirectory_arrow_right),
                    ),
                    initialValue: _selectedSubCategory,
                    items: _subCategories.map((subCategory) {
                      return DropdownMenuItem(
                        value: subCategory,
                        child: Text(subCategory),
                      );
                    }).toList(),
                    onChanged: _selectedCategory != null
                        ? (value) {
                            setState(() {
                              _selectedSubCategory = value;
                            });
                          }
                        : null,
                  ),

                  const SizedBox(height: 16),

                  // Show available parts count
                  if (_selectedCategory != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppTheme.primaryColor,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedSubCategory != null
                                  ? 'Parts available for $_selectedCategory > $_selectedSubCategory'
                                  : 'Parts available for $_selectedCategory',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onCategorySelected(_selectedCategory, _selectedSubCategory);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
