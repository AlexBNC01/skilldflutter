// lib/pages/add_product_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import '../services/database_service.dart';
import '../models/product.dart';
import '../models/container_model.dart';
import '../models/category.dart';
import 'package:image_picker/image_picker.dart';

// Импорты дополнительных экранов управления
import 'type_management_screen.dart';
import 'tech_management_screen.dart';
import 'manage_categories_page.dart';

class AddProductScreen extends StatefulWidget {
  final int? containerId;

  const AddProductScreen({this.containerId, Key? key}) : super(key: key);

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final DatabaseService _db = DatabaseService();

  // Контроллеры для текстовых полей
  final TextEditingController nameController = TextEditingController(); // Название товара
  final TextEditingController displayNameController = TextEditingController(); // Наименование
  final TextEditingController numberController = TextEditingController(); // Номер
  final TextEditingController priceController = TextEditingController(); // Цена
  final TextEditingController quantityController = TextEditingController(); // Количество
  final TextEditingController barcodeController = TextEditingController(); // Штрих-код
  final Map<String, TextEditingController> dynamicControllers = {}; // Динамические поля

  List<WarehouseContainer> _containers = [];
  int? _selectedContainerId;
  List<Category> _categories = [];
  Category? _selectedCategory;
  Category? _selectedSubcategory1;
  Category? _selectedSubcategory2;
  List<Category> _types = [];
  Category? _selectedType;
  List<Category> _techs = [];
  Category? _selectedTech;
  List<String> _imagePaths = [];
  List<Map<String, dynamic>> _dynamicFields = [];

