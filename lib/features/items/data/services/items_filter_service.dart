import '../models/item_model.dart';

/// Service for handling sequential filtering of items
/// Implements cascading filter logic where each filter narrows down options for subsequent filters
class ItemsFilterService {
  /// Get all unique vehicle makes from the items list
  static List<String> getVehicleMakes(List<ItemModel> items) {
    final makes = <String>{};
    for (final item in items) {
      if (item.vehicleMake != null && item.vehicleMake!.isNotEmpty) {
        makes.add(item.vehicleMake!);
      }
    }
    return makes.toList()..sort();
  }

  /// Get vehicle models for a specific make
  static List<String> getVehicleModels(
    List<ItemModel> items,
    String? vehicleMake,
  ) {
    if (vehicleMake == null) return [];

    final models = <String>{};
    for (final item in items) {
      if (item.vehicleMake == vehicleMake &&
          item.vehicleModel != null &&
          item.vehicleModel!.isNotEmpty) {
        models.add(item.vehicleModel!);
      }
    }
    return models.toList()..sort();
  }

  /// Get parts (subcategories) for specific vehicle make and model
  static List<String> getParts(
    List<ItemModel> items,
    String? vehicleMake,
    String? vehicleModel,
  ) {
    final parts = <String>{};
    for (final item in items) {
      bool matchesVehicle = true;

      if (vehicleMake != null && item.vehicleMake != vehicleMake) {
        matchesVehicle = false;
      }

      if (vehicleModel != null && item.vehicleModel != vehicleModel) {
        matchesVehicle = false;
      }

      if (matchesVehicle &&
          item.subCategory != null &&
          item.subCategory!.isNotEmpty) {
        parts.add(item.subCategory!);
      }
    }
    return parts.toList()..sort();
  }

  /// Get part types for specific vehicle make, model, and part
  static List<String> getPartTypes(
    List<ItemModel> items,
    String? vehicleMake,
    String? vehicleModel,
    String? part,
  ) {
    final types = <String>{};
    for (final item in items) {
      bool matchesFilters = true;

      if (vehicleMake != null && item.vehicleMake != vehicleMake) {
        matchesFilters = false;
      }

      if (vehicleModel != null && item.vehicleModel != vehicleModel) {
        matchesFilters = false;
      }

      if (part != null && item.subCategory != part) {
        matchesFilters = false;
      }

      if (matchesFilters &&
          item.partType != null &&
          item.partType!.isNotEmpty) {
        types.add(item.partType!);
      }
    }
    return types.toList()..sort();
  }

  /// Get sizes for specific vehicle make, model, part, and type
  static List<String> getSizes(
    List<ItemModel> items,
    String? vehicleMake,
    String? vehicleModel,
    String? part,
    String? partType,
  ) {
    final sizes = <String>{};
    for (final item in items) {
      bool matchesFilters = true;

      if (vehicleMake != null && item.vehicleMake != vehicleMake) {
        matchesFilters = false;
      }

      if (vehicleModel != null && item.vehicleModel != vehicleModel) {
        matchesFilters = false;
      }

      if (part != null && item.subCategory != part) {
        matchesFilters = false;
      }

      if (partType != null && item.partType != partType) {
        matchesFilters = false;
      }

      if (matchesFilters && item.size != null && item.size!.isNotEmpty) {
        sizes.add(item.size!);
      }
    }
    return sizes.toList()..sort();
  }

  /// Apply all filters to the items list
  static List<ItemModel> applyFilters(
    List<ItemModel> items, {
    String? vehicleMake,
    String? vehicleModel,
    String? part,
    String? partType,
    String? size,
  }) {
    return items.where((item) {
      // Vehicle Make filter
      if (vehicleMake != null && item.vehicleMake != vehicleMake) {
        return false;
      }

      // Vehicle Model filter
      if (vehicleModel != null && item.vehicleModel != vehicleModel) {
        return false;
      }

      // Part (SubCategory) filter
      if (part != null && item.subCategory != part) {
        return false;
      }

      // Part Type filter
      if (partType != null && item.partType != partType) {
        return false;
      }

      // Size filter
      if (size != null && item.size != size) {
        return false;
      }

      return true;
    }).toList();
  }

  /// Get filter statistics
  static Map<String, int> getFilterStats(List<ItemModel> items) {
    return {
      'totalItems': items.length,
      'vehicleMakes': getVehicleMakes(items).length,
      'vehicleModels': items
          .where(
            (item) =>
                item.vehicleModel != null && item.vehicleModel!.isNotEmpty,
          )
          .length,
      'parts': items
          .where(
            (item) => item.subCategory != null && item.subCategory!.isNotEmpty,
          )
          .length,
      'partTypes': items
          .where((item) => item.partType != null && item.partType!.isNotEmpty)
          .length,
      'sizes': items
          .where((item) => item.size != null && item.size!.isNotEmpty)
          .length,
    };
  }

  /// Check if a filter combination is valid
  static bool isValidFilterCombination(
    List<ItemModel> items, {
    String? vehicleMake,
    String? vehicleModel,
    String? part,
    String? partType,
    String? size,
  }) {
    final filteredItems = applyFilters(
      items,
      vehicleMake: vehicleMake,
      vehicleModel: vehicleModel,
      part: part,
      partType: partType,
      size: size,
    );

    return filteredItems.isNotEmpty;
  }

  /// Get next available filter options based on current selections
  static Map<String, List<String>> getNextFilterOptions(
    List<ItemModel> items, {
    String? vehicleMake,
    String? vehicleModel,
    String? part,
    String? partType,
  }) {
    return {
      'vehicleMakes': getVehicleMakes(items),
      'vehicleModels': getVehicleModels(items, vehicleMake),
      'parts': getParts(items, vehicleMake, vehicleModel),
      'partTypes': getPartTypes(items, vehicleMake, vehicleModel, part),
      'sizes': getSizes(items, vehicleMake, vehicleModel, part, partType),
    };
  }
}
