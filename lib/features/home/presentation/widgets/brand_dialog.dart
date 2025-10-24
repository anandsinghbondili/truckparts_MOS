import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../home/data/services/parts_service.dart';

class BrandDialog extends StatefulWidget {
  final String? selectedBrand;
  final Function(String?) onBrandSelected;

  const BrandDialog({
    super.key,
    required this.selectedBrand,
    required this.onBrandSelected,
  });

  @override
  State<BrandDialog> createState() => _BrandDialogState();
}

class _BrandDialogState extends State<BrandDialog> {
  String? _selectedBrand;
  List<String> _brands = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedBrand = widget.selectedBrand;
    _loadBrands();
  }

  Future<void> _loadBrands() async {
    try {
      final brands = await PartsService.getBrands();
      setState(() {
        _brands = brands;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load brands: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Brand'),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Brand Dropdown
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Brand',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.branding_watermark),
                    ),
                    initialValue: _selectedBrand,
                    items: _brands.map((brand) {
                      return DropdownMenuItem(value: brand, child: Text(brand));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedBrand = value;
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // Show available parts count
                  if (_selectedBrand != null)
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
                              'Parts available for brand: $_selectedBrand',
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
            widget.onBrandSelected(_selectedBrand);
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
