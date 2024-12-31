import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:image_picker/image_picker.dart'; // <-- нужен для выбора изображения
import '../services/database_service.dart';
import '../models/product.dart';
import '../models/dynamic_field.dart';
import '../models/container_model.dart'; 
import 'dart:convert';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({Key? key}) : super(key: key);

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final DatabaseService _databaseService = DatabaseService();
  
  // =========== Стандартные поля ============
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController(); // Для штрих-кода

  // =========== Динамические поля ============
  List<DynamicField> _dynamicFields = [];
  final Map<String, TextEditingController> _dynamicControllers = {};

  // =========== Фото ============
  List<String> _imagePaths = []; // Список путей к локальным фото

  // =========== Контейнер ============
  List<WarehouseContainer> _availableContainers = [];
  int? _selectedContainerId;

  @override
  void initState() {
    super.initState();
    _loadDynamicFields();
    _loadContainers();
  }

  // Загрузка динамических полей (entity = 'products')
  Future<void> _loadDynamicFields() async {
    final fields = await _databaseService.getDynamicFields('products');
    setState(() {
      _dynamicFields = fields;
      for (var field in _dynamicFields) {
        _dynamicControllers[field.fieldName] = TextEditingController();
      }
    });
  }

  // Загрузка контейнеров
  Future<void> _loadContainers() async {
    final containers = await _databaseService.getContainers();
    setState(() {
      _availableContainers = containers;
    });
  }

  // =========== Сканирование штрих-кода ============
  Future<void> _scanBarcode() async {
    try {
      const scanColor = '#ff6666';
      final barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
        scanColor,
        'Отмена',
        true,
        ScanMode.BARCODE,
      );
      if (!mounted) return;

      if (barcodeScanRes != '-1') {
        setState(() {
          _barcodeController.text = barcodeScanRes;
        });
        // Попробуем найти товар с таким штрих-кодом
        final existingProduct = await _databaseService.getProductByBarcode(barcodeScanRes);
        if (existingProduct != null) {
          // Заполняем поля из существующего товара
          setState(() {
            _nameController.text = existingProduct.name;
            _priceController.text = existingProduct.price.toString();
            _quantityController.text = existingProduct.quantity.toString();
            _selectedContainerId = existingProduct.containerId;

            // Если у товара уже есть фото, распарсим их в _imagePaths
            if (existingProduct.imagePaths != null && existingProduct.imagePaths!.isNotEmpty) {
              _imagePaths = existingProduct.imagePaths!.split(',');
            }

            // Заполняем динамические поля, если совпадают ключи
            final existingDyn = existingProduct.dynamicFields ?? {};
            existingDyn.forEach((k, v) {
              if (_dynamicControllers.containsKey(k)) {
                _dynamicControllers[k]!.text = v.toString();
              }
            });
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сканирования: $e')),
        );
      }
    }
  }

  // =========== Выбор изображения из галереи ============
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (!mounted) return;
    if (pickedFile != null) {
      setState(() {
        _imagePaths.add(pickedFile.path);
      });
    }
  }

  // =========== Сохранение товара ============
  Future<void> _submitProduct() async {
    // Проверяем обязательные поля
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
        dynamicValues[field.fieldName] = int.tryParse(
          _dynamicControllers[field.fieldName]?.text.trim() ?? '',
        );
      } else {
        dynamicValues[field.fieldName] =
            _dynamicControllers[field.fieldName]?.text.trim() ?? '';
      }
    }

    // Создаём объект Product
    final product = Product(
      name: _nameController.text.trim(),
      price: double.parse(_priceController.text.trim()),
      quantity: int.parse(_quantityController.text.trim()),
      containerId: _selectedContainerId!,
      // barcode (если пусто => null)
      barcode: _barcodeController.text.isNotEmpty
          ? _barcodeController.text.trim()
          : null,
      // Склеиваем пути в одну строку, разделяя запятыми
      imagePaths: _imagePaths.isEmpty ? null : _imagePaths.join(','),
      dynamicFields: dynamicValues,
    );

    try {
      await _databaseService.insertProduct(product);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Товар добавлен')),
      );
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при добавлении товара: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Добавить Товар'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // ========== Штрих-код + кнопка сканирования ==========
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _barcodeController,
                    decoration: const InputDecoration(
                      labelText: 'Штрих-код',
                      hintText: 'Отсканируйте или введите штрих-код',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.camera_alt),
                  onPressed: _scanBarcode,
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ========== Название ==========
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Название *'),
            ),
            const SizedBox(height: 10),

            // ========== Цена ==========
            TextField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Цена *'),
            ),
            const SizedBox(height: 10),

            // ========== Количество ==========
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Количество *'),
            ),
            const SizedBox(height: 10),

            // ========== Контейнер ==========
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

            // ========== Динамические поля ==========
            const Text(
              'Дополнительные Поля',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ..._dynamicFields.map((field) {
              if (field.fieldType == 'dropdown') {
                // Поле выпадающего списка
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
                // Поле ввода числа
                return TextField(
                  controller: _dynamicControllers[field.fieldName],
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: field.fieldLabel),
                );
              } else {
                // Текстовое поле
                return TextField(
                  controller: _dynamicControllers[field.fieldName],
                  decoration: InputDecoration(labelText: field.fieldLabel),
                );
              }
            }).toList(),

            const SizedBox(height: 20),

            // ========== Блок добавления фото ==========
            Text(
              'Фотографии:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            // Показываем превью добавленных фото
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: _imagePaths.map((path) {
                return Stack(
                  children: [
                    Image.file(
                      File(path),
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _imagePaths.remove(path);
                          });
                        },
                        child: const CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.red,
                          child: Icon(Icons.close, size: 16, color: Colors.white),
                        ),
                      ),
                    )
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Добавить фото'),
            ),

            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _submitProduct,
              child: const Text('Сохранить Товар'),
            ),
          ],
        ),
      ),
    );
  }
}