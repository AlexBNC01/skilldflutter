// lib/models/product.dart
import 'dart:convert';

class Product {
  final int? id;
  final String name;
  final double price;
  final int quantity;
  final int containerId;
  final String? imagePaths;
  final int? categoryId;
  final int? subcategoryId1;
  final int? subcategoryId2;
  final String? displayName;
  final String? number;
  final String? barcode; // Поле теперь nullable
  final double? volume;
  final int? typeId;
  final int? techId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  Map<String, dynamic>? dynamicFields;

  // Добавлено новое поле
  final String? categoryName;
  final String? typeName;
  final String? techName;

  Product({
    this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.containerId,
    this.imagePaths,
    this.categoryId,
    this.subcategoryId1,
    this.subcategoryId2,
    this.displayName,
    this.number,
    this.barcode, // Поле теперь необязательное
    this.volume,
    this.typeId,
    this.techId,
    this.createdAt,
    this.updatedAt,
    this.dynamicFields,
    this.categoryName, // Инициализация нового поля
    this.typeName,
    this.techName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
      'container_id': containerId,
      'image_paths': imagePaths,
      'category_id': categoryId,
      'subcategory_id1': subcategoryId1,
      'subcategory_id2': subcategoryId2,
      'display_name': displayName,
      'number': number,
      'barcode': barcode, // Может быть null
      'volume': volume,
      'type_id': typeId,
      'tech_id': techId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'dynamic_fields': dynamicFields != null ? jsonEncode(dynamicFields) : null,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      quantity: map['quantity'] as int,
      containerId: map['container_id'] as int,
      imagePaths: map['image_paths'] as String?,
      categoryId: map['category_id'] as int?,
      subcategoryId1: map['subcategory_id1'] as int?,
      subcategoryId2: map['subcategory_id2'] as int?,
      displayName: map['display_name'] as String?,
      number: map['number'] as String?,
      barcode: map['barcode'] as String?, // Nullable
      volume: map['volume'] != null ? (map['volume'] as num).toDouble() : null,
      typeId: map['type_id'] as int?,
      techId: map['tech_id'] as int?,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
      dynamicFields: map['dynamic_fields'] != null
          ? jsonDecode(map['dynamic_fields']) as Map<String, dynamic>
          : null,
      categoryName: map['categoryName'] as String?, // Инициализация нового поля
      typeName: map['typeName'] as String?,
      techName: map['techName'] as String?,
    );
  }

  List<String> get imagePathsList {
    if (imagePaths == null || imagePaths!.isEmpty) {
      return [];
    }
    return imagePaths!.split(',').map((path) => path.trim()).toList();
  }
}