  @override
  void initState() {
    super.initState();
    _selectedContainerId = widget.containerId;
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final containers = await _db.getContainers();
      final cats = await _db.getCategories();
      final tps = await _db.getTypes();
      final tchs = await _db.getTechs();
      final dynamicFields = await _db.getDynamicFields('products');

      setState(() {
        _containers = containers;
        _categories = cats;
        _types = tps;
        _techs = tchs;
        _dynamicFields = dynamicFields;

        // Инициализация контроллеров для динамических полей
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

  List<Category> _getRootCategories() {
    return _categories.where((c) => c.parentId == null).toList();
  }

  List<Category> _getChildCategories(Category? parent) {
    if (parent == null) return [];
    return _categories.where((c) => c.parentId == parent.id).toList();
  }

  // Метод для сканирования штрих-кода
  Future<void> _scanBarcode() async {
    try {
      String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          '#ff6666', 'Отмена', true, ScanMode.BARCODE);
      if (barcodeScanRes != '-1') {
        setState(() {
          barcodeController.text = barcodeScanRes;
        }); // Закрываем setState корректно

        // Попробуйте найти продукт по штрих-коду
        if (barcodeScanRes.isNotEmpty) {
          Product? existingProduct = await _db.getProductByBarcode(barcodeScanRes);
          if (existingProduct != null) {
            setState(() {
              nameController.text = existingProduct.name;
              displayNameController.text = existingProduct.displayName ?? '';
              numberController.text = existingProduct.number ?? '';
              priceController.text = existingProduct.price.toString();
              quantityController.text = existingProduct.quantity.toString();
              _selectedContainerId = existingProduct.containerId;
              _selectedCategory = _categories.firstWhereOrNull((cat) => cat.id == existingProduct.categoryId);
              _selectedSubcategory1 = _categories.firstWhereOrNull((cat) => cat.id == existingProduct.subcategoryId1);
              _selectedSubcategory2 = _categories.firstWhereOrNull((cat) => cat.id == existingProduct.subcategoryId2);
              _selectedType = _types.firstWhereOrNull((type) => type.id == existingProduct.typeId);
              _selectedTech = _techs.firstWhereOrNull((tech) => tech.id == existingProduct.techId);
              // Заполнение динамических полей
              if (existingProduct.dynamicFields != null) {
                existingProduct.dynamicFields!.forEach((key, value) {
                  if (dynamicControllers.containsKey(key)) {
                    dynamicControllers[key]!.text = value.toString();
                  }
                });
              }
              // Обработка изображений
              if (existingProduct.imagePaths != null && existingProduct.imagePaths!.isNotEmpty) {
                _imagePaths = existingProduct.imagePaths!.split(',');
              }
            });
          } else {
            // Если продукт не найден, уведомите пользователя
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Товар с таким штрих-кодом не найден. Добавьте новый товар.')),
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

  Future<void> _addProduct() async {
    final name = nameController.text.trim();
    final displayName = displayNameController.text.trim();
    final number = numberController.text.trim();
    final price = double.tryParse(priceController.text.trim());
    final quantity = int.tryParse(quantityController.text.trim());
    final barcode = barcodeController.text.trim();

    // Удаляем проверку на barcode.isEmpty
    if (name.isEmpty || price == null || quantity == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Заполните обязательные поля (Название товара, Цена, Количество)')),
        );
      }
      return;
    }

    if (_selectedContainerId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Выберите контейнер')),
        );
      }
      return;
    }

    // Проверьте, существует ли продукт с таким же штрих-кодом, только если barcode is not null
    if (barcode.isNotEmpty) {
      Product? existingProduct = await _db.getProductByBarcode(barcode);
      if (existingProduct != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Продукт с таким штрих-кодом уже существует.')),
          );
        }
        return;
      }
    }

    final dynamicValues = <String, dynamic>{};
    for (var field in _dynamicFields) {
      dynamicValues[field['field_name']] = dynamicControllers[field['field_name']]?.text.trim();
    }

    final newProduct = Product(
      name: name,
      price: price,
      quantity: quantity,
      containerId: _selectedContainerId!,
      imagePaths: _imagePaths.join(','),
      categoryId: _selectedCategory?.id,
      subcategoryId1: _selectedSubcategory1?.id,
      subcategoryId2: _selectedSubcategory2?.id,
      typeId: _selectedType?.id,
      techId: _selectedTech?.id,
      barcode: barcode.isNotEmpty ? barcode : null, // Установка null, если пусто
      dynamicFields: dynamicValues,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await _db.insertProduct(newProduct);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Товар добавлен')),
        );
        Navigator.pop(context, true); // Возвращаем true для обновления списка товаров
      }
    } catch (e) {
      print('Error adding product: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при добавлении товара: $e')),
        );
      }
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final rootCategories = _getRootCategories();
    final subcategories1 = _getChildCategories(_selectedCategory);
    final subcategories2 = _getChildCategories(_selectedSubcategory1);

    return Scaffold(
      appBar: AppBar(title: const Text('Добавить товар')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Поле для сканирования штрих-кода
            TextField(
              controller: barcodeController,
              decoration: InputDecoration(
                labelText: 'Штрих-код', // Убрана звёздочка
                suffixIcon: IconButton(
                  icon: const Icon(Icons.camera_alt),
                  onPressed: _scanBarcode,
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Название товара
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Название товара *'),
            ),
            const SizedBox(height: 10),
            // Наименование
            TextField(
              controller: displayNameController,
              decoration: const InputDecoration(labelText: 'Наименование'),
            ),
            const SizedBox(height: 10),
            // Номер
            TextField(
              controller: numberController,
              decoration: const InputDecoration(labelText: 'Номер'),
            ),
            const SizedBox(height: 10),
            // Цена
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: 'Цена *'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 10),
            // Количество
            TextField(
              controller: quantityController,
              decoration: const InputDecoration(labelText: 'Количество *'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            // Выбор контейнера
            DropdownButtonFormField<int>(
              value: _selectedContainerId,
              items: _containers.map((container) {
                return DropdownMenuItem<int>(
                  value: container.id,
                  child: Text(container.name),
                );
              }).toList(),
              decoration: const InputDecoration(labelText: 'Контейнер *'),
              onChanged: (value) {
                setState(() {
                  _selectedContainerId = value;
                });
              },
            ),
            const SizedBox(height: 10),
            // Категория
            const Text('Категория'),
            DropdownButton<Category?>(
              value: _selectedCategory,
              hint: const Text('Выберите основную категорию (не обязательно)'),
              items: [
                const DropdownMenuItem<Category?>(
                  value: null,
                  child: Text('Не выбрано'),
                ),
                ...rootCategories.map((cat) {
                  return DropdownMenuItem<Category?>(
                    value: cat,
                    child: Text(cat.name),
                  );
                }).toList(),
              ],
              onChanged: (cat) {
                setState(() {
                  _selectedCategory = cat;
                  _selectedSubcategory1 = null;
                  _selectedSubcategory2 = null;
                });
              },
            ),
            if (subcategories1.isNotEmpty) ...[
              const SizedBox(height: 10),
              DropdownButton<Category?>(
                value: _selectedSubcategory1,
                hint: const Text('Выберите подкатегорию'),
                items: subcategories1.map((cat) {
                  return DropdownMenuItem<Category?>(
                    value: cat,
                    child: Text(cat.name),
                  );
                }).toList(),
                onChanged: (cat) {
                  setState(() {
                    _selectedSubcategory1 = cat;
                    _selectedSubcategory2 = null;
                  });
                },
              ),
            ],
            if (subcategories2.isNotEmpty) ...[
              const SizedBox(height: 10),
              DropdownButton<Category?>(
                value: _selectedSubcategory2,
                hint: const Text('Выберите подкатегорию'),
                items: subcategories2.map((cat) {
                  return DropdownMenuItem<Category?>(
                    value: cat,
                    child: Text(cat.name),
                  );
                }).toList(),
                onChanged: (cat) {
                  setState(() {
                    _selectedSubcategory2 = cat;
                  });
                },
              ),
            ],
            const SizedBox(height: 10),
            // Тип
            const Text('Тип'),
            DropdownButton<Category?>(
              value: _selectedType,
              hint: const Text('Выберите тип'),
              items: _types.map((t) {
                return DropdownMenuItem<Category?>(
                  value: t,
                  child: Text(t.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value;
                });
              },
            ),
            const SizedBox(height: 10),
            // Техника
            const Text('Техника'),
            DropdownButton<Category?>(
              value: _selectedTech,
              hint: const Text('Выберите технику'),
              items: _techs.map((tech) {
                return DropdownMenuItem<Category?>(
                  value: tech,
                  child: Text(tech.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTech = value;
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
            const SizedBox(height: 10),
            // Изображения
            Wrap(
              children: _imagePaths.map((path) {
                return Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Stack(
                    children: [
                      Image.file(
                        File(path),
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        right: -10,
                        top: -10,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _imagePaths.remove(path);
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Добавить фото'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addProduct,
              child: const Text('Добавить товар'),
            ),
            const SizedBox(height: 20),
            // Кнопки для перехода на экраны управления типами и техникой
            ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TypeManagementScreen()),
                );
                if (result == true) {
                  _loadData();
                }
              },
              child: const Text('Управление типами'),
            ),
            ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TechManagementScreen()),
                );
                if (result == true) {
                  _loadData();
                }
              },
              child: const Text('Управление техникой'),
            ),
            // Добавьте аналогичные кнопки для категорий и контейнеров, если необходимо
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