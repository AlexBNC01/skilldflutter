// lib/screens/add_dynamic_field_screen.dart

import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/dynamic_field.dart';

class AddDynamicFieldScreen extends StatefulWidget {
  const AddDynamicFieldScreen({Key? key}) : super(key: key);

  @override
  State<AddDynamicFieldScreen> createState() => _AddDynamicFieldScreenState();
}

class _AddDynamicFieldScreenState extends State<AddDynamicFieldScreen> {
  final DatabaseService _db = DatabaseService();
  final _formKey = GlobalKey<FormState>();

  String _entity = 'products';
  String _fieldName = '';
  String _fieldLabel = '';
  String _fieldType = 'text';
  String? _module;
  List<String> _options = [];

  final TextEditingController _optionController = TextEditingController();

  void _addOption() {
    final option = _optionController.text.trim();
    if (option.isNotEmpty && !_options.contains(option)) {
      setState(() {
        _options.add(option);
      });
      _optionController.clear();
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final dynamicField = DynamicField(
        entity: _entity,
        fieldName: _fieldName,
        fieldLabel: _fieldLabel,
        fieldType: _fieldType,
        module: _module,
        options: _fieldType == 'dropdown' ? _options : null,
      );

      try {
        await _db.insertDynamicField(dynamicField);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Динамическое поле добавлено')),
        );
        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при добавлении поля: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _optionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Добавить Динамическое Поле'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Поле выбора сущности
              DropdownButtonFormField<String>(
                value: _entity,
                items: [
                  DropdownMenuItem(value: 'products', child: Text('Продукты')),
                  DropdownMenuItem(value: 'expenses', child: Text('Расходы')),
                  // Добавьте другие сущности по необходимости
                ],
                onChanged: (value) {
                  setState(() {
                    _entity = value!;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Сущность',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16.0),

              // Поле имени
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Имя поля',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Пожалуйста, введите имя поля';
                  }
                  return null;
                },
                onChanged: (value) {
                  _fieldName = value.trim();
                },
              ),
              SizedBox(height: 16.0),

              // Поле метки
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Метка поля',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Пожалуйста, введите метку поля';
                  }
                  return null;
                },
                onChanged: (value) {
                  _fieldLabel = value.trim();
                },
              ),
              SizedBox(height: 16.0),

              // Поле типа
              DropdownButtonFormField<String>(
                value: _fieldType,
                items: [
                  DropdownMenuItem(value: 'text', child: Text('Текст')),
                  DropdownMenuItem(value: 'number', child: Text('Число')),
                  DropdownMenuItem(value: 'dropdown', child: Text('Выпадающий список')),
                  // Добавьте другие типы по необходимости
                ],
                onChanged: (value) {
                  setState(() {
                    _fieldType = value!;
                    if (_fieldType != 'dropdown') {
                      _options.clear();
                    }
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Тип поля',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16.0),

              // Поле модуля (опционально)
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Модуль (опционально)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  _module = value.trim().isEmpty ? null : value.trim();
                },
              ),
              SizedBox(height: 16.0),

              // Поля опций для dropdown
              if (_fieldType == 'dropdown') ...[
                Text(
                  'Опции:',
                  style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8.0),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _optionController,
                        decoration: InputDecoration(
                          labelText: 'Добавить опцию',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.0),
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: _addOption,
                    ),
                  ],
                ),
                SizedBox(height: 8.0),
                Wrap(
                  spacing: 8.0,
                  children: _options
                      .map((option) => Chip(
                            label: Text(option),
                            onDeleted: () {
                              setState(() {
                                _options.remove(option);
                              });
                            },
                          ))
                      .toList(),
                ),
                SizedBox(height: 16.0),
              ],

              // Кнопка отправки
              ElevatedButton(
                onPressed: _submit,
                child: Text('Добавить поле'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}