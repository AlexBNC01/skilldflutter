// lib/models/product.dart

import 'dart:convert';

class Product {
  final int? id;
  final String name;
  final double price;
  final int quantity;
  final int? containerId; // Сделано nullable
  final String? imagePaths;
  final int? categoryId;
  final int? subcategoryId1;
  final int? subcategoryId2;
  final String? displayName;
  final String? number;
  final String? barcode; // Nullable
  final double? volume;
  final int? typeId;
  final int? techId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  Map<String, dynamic>? dynamicFields;

  // Новые поля для отображения имен категорий, типов, техников и контейнера
  final String? categoryName;
  final String? typeName;
  final String? techName;
  final String? containerName;

  Product({
    this.id,
    required this.name,
    required this.price,
    required this.quantity,
    this.containerId, // Nullable
    this.imagePaths,
    this.categoryId,
    this.subcategoryId1,
    this.subcategoryId2,
    this.displayName,
    this.number,
    this.barcode,
    this.volume,
    this.typeId,
    this.techId,
    this.createdAt,
    this.updatedAt,
    this.dynamicFields,
    this.categoryName,
    this.typeName,
    this.techName,
    this.containerName,
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
      'barcode': barcode,
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
      containerId: map['container_id'] as int?, // Изменено на nullable
      imagePaths: map['imagePaths'] as String?,
      categoryId: map['category_id'] as int?,
      subcategoryId1: map['subcategory_id1'] as int?,
      subcategoryId2: map['subcategory_id2'] as int?,
      displayName: map['displayName'] as String?,
      number: map['number'] as String?,
      barcode: map['barcode'] as String?,
      volume: map['volume'] != null ? (map['volume'] as num).toDouble() : null,
      typeId: map['type_id'] as int?,
      techId: map['tech_id'] as int?,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
      dynamicFields: map['dynamicFields'] != null
          ? jsonDecode(map['dynamicFields']) as Map<String, dynamic>
          : null,
      categoryName: map['categoryName'] as String?,
      typeName: map['typeName'] as String?,
      techName: map['techName'] as String?,
      containerName: map['containerName'] as String?, // Добавлено маппирование
    );
  }

  List<String> get imagePathsList {
    if (imagePaths == null || imagePaths!.isEmpty) {
      return [];
    }
    return imagePaths!.split(',').map((path) => path.trim()).toList();
  }
}