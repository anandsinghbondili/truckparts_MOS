import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/part.dart';

// part 'part_model.g.dart';

@JsonSerializable()
class PartModel extends Part {
  const PartModel({
    required super.id,
    required super.category,
    required super.subCategory,
    required super.vehicleMake,
    required super.model,
    required super.type,
    required super.part,
    required super.size,
    required super.brand,
    required super.item,
    super.price,
    super.mrp,
    super.netPrice,
    super.imageUrl,
    super.description,
  });

  factory PartModel.fromJson(Map<String, dynamic> json) {
    return PartModel(
      id: json['id']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      subCategory: json['sub_category']?.toString() ?? '',
      vehicleMake: json['vehicle_make']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      part: json['part']?.toString() ?? '',
      size: json['size']?.toString() ?? '',
      brand: json['brand']?.toString() ?? '',
      item: json['item']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble(),
      mrp: (json['mrp'] as num?)?.toDouble(),
      netPrice: (json['net_price'] as num?)?.toDouble(),
      imageUrl: json['image_url']?.toString(),
      description: json['description']?.toString() ?? '',
    );
  }

  /// Factory constructor for ItemDetailsbyCustomer API response
  factory PartModel.fromApiJson(Map<String, dynamic> json) {
    final listPrice = _parsePrice(json['list_price']);
    final netPriceValue = _parsePrice(json['net_price']);

    return PartModel(
      id: json['itemid']?.toString() ?? '',
      item: json['itemname']?.toString() ?? '',
      description: json['itemdesc']?.toString() ?? '',
      vehicleMake: json['vehicle_make']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      subCategory: json['subcategory']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      part: json['part']?.toString() ?? '',
      size: json['size']?.toString() ?? '',
      brand: json['Brand']?.toString() ?? '',
      price:
          netPriceValue ??
          listPrice, // Fallback to list price if net price is null
      mrp: listPrice, // MRP is the list_price from API
      netPrice: netPriceValue, // Net Price is the discounted price from API
      imageUrl: null, // Not provided in API response
    );
  }

  /// Helper method to parse price from dynamic value
  static double? _parsePrice(dynamic priceValue) {
    if (priceValue != null && priceValue != 0.00) {
      if (priceValue is num) return priceValue.toDouble();
      if (priceValue is String) return double.tryParse(priceValue);
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'sub_category': subCategory,
      'vehicle_make': vehicleMake,
      'model': model,
      'type': type,
      'part': part,
      'size': size,
      'brand': brand,
      'item': item,
      'price': price,
      'mrp': mrp,
      'net_price': netPrice,
      'image_url': imageUrl,
      'description': description,
    };
  }

  factory PartModel.fromEntity(Part part) {
    return PartModel(
      id: part.id,
      category: part.category,
      subCategory: part.subCategory,
      vehicleMake: part.vehicleMake,
      model: part.model,
      type: part.type,
      part: part.part,
      size: part.size,
      brand: part.brand,
      item: part.item,
      price: part.price,
      mrp: part.mrp,
      netPrice: part.netPrice,
      imageUrl: part.imageUrl,
      description: part.description,
    );
  }

  Part toEntity() {
    return Part(
      id: id,
      category: category,
      subCategory: subCategory,
      vehicleMake: vehicleMake,
      model: model,
      type: type,
      part: part,
      size: size,
      brand: brand,
      item: item,
      price: price,
      mrp: mrp,
      netPrice: netPrice,
      imageUrl: imageUrl,
      description: description,
    );
  }
}
