import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../home/data/services/parts_service.dart';

class SizeDialog extends StatefulWidget {
  final String? selectedSize;
  final Function(String?) onSizeSelected;

  const SizeDialog({
    super.key,
    required this.selectedSize,
    required this.onSizeSelected,
  });

  @override
  State<SizeDialog> createState() => _SizeDialogState();
}

class _SizeDialogState extends State<SizeDialog> {
  String? _selectedSize;
  List<String> _sizes = [];
  bool _isLoading = true;
  bool _isEmpty = false; // ✅ NEW: Track if sizes list is empty

  @override
  void initState() {
    super.initState();
    _selectedSize = widget.selectedSize;
    _loadSizes();
  }

  Future<void> _loadSizes() async {
    try {
      final sizes = await PartsService.getSizes();
      setState(() {
        if (sizes.isEmpty) {
          // ✅ NEW: Handle empty sizes - show "Any" only
          _isEmpty = true;
          _sizes = ['Any'];
          _selectedSize = _selectedSize ?? 'Any'; // Auto-select "Any"
          print('⚠️ SizeDialog: No sizes available - showing "Any" option');
        } else {
          _isEmpty = false;
          _sizes = sizes;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isEmpty = true;
        _sizes = ['Any'];
        print('❌ SizeDialog: Error loading sizes - showing "Any" option');
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load sizes: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Size'),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Size Dropdown
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Size',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.straighten),
                    ),
                    initialValue: _selectedSize,
                    items: _sizes.map((size) {
                      return DropdownMenuItem(value: size, child: Text(size));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSize = value;
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // Show available parts count
                  if (_selectedSize != null)
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
                              'Parts available in size: $_selectedSize',
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
            widget.onSizeSelected(_selectedSize);
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
