// lib/screens/add_expense_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import '../services/database_service.dart';
import '../models/product.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../models/container_model.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({Key? key}) : super(key: key);

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  final Map<String, TextEditingController> dynamicControllers = {};

  int? _selectedProductId;
  int? _selectedCategoryId;
  int? _selectedTypeId;
  int? _selectedTechId;
  int? _selectedContainerId;

  List<Product> _products = [];
  List<Category> _categories = [];
  List<Category> _types = [];
  List<Category> _techs = [];
  List<WarehouseContainer> _containers = [];
  List<Map<String, dynamic>> _dynamicFields = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final products = await _databaseService.getProducts();
      final categories = await _databaseService.getCategories();
      final types = await _databaseService.getTypes();
      final techs = await _databaseService.getTechs();
      final containers = await _databaseService.getContainers();
      final dynamicFields = await _databaseService.getDynamicFields('expenses');

      setState(() {
        _products = products;
        _categories = categories;
        _types = types;
        _techs = techs;
        _containers = containers;
        _dynamicFields = dynamicFields;

        for (var field in _dynamicFields) {
          dynamicControllers[field['field_name']] = TextEditingController();
        }
      });
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки данных: $e')),
        );
      }
    }
  }

  // Метод для сканирования штрих-кода
  Future<void> _scanBarcode() async {
    try {
      String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          '#ff6666', 'Отмена', true, ScanMode.BARCODE);
      if (barcodeScanRes != '-1') {
        setState(() {
          _barcodeController.text = barcodeScanRes;
        });

        // Найдите продукт по штрих-коду, только если barcode не пустой
        if (barcodeScanRes.isNotEmpty) {
          Product? product = await _databaseService.getProductByBarcode(barcodeScanRes);
          if (product != null) {
            setState(() {
              _selectedProductId = product.id;
              // Вы можете добавить автоматическое заполнение других полей, если необходимо
            });
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Товар с таким штрих-кодом не найден.')),
              );
            }
          }
        }
      }
    } catch (e) {
      print('Ошибка сканирования: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сканирования: $e')),
        );
      }
    }
  }

  Future<void> _submitExpense() async {
    if (_selectedProductId == null || _quantityController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Пожалуйста, заполните все обязательные поля.')),
        );
      }
      return;
    }

    final selectedProduct = _products.firstWhereOrNull(
      (p) => p.id == _selectedProductId,
    );

    if (selectedProduct == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Выбранный товар не найден.')),
        );
      }
      return;
    }

    final quantity = int.tryParse(_quantityController.text);

    if (quantity == null || quantity <= 0 || quantity > selectedProduct.quantity) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Недостаточно товара для списания.')),
        );
      }
      return;
    }

    final dynamicValues = <String, dynamic>{};
    for (var field in _dynamicFields) {
      dynamicValues[field['field_name']] = dynamicControllers[field['field_name']]?.text.trim();
    }

    final expense = Expense(
      productId: selectedProduct.id!,
      quantity: quantity,
      date: DateTime.now().toIso8601String(),
      dynamicFields: dynamicValues,
      categoryId: _selectedCategoryId,
      typeId: _selectedTypeId,
      techId: _selectedTechId,
      containerId: _selectedContainerId,
      barcode: _barcodeController.text.isNotEmpty ? _barcodeController.text : null,
      // reason: 'Причина расхода', // Если используете поле reason
    );

    try {
      await _databaseService.insertExpense(expense);
      await _databaseService.updateProductQuantity(
        selectedProduct.id!,
        selectedProduct.quantity - quantity,
      );

      // Проверка, что виджет всё ещё смонтирован
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Расход добавлен')),
      );

      Navigator.pop(context, true); // Возвращаем true для обновления списка расходов
    } catch (e) {
      print('Error adding expense: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при добавлении расхода: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Добавить расход')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Поле для сканирования штрих-кода (необязательное)
            TextField(
              controller: _barcodeController,
              decoration: InputDecoration(
                labelText: 'Штрих-код (необязательно)', // Добавлена подсказка
                suffixIcon: IconButton(
                  icon: const Icon(Icons.camera_alt),
                  onPressed: _scanBarcode,
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Выбор товара
            DropdownButtonFormField<int>(
              value: _selectedProductId,
              hint: const Text('Выберите товар'),
              items: _products.map((product) {
                return DropdownMenuItem<int>(
                  value: product.id,
                  child: Text(product.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedProductId = value;
                });
              },
            ),
            const SizedBox(height: 10),
            // Поле количества
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Количество *'),
            ),
            const SizedBox(height: 10),
            // Категория
            const Text('Категория'),
            DropdownButtonFormField<int>(
              value: _selectedCategoryId,
              hint: const Text('Выберите категорию'),
              items: _categories.map((category) {
                return DropdownMenuItem<int>(
                  value: category.id,
                  child: Text(category.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategoryId = value;
                });
              },
            ),
            const SizedBox(height: 10),
            // Тип
            const Text('Тип'),
            DropdownButtonFormField<int>(
              value: _selectedTypeId,
              hint: const Text('Выберите тип'),
              items: _types.map((type) {
                return DropdownMenuItem<int>(
                  value: type.id,
                  child: Text(type.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTypeId = value;
                });
              },
            ),
            const SizedBox(height: 10),
            // Техника
            const Text('Техника'),
            DropdownButtonFormField<int>(
              value: _selectedTechId,
              hint: const Text('Выберите технику'),
              items: _techs.map((tech) {
                return DropdownMenuItem<int>(
                  value: tech.id,
                  child: Text(tech.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTechId = value;
                });
              },
            ),
            const SizedBox(height: 10),
            // Контейнер
            const Text('Контейнер'),
            DropdownButtonFormField<int>(
              value: _selectedContainerId,
              hint: const Text('Выберите контейнер'),
              items: _containers.map((container) {
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
            const SizedBox(height: 10),
            // Динамические поля
            ..._dynamicFields.map((field) {
              return TextField(
                controller: dynamicControllers[field['field_name']],
                decoration: InputDecoration(labelText: field['field_label']),
              );
            }).toList(),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitExpense,
              child: const Text('Сохранить расход'),
            ),
          ],
        ),
      ),
    );
  }
}

// Расширение для firstWhereOrNull
extension IterableExtensions<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    for (E element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}