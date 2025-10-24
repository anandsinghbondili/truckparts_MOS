import 'package:get_it/get_it.dart';

import '../../../../features/home/domain/entities/part.dart';
import 'parts_data_service.dart';

class PartsService {
  static PartsDataService get _partsDataService =>
      GetIt.instance<PartsDataService>();

  static Future<List<Part>> getAllParts() async {
    print('🏠 PartsService.getAllParts() called from HOME PAGE');
    final parts = _partsDataService.getAllParts();
    print('   - Returning ${parts.length} parts from cache');
    return parts;
  }

  static Future<List<String>> getVehicleMakes({
    String? vehicleModel,
    String? subCategory,
    String? size,
  }) async {
    return _partsDataService.getVehicleMakes(
      vehicleModel: vehicleModel,
      subCategory: subCategory,
      size: size,
    );
  }

  static Future<List<String>> getVehicleModels({
    String? vehicleMake,
    String? subCategory,
    String? size,
  }) async {
    return _partsDataService.getVehicleModels(
      vehicleMake: vehicleMake,
      subCategory: subCategory,
      size: size,
    );
  }

  static Future<List<String>> getCategories({
    String? vehicleMake,
    String? vehicleModel,
    String? size,
  }) async {
    return _partsDataService.getCategories(
      vehicleMake: vehicleMake,
      vehicleModel: vehicleModel,
      size: size,
    );
  }

  static Future<List<String>> getSubCategories({
    String? category,
    String? vehicleMake,
    String? vehicleModel,
    String? size,
  }) async {
    return _partsDataService.getSubCategories(
      category: category,
      vehicleMake: vehicleMake,
      vehicleModel: vehicleModel,
      size: size,
    );
  }

  static Future<List<String>> getTypes({
    String? vehicleMake,
    String? vehicleModel,
    String? subCategory,
    String? size,
  }) async {
    return _partsDataService.getTypes(
      vehicleMake: vehicleMake,
      vehicleModel: vehicleModel,
      subCategory: subCategory,
      size: size,
    );
  }

  static Future<List<String>> getSizes({
    String? vehicleMake,
    String? vehicleModel,
    String? subCategory,
    String? type,
  }) async {
    return _partsDataService.getSizes(
      vehicleMake: vehicleMake,
      vehicleModel: vehicleModel,
      subCategory: subCategory,
      type: type,
    );
  }

  static Future<List<String>> getBrands() async {
    return _partsDataService.getBrands();
  }

  static Future<List<Part>> searchParts({
    String? query,
    String? vehicleMake,
    String? vehicleModel,
    String? category,
    String? subCategory,
    String? type,
    String? size,
    String? brand,
  }) async {
    return _partsDataService.searchParts(
      query: query,
      vehicleMake: vehicleMake,
      vehicleModel: vehicleModel,
      category: category,
      subCategory: subCategory,
      type: type,
      size: size,
      brand: brand,
    );
  }
}
