// lib/models/inventory_log.dart

import 'dart:convert';

class InventoryLog {
  final int? id;
  final int productId;
  final String changeType; // 'increase' или 'decrease'
  final int quantity;
  final String date;
  final String? reason;

  InventoryLog({
    this.id,
    required this.productId,
    required this.changeType,
    required this.quantity,
    required this.date,
    this.reason,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'change_type': changeType,
      'quantity': quantity,
      'date': date,
      'reason': reason,
    };
  }

  factory InventoryLog.fromMap(Map<String, dynamic> map) {
    return InventoryLog(
      id: map['id'] as int?,
      productId: map['product_id'] as int,
      changeType: map['change_type'] as String,
      quantity: map['quantity'] as int,
      date: map['date'] as String,
      reason: map['reason'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory InventoryLog.fromJson(String source) =>
      InventoryLog.fromMap(json.decode(source));
}