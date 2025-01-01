// lib/screens/add_product_screen.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Импорт для выбора изображений
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart'; // Импорт для сканера штрихкодов
import '../services/database_service.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../models/container_model.dart';
import '../models/dynamic_field.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({Key? key}) : super(key: key);

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _volumeController = TextEditingController();
  // Добавьте другие контроллеры по необходимости

  int? _selectedCategoryId;
  int? _selectedTypeId;
  int? _selectedTechId;
  int? _selectedContainerId;

  List<Category> _categories = [];
  List<Category> _types = [];
  List<Category> _techs = [];
  List<WarehouseContainer> _containers = [];
  List<DynamicField> _dynamicFields = [];
  final Map<String, TextEditingController> _dynamicControllers = {};

  // Список путей к изображениям
  List<String> imagePathsList = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      print('Начинается загрузка начальных данных...');
      final categories = await _databaseService.getCategories();
      final types = await _databaseService.getTypes();
      final techs = await _databaseService.getTechs();
      final containers = await _databaseService.getContainers();
      final dynamicFields = await _databaseService.getDynamicFields('products');

      setState(() {
        _categories = categories;
        _types = types;
        _techs = techs;
        _containers = containers;
        _dynamicFields = dynamicFields;
        _isLoading = false;

        for (var field in _dynamicFields) {
          _dynamicControllers[field.fieldName] = TextEditingController();
        }
      });
      print('Начальные данные загружены успешно.');
    } catch (e) {
      print('Ошибка при загрузке начальных данных: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки данных: $e')),
      );
    }
  }

  Future<void> _pickImages() async {
    try {
      print('Начинается процесс выбора изображений...');
      final ImagePicker _picker = ImagePicker();
      final List<XFile>? images = await _picker.pickMultiImage();
      if (images != null && images.isNotEmpty) {
        setState(() {
          imagePathsList = images.map((image) => image.path).toList();
        });
        print('Изображения выбраны: $imagePathsList');
      } else {
        print('Изображения не выбраны.');
      }
    } catch (e) {
      print('Ошибка при выборе изображений: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при выборе изображений: $e')),
      );
    }
  }

  Future<void> _scanBarcode() async {
    try {
      String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          '#ff6666', // Цвет линии сканера
          'Отмена', // Текст кнопки отмены
          true, // Показывать ли всплывающее окно с подсказкой
          ScanMode.BARCODE // Режим сканирования (BARCODE или QR)
      );

      if (barcodeScanRes != '-1') { // '-1' означает, что сканирование было отменено
        setState(() {
          _barcodeController.text = barcodeScanRes;
        });
        print('Сканированный штрих-код: $barcodeScanRes');
      } else {
        print('Сканирование отменено пользователем.');
      }
    } catch (e) {
      print('Ошибка при сканировании штрихкода: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при сканировании штрихкода: $e')),
      );
    }
  }

  Future<void> _addProduct() async {
    final String name = _nameController.text.trim();
    final double? price = double.tryParse(_priceController.text.trim());
    final int? quantity = int.tryParse(_quantityController.text.trim());
    final String? barcode = _barcodeController.text.trim().isNotEmpty
        ? _barcodeController.text.trim()
        : null;
    final double? volume = double.tryParse(_volumeController.text.trim());

    print('Пытаемся добавить продукт:');
    print('Name: $name, Price: $price, Quantity: $quantity, Barcode: $barcode, Volume: $volume');
    print('Selected Category ID: $_selectedCategoryId');
    print('Selected Type ID: $_selectedTypeId');
    print('Selected Tech ID: $_selectedTechId');
    print('Selected Container ID: $_selectedContainerId');
    print('Image Paths: $imagePathsList');

    if (name.isEmpty || price == null || quantity == null) {
      print('Не заполнены обязательные поля.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, заполните все обязательные поля.')),
      );
      return;
    }

    if (_selectedContainerId == null) {
      print('Контейнер не выбран.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, выберите контейнер.')),
      );
      return;
    }

    // Проверка существования контейнера
    bool exists = await _databaseService.containerExists(_selectedContainerId!);
    if (!exists) {
      print('Контейнер с id $_selectedContainerId не существует.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Выбранный контейнер не существует.')),
      );
      return;
    }

    // Сбор динамических полей
    final Map<String, dynamic> dynamicValues = {};
    _dynamicFields.forEach((field) {
      final controller = _dynamicControllers[field.fieldName];
      if (controller != null) {
        if (field.fieldType == 'number') {
          dynamicValues[field.fieldName] = int.tryParse(controller.text.trim());
        } else {
          dynamicValues[field.fieldName] = controller.text.trim();
        }
      }
    });

    print('Динамические поля: $dynamicValues');

    // Преобразование списка путей к изображениям в строку (запятая-разделитель)
    String imagePathsString = imagePathsList.join(',');

    final Product newProduct = Product(
      name: name,
      price: price,
      quantity: quantity,
      containerId: _selectedContainerId!,
      barcode: barcode,
      volume: volume,
      categoryId: _selectedCategoryId,
      typeId: _selectedTypeId,
      techId: _selectedTechId,
      dynamicFields: dynamicValues,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      imagePaths: imagePathsString, // Преобразование списка в строку
    );

    print('Созданный объект продукта: ${newProduct.toMap()}');

    try {
      final int insertedId = await _databaseService.insertProduct(newProduct);
      print('Продукт успешно добавлен с ID: $insertedId');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Продукт добавлен успешно')),
      );
      Navigator.pop(context, true); // Возвращаем true для обновления списка продуктов
    } catch (e) {
      print('Ошибка при добавлении продукта: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при добавлении продукта: $e')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _barcodeController.dispose();
    _volumeController.dispose();
    _dynamicControllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Добавить Продукт'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Кнопка для выбора изображений
                  ElevatedButton(
                    onPressed: _pickImages,
                    child: const Text('Выбрать Изображения'),
                  ),
                  const SizedBox(height: 10),
                  // Отображение выбранных изображений
                  imagePathsList.isNotEmpty
                      ? SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: imagePathsList.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Image.file(
                                  File(imagePathsList[index]),
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              );
                            },
                          ),
                        )
                      : const SizedBox(),
                  const SizedBox(height: 10),
                  // Название продукта
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Название продукта *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Цена
                  TextField(
                    controller: _priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Цена *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Количество
                  TextField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Количество *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Штрих-код (необязательно) с кнопкой сканирования
                  TextField(
                    controller: _barcodeController,
                    decoration: InputDecoration(
                      labelText: 'Штрих-код (необязательно)',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.camera_alt),
                        onPressed: _scanBarcode,
                        tooltip: 'Сканировать штрих-код',
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Объём (необязательно)
                  TextField(
                    controller: _volumeController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Объём (необязательно)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Категория
                  DropdownButtonFormField<int>(
                    value: _selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'Категория',
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text('Выберите категорию'),
                    items: _categories.map((Category category) {
                      return DropdownMenuItem<int>(
                        value: category.id,
                        child: Text(category.name),
                      );
                    }).toList(),
                    onChanged: (int? newValue) {
                      setState(() {
                        _selectedCategoryId = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  // Тип
                  DropdownButtonFormField<int>(
                    value: _selectedTypeId,
                    decoration: const InputDecoration(
                      labelText: 'Тип',
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text('Выберите тип'),
                    items: _types.map((Category type) {
                      return DropdownMenuItem<int>(
                        value: type.id,
                        child: Text(type.name),
                      );
                    }).toList(),
                    onChanged: (int? newValue) {
                      setState(() {
                        _selectedTypeId = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  // Техника
                  DropdownButtonFormField<int>(
                    value: _selectedTechId,
                    decoration: const InputDecoration(
                      labelText: 'Техника',
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text('Выберите технику'),
                    items: _techs.map((Category tech) {
                      return DropdownMenuItem<int>(
                        value: tech.id,
                        child: Text(tech.name),
                      );
                    }).toList(),
                    onChanged: (int? newValue) {
                      setState(() {
                        _selectedTechId = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  // Контейнер
                  DropdownButtonFormField<int>(
                    value: _selectedContainerId,
                    decoration: const InputDecoration(
                      labelText: 'Контейнер',
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text('Выберите контейнер'),
                    items: _containers.map((WarehouseContainer container) {
                      return DropdownMenuItem<int>(
                        value: container.id,
                        child: Text(container.name),
                      );
                    }).toList(),
                    onChanged: (int? newValue) {
                      setState(() {
                        _selectedContainerId = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  // Динамические поля
                  const Text(
                    'Дополнительные Поля',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ..._dynamicFields.map((field) {
                    final controller = _dynamicControllers[field.fieldName];
                    if (field.fieldType == 'dropdown') {
                      // Обработка выпадающего списка
                      List<String> options = [];
                      if (field.options != null) {
                        try {
                          // Исправлено: убран jsonDecode, предполагается, что field.options уже List<String>
                          options = List<String>.from(field.options!);
                        } catch (e) {
                          print('Ошибка при преобразовании опций для поля ${field.fieldName}: $e');
                        }
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: DropdownButtonFormField<String>(
                          isExpanded: true, // Обеспечивает, что выпадающий список занимает всю доступную ширину
                          icon: const Icon(Icons.arrow_drop_down, size: 24),
                          value: controller?.text.isNotEmpty == true ? controller!.text : null,
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Все')),
                            ...options.map((String option) {
                              return DropdownMenuItem<String>(
                                value: option,
                                child: Text(option),
                              );
                            }).toList(),
                          ],
                          onChanged: (String? newValue) {
                            if (controller != null) {
                              controller.text = newValue ?? '';
                            }
                          },
                          decoration: InputDecoration(
                            labelText: field.fieldLabel,
                            border: const OutlineInputBorder(),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                          ),
                        ),
                      );
                    } else if (field.fieldType == 'number') {
                      // Обработка числового поля
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: TextField(
                          controller: controller,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: field.fieldLabel,
                            border: const OutlineInputBorder(),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                          ),
                        ),
                      );
                    } else {
                      // Обработка текстового поля
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: TextField(
                          controller: controller,
                          decoration: InputDecoration(
                            labelText: field.fieldLabel,
                            border: const OutlineInputBorder(),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                          ),
                        ),
                      );
                    }
                  }).toList(),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _addProduct,
                    child: const Text('Сохранить'),
                  ),
                ],
              ),
            ),
    );
  }
}

// Расширение для firstWhereOrNull, если нужно
extension IterableExtensions<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    for (E element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}