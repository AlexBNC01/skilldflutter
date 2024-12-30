// lib/models/expense.dart
import 'dart:convert';

class Expense {
  final int? id;
  final int productId;
  final int quantity;
  final String date;
  final Map<String, dynamic>? dynamicFields;
  final int? categoryId;
  final int? typeId;
  final int? techId;
  final int? containerId;
  final String? barcode; // Новое поле
  final String? reason;   // Новое поле

  Expense({
    this.id,
    required this.productId,
    required this.quantity,
    required this.date,
    this.dynamicFields,
    this.categoryId,
    this.typeId,
    this.techId,
    this.containerId,
    this.barcode,
    this.reason,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'quantity': quantity,
      'date': date,
      'dynamic_fields': dynamicFields != null ? jsonEncode(dynamicFields) : null,
      'category_id': categoryId,
      'type_id': typeId,
      'tech_id': techId,
      'container_id': containerId,
      'barcode': barcode,
      'reason': reason,
    };
  }

  static Expense fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      productId: map['product_id'] as int,
      quantity: map['quantity'] as int,
      date: map['date'] as String,
      dynamicFields: map['dynamic_fields'] != null
          ? jsonDecode(map['dynamic_fields']) as Map<String, dynamic>
          : null,
      categoryId: map['category_id'] as int?,
      typeId: map['type_id'] as int?,
      techId: map['tech_id'] as int?,
      containerId: map['container_id'] as int?,
      barcode: map['barcode'] as String?,
      reason: map['reason'] as String?,
    );
  }
}