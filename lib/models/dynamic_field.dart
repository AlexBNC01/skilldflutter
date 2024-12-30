// lib/models/dynamic_field.dart
import 'dart:convert';

class DynamicField {
  final int? id;
  final String entity; // 'products' или 'expenses'
  final String fieldName;
  final String fieldLabel;
  final String fieldType; // 'text', 'number', 'dropdown'
  final String? module;
  final List<String>? options; // Для 'dropdown' типа

  DynamicField({
    this.id,
    required this.entity,
    required this.fieldName,
    required this.fieldLabel,
    required this.fieldType,
    this.module,
    this.options,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entity': entity,
      'field_name': fieldName,
      'field_label': fieldLabel,
      'field_type': fieldType,
      'module': module,
      'options': options != null ? jsonEncode(options) : null,
    };
  }

  factory DynamicField.fromMap(Map<String, dynamic> map) {
    return DynamicField(
      id: map['id'] as int?,
      entity: map['entity'] as String,
      fieldName: map['field_name'] as String,
      fieldLabel: map['field_label'] as String,
      fieldType: map['field_type'] as String,
      module: map['module'] as String?,
      options: map['options'] != null
          ? List<String>.from(jsonDecode(map['options']))
          : null,
    );
  }
}