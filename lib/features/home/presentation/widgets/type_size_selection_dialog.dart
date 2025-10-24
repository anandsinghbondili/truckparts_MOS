import 'package:flutter/material.dart';

import 'type_dialog.dart';
import 'size_selection_dialog.dart';

class TypeSizeSelectionDialog {
  static Future<void> show({
    required BuildContext context,
    required String? selectedType,
    required String? selectedSize,
    required Function(String?, String?) onTypeSizeSelected,
    String? selectedVehicleMake,
    String? selectedVehicleModel,
    String? selectedSubCategory,
  }) async {
    String? currentType = selectedType;
    String? currentSize = selectedSize;
    String? previousType = selectedType; // Track previous type
    bool shouldShowSize = false;

    // Show Type Dialog
    do {
      final typeResult = await showDialog<String>(
        context: context,
        barrierDismissible: true, // Allow ESC key to close
        barrierColor: Colors.black54,
        builder: (context) => TypeDialog(
          selectedType: currentType,
          onTypeSelected: (type) {
            // If type changed, reset size to null
            if (type != previousType) {
              print(
                '🔄 Type changed from "$previousType" to "$type" - Resetting size to null',
              );
              currentSize = null;
              previousType = type;
            }
            currentType = type;
          },
          // Pass cascading filters
          selectedVehicleMake: selectedVehicleMake,
          selectedVehicleModel: selectedVehicleModel,
          selectedSubCategory: selectedSubCategory,
        ),
      );

      // If Cancel was clicked, stop the flow
      if (typeResult == 'cancel') {
        print('❌ Type selection cancelled by user');
        return;
      }

      // If Next was clicked (even without selection), show Size Dialog
      if (typeResult == 'next' && context.mounted) {
        print(
          '➡️ Proceeding to Size dialog (Type: ${currentType ?? "Not selected"})',
        );

        final result = await showDialog<String>(
          context: context,
          barrierDismissible: true, // Allow ESC key to close
          barrierColor: Colors.black54,
          builder: (context) => SizeSelectionDialog(
            selectedType: currentType, // Can be null
            selectedSize: currentSize,
            onSizeSelected: (size) {
              currentSize = size;
            },
            onBackPressed: () {
              Navigator.pop(
                context,
                'back',
              ); // Return 'back' to show type dialog again
            },
            // Pass cascading filters
            selectedVehicleMake: selectedVehicleMake,
            selectedVehicleModel: selectedVehicleModel,
            selectedSubCategory: selectedSubCategory,
          ),
        );

        // If Cancel was clicked, stop the flow
        if (result == 'cancel') {
          print('❌ Size selection cancelled by user');
          return;
        }

        // If back was pressed from size dialog, show type dialog again
        shouldShowSize = result == 'back';
      } else {
        shouldShowSize = false;
      }
    } while (shouldShowSize);

    // Call the callback with the final selection
    onTypeSizeSelected(currentType, currentSize);
  }
}
