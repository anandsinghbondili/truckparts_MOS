import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Service for managing persistent storage of filter selections
class FilterStorageService {
  static const String _storageKey = 'filter_selections';

  /// Save filter selections to persistent storage
  static Future<void> saveFilterSelections({
    String? vehicleMake,
    String? vehicleModel,
    String? subCategory,
    String? type,
    String? size,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final filterData = {
        'vehicleMake': vehicleMake,
        'vehicleModel': vehicleModel,
        'subCategory': subCategory,
        'type': type,
        'size': size,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final filterJson = json.encode(filterData);
      await prefs.setString(_storageKey, filterJson);

      print('💾 FilterStorageService: Saved filter selections');
      print('   - Vehicle Make: $vehicleMake');
      print('   - Vehicle Model: $vehicleModel');
      print('   - Sub Category: $subCategory');
      print('   - Type: $type');
      print('   - Size: $size');
    } catch (e) {
      print('❌ FilterStorageService: Error saving filter selections: $e');
    }
  }

  /// Load filter selections from persistent storage
  static Future<Map<String, String?>> loadFilterSelections() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final filterJson = prefs.getString(_storageKey);

      if (filterJson != null && filterJson.isNotEmpty) {
        final filterData = json.decode(filterJson) as Map<String, dynamic>;

        final selections = {
          'vehicleMake': filterData['vehicleMake']?.toString(),
          'vehicleModel': filterData['vehicleModel']?.toString(),
          'subCategory': filterData['subCategory']?.toString(),
          'type': filterData['type']?.toString(),
          'size': filterData['size']?.toString(),
        };

        print('📂 FilterStorageService: Loaded filter selections');
        print('   - Vehicle Make: ${selections['vehicleMake']}');
        print('   - Vehicle Model: ${selections['vehicleModel']}');
        print('   - Sub Category: ${selections['subCategory']}');
        print('   - Type: ${selections['type']}');
        print('   - Size: ${selections['size']}');

        return selections;
      } else {
        print('📂 FilterStorageService: No filter selections found in storage');
        return {
          'vehicleMake': null,
          'vehicleModel': null,
          'subCategory': null,
          'type': null,
          'size': null,
        };
      }
    } catch (e) {
      print('❌ FilterStorageService: Error loading filter selections: $e');
      return {
        'vehicleMake': null,
        'vehicleModel': null,
        'subCategory': null,
        'type': null,
        'size': null,
      };
    }
  }

  /// Clear filter selections from persistent storage
  static Future<void> clearFilterSelections() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      print('🗑️ FilterStorageService: Cleared filter selections from storage');
    } catch (e) {
      print('❌ FilterStorageService: Error clearing filter selections: $e');
    }
  }

  /// Check if filter selections exist in storage
  static Future<bool> hasFilterSelections() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final filterJson = prefs.getString(_storageKey);
      return filterJson != null && filterJson.isNotEmpty;
    } catch (e) {
      print('❌ FilterStorageService: Error checking filter selections: $e');
      return false;
    }
  }
}
