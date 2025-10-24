import 'package:flutter/material.dart';

import 'vehicle_make_dialog.dart';
import 'vehicle_model_dialog.dart';

class VehicleSelectionDialog {
  static Future<void> show({
    required BuildContext context,
    required String? selectedVehicleMake,
    required String? selectedVehicleModel,
    required Function(String?, String?) onVehicleSelected,
    String? selectedSubCategory,
    String? selectedSize,
  }) async {
    String? currentMake = selectedVehicleMake;
    String? currentModel = selectedVehicleModel;
    String? previousMake = selectedVehicleMake; // Track previous make
    bool shouldShowModel = false;

    // Show Vehicle Make Dialog
    do {
      final makeResult = await showDialog<String>(
        context: context,
        barrierDismissible: true, // Allow ESC key to close
        barrierColor: Colors.black87, // More opaque barrier to block touches
        useSafeArea: true, // Ensure dialog is within safe area
        builder: (context) => VehicleMakeDialog(
          selectedVehicleMake: currentMake,
          onVehicleMakeSelected: (make) {
            // If make changed, reset model to null
            if (make != previousMake) {
              print(
                '🔄 Make changed from "$previousMake" to "$make" - Resetting model to null',
              );
              currentModel = null;
              previousMake = make;
            }
            currentMake = make;
          },
          // Pass cascading filters
          selectedSubCategory: selectedSubCategory,
          selectedSize: selectedSize,
        ),
      );

      // If Cancel was clicked, stop the flow
      if (makeResult == 'cancel') {
        print('❌ Vehicle selection cancelled by user');
        return;
      }

      // If a make was selected, show Vehicle Model Dialog
      if (currentMake != null && context.mounted) {
        final result = await showDialog<String>(
          context: context,
          barrierDismissible: true, // Allow ESC key to close
          barrierColor: Colors.black87, // More opaque barrier to block touches
          useSafeArea: true, // Ensure dialog is within safe area
          builder: (context) => VehicleModelDialog(
            selectedVehicleMake: currentMake!,
            selectedVehicleModel: currentModel,
            onVehicleModelSelected: (model) {
              currentModel = model;
            },
            onBackPressed: () {
              Navigator.pop(
                context,
                'back',
              ); // Return 'back' to show make dialog again
            },
            // Pass cascading filters
            selectedSubCategory: selectedSubCategory,
            selectedSize: selectedSize,
          ),
        );

        // If Cancel was clicked, stop the flow
        if (result == 'cancel') {
          print('❌ Vehicle Model selection cancelled by user');
          return;
        }

        // If back was pressed from model dialog, show make dialog again
        shouldShowModel = result == 'back';
      } else {
        shouldShowModel = false;
      }
    } while (shouldShowModel);

    // Call the callback with the final selection
    onVehicleSelected(currentMake, currentModel);
  }
}
