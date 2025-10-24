import '../../../home/domain/entities/part.dart';
import '../models/part_model.dart';

/// Service for storing and managing parts data from ItemDetailsbyCustomer API
class PartsDataService {
  List<Part> _cachedParts = [];
  bool _isInitialized = false;

  /// Check if data is loaded
  bool get isInitialized => _isInitialized;

  /// Get all cached parts
  List<Part> get allParts => List.unmodifiable(_cachedParts);

  /// Store parts data from API
  void storeParts(List<PartModel> parts) {
    print('📦 PartsDataService: Storing ${parts.length} parts...');
    try {
      _cachedParts = parts.map((model) => model.toEntity()).toList();
      _isInitialized = true;
      print('✅ PartsDataService: Stored ${_cachedParts.length} parts');
      print('   - Initialized: $_isInitialized');
      if (_cachedParts.isNotEmpty) {
        print(
          '   - First part: ${_cachedParts.first.id} - ${_cachedParts.first.item}',
        );
      }
    } catch (e, stackTrace) {
      print('❌ PartsDataService: Error storing parts: $e');
      print('❌ Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Clear cached data
  void clear() {
    _cachedParts = [];
    _isInitialized = false;
    print('🗑️ PartsDataService: Cleared cached parts');
  }

  /// Get all parts
  List<Part> getAllParts() {
    print(
      '📋 PartsDataService: getAllParts called - Initialized: $_isInitialized, Count: ${_cachedParts.length}',
    );
    return List.unmodifiable(_cachedParts);
  }

  /// Get a specific part by ID
  Part? getPartById(String partId) {
    print(
      '🔍 PartsDataService: getPartById called for ID: $partId - Initialized: $_isInitialized, Count: ${_cachedParts.length}',
    );

    if (!_isInitialized || _cachedParts.isEmpty) {
      print('⚠️ PartsDataService: No cached parts available');
      return null;
    }

    try {
      final part = _cachedParts.firstWhere(
        (part) => part.id == partId,
        orElse: () => throw StateError('Part not found'),
      );
      print('✅ PartsDataService: Found part - ${part.id} - ${part.item}');
      return part;
    } catch (e) {
      print('❌ PartsDataService: Part with ID $partId not found');
      return null;
    }
  }

  /// Get vehicle makes - with optional cascading filters
  List<String> getVehicleMakes({
    String? vehicleModel,
    String? subCategory,
    String? size,
  }) {
    var filteredParts = _cachedParts;

    // Apply cascading filters based on already selected values
    if (vehicleModel != null && vehicleModel.isNotEmpty) {
      filteredParts = filteredParts
          .where(
            (part) => part.model.toLowerCase() == vehicleModel.toLowerCase(),
          )
          .toList();
    }
    if (subCategory != null && subCategory.isNotEmpty) {
      filteredParts = filteredParts
          .where(
            (part) =>
                part.subCategory.toLowerCase() == subCategory.toLowerCase(),
          )
          .toList();
    }
    if (size != null && size.isNotEmpty) {
      filteredParts = filteredParts
          .where((part) => part.size.toLowerCase() == size.toLowerCase())
          .toList();
    }

    final vehicleMakes = filteredParts
        .map((part) => part.vehicleMake)
        .where((make) => make.isNotEmpty)
        .toSet()
        .toList();
    vehicleMakes.sort();
    return vehicleMakes;
  }

  /// Get vehicle models - with optional cascading filters
  List<String> getVehicleModels({
    String? vehicleMake,
    String? subCategory,
    String? size,
  }) {
    var filteredParts = _cachedParts;

    // Apply cascading filters
    if (vehicleMake != null && vehicleMake.isNotEmpty) {
      filteredParts = filteredParts
          .where(
            (part) =>
                part.vehicleMake.toLowerCase() == vehicleMake.toLowerCase(),
          )
          .toList();
    }
    if (subCategory != null && subCategory.isNotEmpty) {
      filteredParts = filteredParts
          .where(
            (part) =>
                part.subCategory.toLowerCase() == subCategory.toLowerCase(),
          )
          .toList();
    }
    if (size != null && size.isNotEmpty) {
      filteredParts = filteredParts
          .where((part) => part.size.toLowerCase() == size.toLowerCase())
          .toList();
    }

    final models = filteredParts
        .map((part) => part.model)
        .where((model) => model.isNotEmpty)
        .toSet()
        .toList();
    models.sort();
    return models;
  }

  /// Get categories - with optional cascading filters
  List<String> getCategories({
    String? vehicleMake,
    String? vehicleModel,
    String? size,
  }) {
    var filteredParts = _cachedParts;

    // Apply cascading filters
    if (vehicleMake != null && vehicleMake.isNotEmpty) {
      filteredParts = filteredParts
          .where(
            (part) =>
                part.vehicleMake.toLowerCase() == vehicleMake.toLowerCase(),
          )
          .toList();
    }
    if (vehicleModel != null && vehicleModel.isNotEmpty) {
      filteredParts = filteredParts
          .where(
            (part) => part.model.toLowerCase() == vehicleModel.toLowerCase(),
          )
          .toList();
    }
    if (size != null && size.isNotEmpty) {
      filteredParts = filteredParts
          .where((part) => part.size.toLowerCase() == size.toLowerCase())
          .toList();
    }

    final categories = filteredParts
        .map((part) => part.category)
        .where((category) => category.isNotEmpty)
        .toSet()
        .toList();
    categories.sort();
    return categories;
  }

  /// Get sub-categories (Parts) - with optional cascading filters
  List<String> getSubCategories({
    String? category,
    String? vehicleMake,
    String? vehicleModel,
    String? size,
  }) {
    var filteredParts = _cachedParts;

    // Apply cascading filters
    if (category != null && category.isNotEmpty) {
      filteredParts = filteredParts
          .where(
            (part) => part.category.toLowerCase() == category.toLowerCase(),
          )
          .toList();
    }
    if (vehicleMake != null && vehicleMake.isNotEmpty) {
      filteredParts = filteredParts
          .where(
            (part) =>
                part.vehicleMake.toLowerCase() == vehicleMake.toLowerCase(),
          )
          .toList();
    }
    if (vehicleModel != null && vehicleModel.isNotEmpty) {
      filteredParts = filteredParts
          .where(
            (part) => part.model.toLowerCase() == vehicleModel.toLowerCase(),
          )
          .toList();
    }
    if (size != null && size.isNotEmpty) {
      filteredParts = filteredParts
          .where((part) => part.size.toLowerCase() == size.toLowerCase())
          .toList();
    }

    final subCategories = filteredParts
        .map((part) => part.subCategory)
        .where((subCategory) => subCategory.isNotEmpty)
        .toSet()
        .toList();
    subCategories.sort();
    return subCategories;
  }

  /// Get types - with optional cascading filters
  List<String> getTypes({
    String? vehicleMake,
    String? vehicleModel,
    String? subCategory,
    String? size,
  }) {
    var filteredParts = _cachedParts;

    // Apply cascading filters
    if (vehicleMake != null && vehicleMake.isNotEmpty) {
      filteredParts = filteredParts
          .where(
            (part) =>
                part.vehicleMake.toLowerCase() == vehicleMake.toLowerCase(),
          )
          .toList();
    }
    if (vehicleModel != null && vehicleModel.isNotEmpty) {
      filteredParts = filteredParts
          .where(
            (part) => part.model.toLowerCase() == vehicleModel.toLowerCase(),
          )
          .toList();
    }
    if (subCategory != null && subCategory.isNotEmpty) {
      filteredParts = filteredParts
          .where(
            (part) =>
                part.subCategory.toLowerCase() == subCategory.toLowerCase(),
          )
          .toList();
    }
    if (size != null && size.isNotEmpty) {
      filteredParts = filteredParts
          .where((part) => part.size.toLowerCase() == size.toLowerCase())
          .toList();
    }

    final types = filteredParts
        .map((part) => part.type)
        .where((type) => type.isNotEmpty)
        .toSet()
        .toList();
    types.sort();
    return types;
  }

  /// Get sizes - with optional cascading filters
  List<String> getSizes({
    String? vehicleMake,
    String? vehicleModel,
    String? subCategory,
    String? type,
  }) {
    var filteredParts = _cachedParts;

    // Apply cascading filters
    if (vehicleMake != null && vehicleMake.isNotEmpty) {
      filteredParts = filteredParts
          .where(
            (part) =>
                part.vehicleMake.toLowerCase() == vehicleMake.toLowerCase(),
          )
          .toList();
    }
    if (vehicleModel != null && vehicleModel.isNotEmpty) {
      filteredParts = filteredParts
          .where(
            (part) => part.model.toLowerCase() == vehicleModel.toLowerCase(),
          )
          .toList();
    }
    if (subCategory != null && subCategory.isNotEmpty) {
      filteredParts = filteredParts
          .where(
            (part) =>
                part.subCategory.toLowerCase() == subCategory.toLowerCase(),
          )
          .toList();
    }
    if (type != null && type.isNotEmpty) {
      filteredParts = filteredParts
          .where((part) => part.type.toLowerCase() == type.toLowerCase())
          .toList();
    }

    final sizes = filteredParts
        .map((part) => part.size)
        .where((size) => size.isNotEmpty)
        .toSet()
        .toList();
    sizes.sort();
    return sizes;
  }

  /// Get brands
  List<String> getBrands() {
    final brands = _cachedParts
        .map((part) => part.brand)
        .where((brand) => brand.isNotEmpty)
        .toSet()
        .toList();
    brands.sort();
    return brands;
  }

  /// Search parts with filters
  List<Part> searchParts({
    String? query,
    String? vehicleMake,
    String? vehicleModel,
    String? category,
    String? subCategory,
    String? type,
    String? size,
    String? brand,
  }) {
    return _cachedParts.where((part) {
      // Search query
      if (query != null && query.isNotEmpty) {
        final lowerQuery = query.toLowerCase();
        final matchesQuery =
            part.category.toLowerCase().contains(lowerQuery) ||
            part.subCategory.toLowerCase().contains(lowerQuery) ||
            part.vehicleMake.toLowerCase().contains(lowerQuery) ||
            part.model.toLowerCase().contains(lowerQuery) ||
            part.part.toLowerCase().contains(lowerQuery) ||
            part.brand.toLowerCase().contains(lowerQuery) ||
            part.item.toLowerCase().contains(lowerQuery) ||
            part.description.toLowerCase().contains(lowerQuery);

        if (!matchesQuery) return false;
      }

      // Vehicle filters
      if (vehicleMake != null && vehicleMake.isNotEmpty) {
        if (part.vehicleMake.toLowerCase() != vehicleMake.toLowerCase()) {
          return false;
        }
      }

      if (vehicleModel != null && vehicleModel.isNotEmpty) {
        if (part.model.toLowerCase() != vehicleModel.toLowerCase()) {
          return false;
        }
      }

      // Category filters
      if (category != null && category.isNotEmpty) {
        if (part.category.toLowerCase() != category.toLowerCase()) {
          return false;
        }
      }

      if (subCategory != null && subCategory.isNotEmpty) {
        if (part.subCategory.toLowerCase() != subCategory.toLowerCase()) {
          return false;
        }
      }

      // Type filter
      // ✅ NEW: Treat "Any" as no filter (show all types)
      if (type != null && type.isNotEmpty && type.toLowerCase() != 'any') {
        if (part.type.toLowerCase() != type.toLowerCase()) {
          return false;
        }
      }

      // Size filter
      // ✅ NEW: Treat "Any" as no filter (show all sizes)
      if (size != null && size.isNotEmpty && size.toLowerCase() != 'any') {
        if (part.size.toLowerCase() != size.toLowerCase()) {
          return false;
        }
      }

      // Brand filter
      if (brand != null && brand.isNotEmpty) {
        if (part.brand.toLowerCase() != brand.toLowerCase()) {
          return false;
        }
      }

      return true;
    }).toList();
  }
}
