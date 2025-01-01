// lib/models/container_model.dart

import 'dart:convert';

class WarehouseContainer {
  final int? id;
  final String name;

  WarehouseContainer({
    this.id,
    required this.name,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  factory WarehouseContainer.fromMap(Map<String, dynamic> map) {
    return WarehouseContainer(
      id: map['id'] as int?,
      name: map['name'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory WarehouseContainer.fromJson(String source) =>
      WarehouseContainer.fromMap(json.decode(source));
}