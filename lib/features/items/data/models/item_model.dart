class ItemModel {
  final String? id;
  final String? name;
  final String? description;
  final String? category;
  final String? subCategory;
  final String? brand;
  final String? model;
  final String? size;
  final String? unit;
  final double? price;
  final int? stock;
  final String? imageUrl;
  final String? status;
  final String? vehicleMake;
  final String? vehicleModel;
  final String? partType;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ItemModel({
    this.id,
    this.name,
    this.description,
    this.category,
    this.subCategory,
    this.brand,
    this.model,
    this.size,
    this.unit,
    this.price,
    this.stock,
    this.imageUrl,
    this.status,
    this.vehicleMake,
    this.vehicleModel,
    this.partType,
    this.createdAt,
    this.updatedAt,
  });

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    // API response structure: itemid, itemname, itemdesc
    final itemId =
        json['itemid']?.toString() ??
        json['id']?.toString() ??
        json['ID']?.toString();
    final itemName =
        json['itemname']?.toString() ??
        json['name']?.toString() ??
        json['Name']?.toString();
    final itemDesc =
        json['itemdesc']?.toString() ??
        json['description']?.toString() ??
        json['Description']?.toString();

    // Generate mock data for filtering based on item name and description
    final mockData = _generateMockData(itemName, itemDesc);

    return ItemModel(
      id: itemId,
      name: itemName,
      description: itemDesc,
      category:
          json['category']?.toString() ??
          json['Category']?.toString() ??
          mockData['category'],
      subCategory:
          json['subCategory']?.toString() ??
          json['SubCategory']?.toString() ??
          mockData['subCategory'],
      brand:
          json['brand']?.toString() ??
          json['Brand']?.toString() ??
          mockData['brand'],
      model:
          json['model']?.toString() ??
          json['Model']?.toString() ??
          mockData['model'],
      size:
          json['size']?.toString() ??
          json['Size']?.toString() ??
          mockData['size'],
      unit:
          json['unit']?.toString() ??
          json['Unit']?.toString() ??
          mockData['unit'],
      price: _parseDouble(json['price'] ?? json['Price']) ?? mockData['price'],
      stock: _parseInt(json['stock'] ?? json['Stock']) ?? mockData['stock'],
      imageUrl: json['imageUrl']?.toString() ?? json['ImageUrl']?.toString(),
      status:
          json['status']?.toString() ??
          json['Status']?.toString() ??
          'Available',
      vehicleMake:
          json['vehicleMake']?.toString() ??
          json['VehicleMake']?.toString() ??
          mockData['vehicleMake'],
      vehicleModel:
          json['vehicleModel']?.toString() ??
          json['VehicleModel']?.toString() ??
          mockData['vehicleModel'],
      partType:
          json['partType']?.toString() ??
          json['PartType']?.toString() ??
          mockData['partType'],
      createdAt:
          _parseDateTime(json['createdAt'] ?? json['CreatedAt']) ??
          DateTime.now(),
      updatedAt:
          _parseDateTime(json['updatedAt'] ?? json['UpdatedAt']) ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'subCategory': subCategory,
      'brand': brand,
      'model': model,
      'size': size,
      'unit': unit,
      'price': price,
      'stock': stock,
      'imageUrl': imageUrl,
      'status': status,
      'vehicleMake': vehicleMake,
      'vehicleModel': vehicleModel,
      'partType': partType,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /// Generate mock data for filtering based on item name and description
  static Map<String, dynamic> _generateMockData(
    String? itemName,
    String? itemDesc,
  ) {
    final name = (itemName ?? '').toLowerCase();
    final desc = (itemDesc ?? '').toLowerCase();

    // Vehicle makes based on common truck manufacturers
    final vehicleMakes = [
      'Ashok Leyland',
      'Tata Motors',
      'Mahindra',
      'BharatBenz',
      'Volvo',
      'Eicher',
    ];
    final vehicleModels = ['1015', '1613', '2516', '3118', '4018', '4923'];
    final categories = [
      'Engine Parts',
      'Brake System',
      'Transmission',
      'Electrical',
      'Body Parts',
      'Suspension',
    ];
    final subCategories = [
      'Filter',
      'Pump',
      'Belt',
      'Gasket',
      'Sensor',
      'Valve',
      'Cable',
      'Hose',
    ];
    final partTypes = ['Original', 'Aftermarket', 'OEM', 'Replacement'];
    final sizes = ['Small', 'Medium', 'Large', 'Extra Large'];
    final brands = [
      'Bosch',
      'Delphi',
      'Continental',
      'Denso',
      'Valeo',
      'Magneti Marelli',
    ];

    // Generate consistent data based on item name hash
    final hash = (name + desc).hashCode;
    final makeIndex = hash.abs() % vehicleMakes.length;
    final modelIndex = (hash.abs() ~/ 10) % vehicleModels.length;
    final categoryIndex = (hash.abs() ~/ 100) % categories.length;
    final subCategoryIndex = (hash.abs() ~/ 1000) % subCategories.length;
    final typeIndex = (hash.abs() ~/ 10000) % partTypes.length;
    final sizeIndex = (hash.abs() ~/ 100000) % sizes.length;
    final brandIndex = (hash.abs() ~/ 1000000) % brands.length;

    return {
      'vehicleMake': vehicleMakes[makeIndex],
      'vehicleModel': vehicleModels[modelIndex],
      'category': categories[categoryIndex],
      'subCategory': subCategories[subCategoryIndex],
      'partType': partTypes[typeIndex],
      'size': sizes[sizeIndex],
      'brand': brands[brandIndex],
      'price':
          100.0 + (hash.abs() % 10000) / 100.0, // Random price between 100-200
      'stock': 1 + (hash.abs() % 50), // Random stock between 1-50
    };
  }

  @override
  String toString() {
    return 'ItemModel(id: $id, name: $name, price: $price, stock: $stock)';
  }
}
