import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../home/data/services/parts_service.dart';

class VehicleDialog extends StatefulWidget {
  final String? selectedVehicleMake;
  final String? selectedVehicleModel;
  final Function(String?, String?) onVehicleSelected;

  const VehicleDialog({
    super.key,
    required this.selectedVehicleMake,
    required this.selectedVehicleModel,
    required this.onVehicleSelected,
  });

  @override
  State<VehicleDialog> createState() => _VehicleDialogState();
}

class _VehicleDialogState extends State<VehicleDialog> {
  String? _selectedVehicleMake;
  String? _selectedVehicleModel;
  List<String> _vehicleMakes = [];
  List<String> _vehicleModels = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedVehicleMake = widget.selectedVehicleMake;
    _selectedVehicleModel = widget.selectedVehicleModel;
    _loadVehicleMakes();
  }

  Future<void> _loadVehicleMakes() async {
    try {
      final makes = await PartsService.getVehicleMakes();
      setState(() {
        _vehicleMakes = makes;
        _isLoading = false;
      });

      // Load models if a make is already selected
      if (_selectedVehicleMake != null) {
        _loadVehicleModels(_selectedVehicleMake!);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load vehicle makes: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _loadVehicleModels(String vehicleMake) async {
    try {
      final models = await PartsService.getVehicleModels(
        vehicleMake: vehicleMake,
      );
      setState(() {
        _vehicleModels = models;
        _selectedVehicleModel = null; // Reset model when make changes
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load vehicle models: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Vehicle'),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Vehicle Make Dropdown
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Vehicle Make',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.directions_car),
                    ),
                    initialValue: _selectedVehicleMake,
                    items: _vehicleMakes.map((make) {
                      return DropdownMenuItem(value: make, child: Text(make));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedVehicleMake = value;
                      });
                      if (value != null) {
                        _loadVehicleModels(value);
                      }
                    },
                  ),

                  const SizedBox(height: 16),

                  // Vehicle Model Dropdown
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Vehicle Model',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.car_rental),
                    ),
                    initialValue: _selectedVehicleModel,
                    items: _vehicleModels.map((model) {
                      return DropdownMenuItem(value: model, child: Text(model));
                    }).toList(),
                    onChanged: _selectedVehicleMake != null
                        ? (value) {
                            setState(() {
                              _selectedVehicleModel = value;
                            });
                          }
                        : null,
                    validator: (value) {
                      if (_selectedVehicleMake != null && value == null) {
                        return 'Please select a vehicle model';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Show available parts count
                  if (_selectedVehicleMake != null &&
                      _selectedVehicleModel != null)
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
                              'Parts available for $_selectedVehicleMake $_selectedVehicleModel',
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
            widget.onVehicleSelected(
              _selectedVehicleMake,
              _selectedVehicleModel,
            );
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
