import 'package:equatable/equatable.dart';

class Part extends Equatable {
  final String id;
  final String category;
  final String subCategory;
  final String vehicleMake;
  final String model;
  final String type;
  final String part;
  final String size;
  final String brand;
  final String item;
  final double? price;
  final double? mrp; // Maximum Retail Price (list_price from API)
  final double? netPrice; // Discounted Price (net_price from API)
  final String? imageUrl;
  final String description;

  const Part({
    required this.id,
    required this.category,
    required this.subCategory,
    required this.vehicleMake,
    required this.model,
    required this.type,
    required this.part,
    required this.size,
    required this.brand,
    required this.item,
    this.price,
    this.mrp,
    this.netPrice,
    this.imageUrl,
    this.description = '',
  });

  @override
  List<Object?> get props => [
    id,
    category,
    subCategory,
    vehicleMake,
    model,
    type,
    part,
    size,
    brand,
    item,
    price,
    mrp,
    netPrice,
    imageUrl,
    description,
  ];

  Part copyWith({
    String? id,
    String? category,
    String? subCategory,
    String? vehicleMake,
    String? model,
    String? type,
    String? part,
    String? size,
    String? brand,
    String? item,
    double? price,
    double? mrp,
    double? netPrice,
    String? imageUrl,
    String? description,
  }) {
    return Part(
      id: id ?? this.id,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      vehicleMake: vehicleMake ?? this.vehicleMake,
      model: model ?? this.model,
      type: type ?? this.type,
      part: part ?? this.part,
      size: size ?? this.size,
      brand: brand ?? this.brand,
      item: item ?? this.item,
      price: price ?? this.price,
      mrp: mrp ?? this.mrp,
      netPrice: netPrice ?? this.netPrice,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
    );
  }

  String get displayName {
    if (part.isNotEmpty) {
      return part;
    } else if (subCategory.isNotEmpty) {
      return subCategory;
    } else {
      return category;
    }
  }

  String get fullDescription {
    final parts = <String>[];
    if (category.isNotEmpty) parts.add(category);
    if (subCategory.isNotEmpty) parts.add(subCategory);
    if (vehicleMake.isNotEmpty) parts.add(vehicleMake);
    if (model.isNotEmpty) parts.add(model);
    if (type.isNotEmpty) parts.add(type);
    if (part.isNotEmpty) parts.add(part);

    return parts.join(' • ');
  }
}
