// lib/screens/dynamic_fields_screen.dart
import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/dynamic_field.dart';

class DynamicFieldsScreen extends StatefulWidget {
  const DynamicFieldsScreen({Key? key}) : super(key: key);

  @override
  State<DynamicFieldsScreen> createState() => _DynamicFieldsScreenState();
}

class _DynamicFieldsScreenState extends State<DynamicFieldsScreen> {
  final DatabaseService _db = DatabaseService();
  List<DynamicField> _fields = [];
  final TextEditingController _fieldNameController = TextEditingController();
  final TextEditingController _fieldLabelController = TextEditingController();
  final TextEditingController _optionsController = TextEditingController();
  String _selectedEntity = 'products'; // Default entity
  String _selectedFieldType = 'text'; // Default field type

  @override
  void initState() {
    super.initState();
    _loadFields();
  }

  Future<void> _loadFields() async {
    final fields = await _db.getDynamicFields(_selectedEntity);
    setState(() {
      _fields = fields;
    });
  }

  Future<void> _showAddFieldDialog() async {
    _fieldNameController.clear();
    _fieldLabelController.clear();
    _optionsController.clear();
    _selectedFieldType = 'text';

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Добавить Динамическое Поле'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedEntity,
                  items: const [
                    DropdownMenuItem(value: 'products', child: Text('Продукты')),
                    DropdownMenuItem(value: 'expenses', child: Text('Расходы')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedEntity = value;
                      });
                    }
                  },
                  decoration: const InputDecoration(labelText: 'Сущность'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _fieldNameController,
                  decoration: const InputDecoration(labelText: 'Имя поля'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _fieldLabelController,
                  decoration: const InputDecoration(labelText: 'Метка поля'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedFieldType,
                  items: const [
                    DropdownMenuItem(value: 'text', child: Text('Текст')),
                    DropdownMenuItem(value: 'number', child: Text('Число')),
                    DropdownMenuItem(value: 'dropdown', child: Text('Выпадающий список')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedFieldType = value;
                      });
                    }
                  },
                  decoration: const InputDecoration(labelText: 'Тип поля'),
                ),
                if (_selectedFieldType == 'dropdown')
                  TextField(
                    controller: _optionsController,
                    decoration: const InputDecoration(
                      labelText: 'Опции (через запятую)',
                      hintText: 'Например: option1, option2, option3',
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () async {
                final entity = _selectedEntity;
                final fieldName = _fieldNameController.text.trim();
                final fieldLabel = _fieldLabelController.text.trim();
                final fieldType = _selectedFieldType;
                List<String>? options;

                if (fieldType == 'dropdown') {
                  options = _optionsController.text
                      .split(',')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList();
                  if (options.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Пожалуйста, добавьте опции для выпадающего списка.')),
                    );
                    return;
                  }
                }

                if (entity.isEmpty || fieldName.isEmpty || fieldLabel.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Пожалуйста, заполните все обязательные поля.')),
                  );
                  return;
                }

                final newField = DynamicField(
                  entity: entity,
                  fieldName: fieldName,
                  fieldLabel: fieldLabel,
                  fieldType: fieldType,
                  options: options,
                );

                try {
                  await _db.insertDynamicField(newField);
                  await _loadFields();
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка добавления поля: $e')),
                  );
                }
              },
              child: const Text('Добавить'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditFieldDialog(DynamicField field) async {
    _selectedEntity = field.entity;
    _fieldNameController.text = field.fieldName;
    _fieldLabelController.text = field.fieldLabel;
    _selectedFieldType = field.fieldType;
    _optionsController.text = field.options != null ? field.options!.join(', ') : '';

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Редактировать Динамическое Поле'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedEntity,
                  items: const [
                    DropdownMenuItem(value: 'products', child: Text('Продукты')),
                    DropdownMenuItem(value: 'expenses', child: Text('Расходы')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedEntity = value;
                      });
                    }
                  },
                  decoration: const InputDecoration(labelText: 'Сущность'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _fieldNameController,
                  decoration: const InputDecoration(labelText: 'Имя поля'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _fieldLabelController,
                  decoration: const InputDecoration(labelText: 'Метка поля'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedFieldType,
                  items: const [
                    DropdownMenuItem(value: 'text', child: Text('Текст')),
                    DropdownMenuItem(value: 'number', child: Text('Число')),
                    DropdownMenuItem(value: 'dropdown', child: Text('Выпадающий список')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedFieldType = value;
                      });
                    }
                  },
                  decoration: const InputDecoration(labelText: 'Тип поля'),
                ),
                if (_selectedFieldType == 'dropdown')
                  TextField(
                    controller: _optionsController,
                    decoration: const InputDecoration(
                      labelText: 'Опции (через запятую)',
                      hintText: 'Например: option1, option2, option3',
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () async {
                final entity = _selectedEntity;
                final fieldName = _fieldNameController.text.trim();
                final fieldLabel = _fieldLabelController.text.trim();
                final fieldType = _selectedFieldType;
                List<String>? options;

                if (fieldType == 'dropdown') {
                  options = _optionsController.text
                      .split(',')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList();
                  if (options.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Пожалуйста, добавьте опции для выпадающего списка.')),
                    );
                    return;
                  }
                }

                if (entity.isEmpty || fieldName.isEmpty || fieldLabel.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Пожалуйста, заполните все обязательные поля.')),
                  );
                  return;
                }

                final updatedField = DynamicField(
                  id: field.id,
                  entity: entity,
                  fieldName: fieldName,
                  fieldLabel: fieldLabel,
                  fieldType: fieldType,
                  options: options,
                );

                try {
                  await _db.updateDynamicField(updatedField);
                  await _loadFields();
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка обновления поля: $e')),
                  );
                }
              },
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDeleteField(DynamicField field) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Удалить Динамическое Поле'),
          content: Text('Вы уверены, что хотите удалить поле "${field.fieldLabel}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Удалить'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await _db.deleteDynamicField(field.id!);
        await _loadFields();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка удаления поля: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление динамическими полями'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedEntity,
              items: const [
                DropdownMenuItem(value: 'products', child: Text('Продукты')),
                DropdownMenuItem(value: 'expenses', child: Text('Расходы')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedEntity = value;
                  });
                  _loadFields();
                }
              },
              decoration: const InputDecoration(labelText: 'Сущность'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _showAddFieldDialog,
              child: const Text('Добавить поле'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _fields.isEmpty
                  ? const Center(child: Text('Нет динамических полей для этой сущности.'))
                  : ListView.builder(
                      itemCount: _fields.length,
                      itemBuilder: (context, index) {
                        final field = _fields[index];
                        return Card(
                          child: ListTile(
                            title: Text(field.fieldLabel),
                            subtitle: Text('Имя: ${field.fieldName}, Тип: ${field.fieldType}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _showEditFieldDialog(field),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _confirmDeleteField(field),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}