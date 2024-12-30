// lib/screens/add_product_screen.dart
import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/product.dart';
import '../models/dynamic_field.dart';
import '../models/container_model.dart'; // Импорт модели контейнера
import 'dart:convert';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({Key? key}) : super(key: key);

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final DatabaseService _databaseService = DatabaseService();
  
  // Контроллеры для стандартных полей
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  // Добавьте другие контроллеры для дополнительных стандартных полей, если необходимо

  // Для динамических полей
  List<DynamicField> _dynamicFields = [];
  final Map<String, TextEditingController> _dynamicControllers = {};

  // Для выбора контейнера
  List<WarehouseContainer> _availableContainers = [];
  int? _selectedContainerId;

  @override
  void initState() {
    super.initState();
    _loadDynamicFields();
    _loadContainers();
  }

  // Загрузка динамических полей для продуктов
  Future<void> _loadDynamicFields() async {
    final fields = await _databaseService.getDynamicFields('products');
    setState(() {
      _dynamicFields = fields;
      for (var field in _dynamicFields) {
        _dynamicControllers[field.fieldName] = TextEditingController();
      }
    });
  }

  // Загрузка доступных контейнеров из базы данных
  Future<void> _loadContainers() async {
    final containers = await _databaseService.getContainers();
    setState(() {
      _availableContainers = containers;
    });
  }

  // Метод для отправки данных продукта
  Future<void> _submitProduct() async {
    // Валидация обязательных стандартных полей
    if (_nameController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _quantityController.text.isEmpty ||
        _selectedContainerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, заполните все обязательные поля.')),
      );
      return;
    }

    // Сбор данных из динамических полей
    final dynamicValues = <String, dynamic>{};
    for (var field in _dynamicFields) {
      if (field.fieldType == 'dropdown') {
        dynamicValues[field.fieldName] =
            _dynamicControllers[field.fieldName]?.text.trim() ?? '';
      } else if (field.fieldType == 'number') {
        dynamicValues[field.fieldName] =
            int.tryParse(_dynamicControllers[field.fieldName]?.text.trim() ?? '');
      } else { // По умолчанию текстовое поле
        dynamicValues[field.fieldName] =
            _dynamicControllers[field.fieldName]?.text.trim() ?? '';
      }
    }

    // Создание объекта продукта с обязательным параметром containerId
    final product = Product(
      name: _nameController.text.trim(),
      price: double.parse(_priceController.text.trim()),
      quantity: int.parse(_quantityController.text.trim()),
      containerId: _selectedContainerId!,
      // Добавьте другие стандартные поля, если они есть
      dynamicFields: dynamicValues,
      // Заполните другие поля по необходимости
    );

    try {
      await _databaseService.insertProduct(product);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Товар добавлен')),
      );
      Navigator.pop(context, true); // Возвращаем true для обновления списка товаров
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при добавлении товара: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Добавить Товар')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              // Стандартные поля
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Название *'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Цена *'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Количество *'),
              ),
              const SizedBox(height: 10),
              // Выбор контейнера
              DropdownButtonFormField<int>(
                value: _selectedContainerId,
                hint: const Text('Выберите контейнер *'),
                items: _availableContainers.map((container) {
                  return DropdownMenuItem<int>(
                    value: container.id,
                    child: Text(container.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedContainerId = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              // Динамические поля
              const Text('Дополнительные Поля', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ..._dynamicFields.map((field) {
                if (field.fieldType == 'dropdown') {
                  return DropdownButtonFormField<String>(
                    decoration: InputDecoration(labelText: field.fieldLabel),
                    items: field.options != null
                        ? field.options!.map((option) {
                            return DropdownMenuItem<String>(
                              value: option,
                              child: Text(option),
                            );
                          }).toList()
                        : [],
                    onChanged: (value) {
                      _dynamicControllers[field.fieldName]?.text = value ?? '';
                    },
                  );
                } else if (field.fieldType == 'number') {
                  return TextField(
                    controller: _dynamicControllers[field.fieldName],
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: field.fieldLabel),
                  );
                } else { // По умолчанию текстовое поле
                  return TextField(
                    controller: _dynamicControllers[field.fieldName],
                    decoration: InputDecoration(labelText: field.fieldLabel),
                  );
                }
              }).toList(),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitProduct,
                child: const Text('Сохранить Товар'),
              ),
            ],
          ),
        ));
  }
}