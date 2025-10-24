import 'dart:convert';
import 'package:flutter/services.dart';

import '../../domain/entities/part.dart';
import '../models/part_model.dart';

abstract class PartsLocalDataSource {
  Future<List<Part>> getAllParts();
  Future<List<Part>> getPartsByCategory(String category);
  Future<List<Part>> getPartsByBrand(String brand);
  Future<List<Part>> getPartsByVehicleMake(String vehicleMake);
  Future<List<Part>> searchParts(String query);
  Future<List<String>> getCategories();
  Future<List<String>> getBrands();
  Future<List<String>> getVehicleMakes();
}

class PartsLocalDataSourceImpl implements PartsLocalDataSource {
  List<Part>? _cachedParts;
  Map<String, dynamic>? _cachedData;

  Future<Map<String, dynamic>> _loadJsonData() async {
    if (_cachedData != null) return _cachedData!;

    try {
      final String jsonString = await rootBundle.loadString(
        'assets/data/parts_data.json',
      );
      _cachedData = json.decode(jsonString) as Map<String, dynamic>;
      return _cachedData!;
    } catch (e) {
      throw Exception('Failed to load parts data: $e');
    }
  }

  Future<List<Part>> _getAllPartsFromCache() async {
    if (_cachedParts != null) return _cachedParts!;

    final data = await _loadJsonData();
    final partsList = data['parts'] as List<dynamic>;

    _cachedParts = partsList
        .map(
          (partJson) =>
              PartModel.fromJson(partJson as Map<String, dynamic>).toEntity(),
        )
        .toList();

    return _cachedParts!;
  }

  @override
  Future<List<Part>> getAllParts() async {
    return await _getAllPartsFromCache();
  }

  @override
  Future<List<Part>> getPartsByCategory(String category) async {
    final allParts = await _getAllPartsFromCache();
    return allParts
        .where(
          (part) =>
              part.category.toLowerCase().contains(category.toLowerCase()),
        )
        .toList();
  }

  @override
  Future<List<Part>> getPartsByBrand(String brand) async {
    final allParts = await _getAllPartsFromCache();
    return allParts
        .where((part) => part.brand.toLowerCase().contains(brand.toLowerCase()))
        .toList();
  }

  @override
  Future<List<Part>> getPartsByVehicleMake(String vehicleMake) async {
    final allParts = await _getAllPartsFromCache();
    return allParts
        .where(
          (part) => part.vehicleMake.toLowerCase().contains(
            vehicleMake.toLowerCase(),
          ),
        )
        .toList();
  }

  @override
  Future<List<Part>> searchParts(String query) async {
    final allParts = await _getAllPartsFromCache();
    final lowerQuery = query.toLowerCase();

    return allParts.where((part) {
      return part.category.toLowerCase().contains(lowerQuery) ||
          part.subCategory.toLowerCase().contains(lowerQuery) ||
          part.vehicleMake.toLowerCase().contains(lowerQuery) ||
          part.model.toLowerCase().contains(lowerQuery) ||
          part.part.toLowerCase().contains(lowerQuery) ||
          part.brand.toLowerCase().contains(lowerQuery) ||
          part.item.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  @override
  Future<List<String>> getCategories() async {
    final allParts = await _getAllPartsFromCache();
    final categories = allParts
        .map((part) => part.category)
        .where((category) => category.isNotEmpty)
        .toSet()
        .toList();
    categories.sort();
    return categories;
  }

  @override
  Future<List<String>> getBrands() async {
    final allParts = await _getAllPartsFromCache();
    final brands = allParts
        .map((part) => part.brand)
        .where((brand) => brand.isNotEmpty)
        .toSet()
        .toList();
    brands.sort();
    return brands;
  }

  @override
  Future<List<String>> getVehicleMakes() async {
    final allParts = await _getAllPartsFromCache();
    final vehicleMakes = allParts
        .map((part) => part.vehicleMake)
        .where((make) => make.isNotEmpty)
        .toSet()
        .toList();
    vehicleMakes.sort();
    return vehicleMakes;
  }
}
