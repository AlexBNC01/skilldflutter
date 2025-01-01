// lib/screens/products_screen.dart

import 'dart:io'; // Добавлен импорт для работы с File
import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/product.dart';
import '../models/dynamic_field.dart';
import 'package:intl/intl.dart';
import 'product_details_screen.dart'; // Импорт экрана деталей продукта
import 'add_product_screen.dart'; // Импорт экрана добавления продукта

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({Key? key}) : super(key: key);

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final DatabaseService _db = DatabaseService();

  // Список продуктов
  List<Product> _products = [];
  bool _isLoading = true;

  // Поисковый запрос
  String _searchQuery = '';

  // Фильтры
  String? _selectedCategory;
  String? _selectedSupplier;
  DateTime? _startDate;
  DateTime? _endDate;

  // Динамические фильтры
  List<DynamicField> _dynamicFields = [];
  Map<String, dynamic> _dynamicFilters = {};

  // Списки для выпадающих фильтров
  List<String> _categories = [];
  List<String> _suppliers = [];

  // Переменная для управления видимостью фильтров
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _loadFilterOptions();
    _fetchDynamicFields();
  }

  Future<void> _loadFilterOptions() async {
    // Загрузка категорий
    final categories = await _db.getCategories();
    setState(() {
      _categories = categories.map((c) => c.name).toList();
    });

    // Загрузка поставщиков
    final suppliers = await _db.getSuppliers();
    setState(() {
      _suppliers = suppliers;
    });
  }

  Future<void> _fetchDynamicFields() async {
    final fields = await _db.getDynamicFields('products');
    setState(() {
      _dynamicFields = fields;
      // Инициализируем фильтры для динамических полей
      for (var field in _dynamicFields) {
        _dynamicFilters[field.fieldName] = null;
      }
    });
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final products = await _db.getProducts(
        searchQuery: _searchQuery,
        category: _selectedCategory,
        supplier: _selectedSupplier,
        startDate: _startDate,
        endDate: _endDate,
        dynamicFilters: _dynamicFilters,
      );
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching products: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при загрузке продуктов: $e')),
      );
    }
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
      _fetchProducts();
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
      _fetchProducts();
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _fetchProducts();
  }

  void _onCategoryChanged(String? category) {
    setState(() {
      _selectedCategory = category;
    });
    _fetchProducts();
  }

  void _onSupplierChanged(String? supplier) {
    setState(() {
      _selectedSupplier = supplier;
    });
    _fetchProducts();
  }

  void _onDynamicFilterChanged(String fieldName, dynamic value) {
    setState(() {
      _dynamicFilters[fieldName] = value;
    });
    _fetchProducts();
  }

  void _resetFilters() {
    setState(() {
      _searchQuery = '';
      _selectedCategory = null;
      _selectedSupplier = null;
      _startDate = null;
      _endDate = null;
      _dynamicFilters.updateAll((key, value) => null);
    });
    _fetchProducts();
  }

  Widget _buildDynamicFilter(DynamicField field) {
    switch (field.fieldType) {
      case 'text':
        return Expanded(
          child: TextField(
            decoration: InputDecoration(
              labelText: field.fieldLabel,
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            ),
            onChanged: (value) {
              _onDynamicFilterChanged(field.fieldName, value);
            },
          ),
        );
      case 'number':
        return Expanded(
          child: TextField(
            decoration: InputDecoration(
              labelText: field.fieldLabel,
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              final intValue = int.tryParse(value);
              _onDynamicFilterChanged(field.fieldName, intValue);
            },
          ),
        );
      case 'dropdown':
        return Expanded(
          child: DropdownButtonFormField<String>(
            isExpanded: true,
            icon: Icon(Icons.arrow_drop_down, size: 24),
            value: _dynamicFilters[field.fieldName],
            items: [
              DropdownMenuItem(value: null, child: Text('Все')),
              ...?field.options?.map((option) => DropdownMenuItem(
                    value: option,
                    child: Text(option),
                  )),
            ],
            onChanged: (value) {
              _onDynamicFilterChanged(field.fieldName, value);
            },
            decoration: InputDecoration(
              labelText: field.fieldLabel,
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            ),
          ),
        );
      default:
        return SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Список Продуктов'),
      ),
      body: Column(
        children: [
          // Поисковая строка
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                labelText: 'Поиск по названию товара',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),

          // Кнопка для отображения/скрытия фильтров
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showFilters = !_showFilters;
                  });
                },
                icon: Icon(
                  _showFilters ? Icons.expand_less : Icons.expand_more,
                ),
                label: Text(_showFilters ? 'Скрыть фильтры' : 'Показать фильтры'),
              ),
            ),
          ),

          // Фильтры (отображаются только если _showFilters == true)
          if (_showFilters)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                children: [
                  // Первый ряд фильтров: Категория и Поставщик
                  Row(
                    children: [
                      // Фильтр по категории
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          isExpanded: true, // Расширение на доступную ширину
                          icon: Icon(Icons.arrow_drop_down, size: 24), // Уменьшение размера иконки
                          value: _selectedCategory,
                          items: [
                            DropdownMenuItem(value: null, child: Text('Все категории')),
                            ..._categories.map((category) => DropdownMenuItem(
                                  value: category,
                                  child: Text(category),
                                )),
                          ],
                          onChanged: _onCategoryChanged,
                          decoration: InputDecoration(
                            labelText: 'Категория',
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.0),
                      // Фильтр по поставщику
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          icon: Icon(Icons.arrow_drop_down, size: 24),
                          value: _selectedSupplier,
                          items: [
                            DropdownMenuItem(value: null, child: Text('Все поставщики')),
                            ..._suppliers.map((supplier) => DropdownMenuItem(
                                  value: supplier,
                                  child: Text(supplier),
                                )),
                          ],
                          onChanged: _onSupplierChanged,
                          decoration: InputDecoration(
                            labelText: 'Поставщик',
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.0),
                  // Второй ряд фильтров: Даты
                  Row(
                    children: [
                      // Фильтр по начальной дате
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _selectStartDate(context),
                          icon: Icon(Icons.date_range),
                          label: Text(_startDate != null
                              ? DateFormat('yyyy-MM-dd').format(_startDate!)
                              : 'Начальная дата'),
                        ),
                      ),
                      SizedBox(width: 8.0),
                      // Фильтр по конечной дате
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _selectEndDate(context),
                          icon: Icon(Icons.date_range),
                          label: Text(_endDate != null
                              ? DateFormat('yyyy-MM-dd').format(_endDate!)
                              : 'Конечная дата'),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.0),

                  // Динамические фильтры (если есть)
                  if (_dynamicFields.isNotEmpty)
                    Wrap(
                      spacing: 8.0, // Отступ между элементами по горизонтали
                      runSpacing: 8.0, // Отступ между строками
                      children: _dynamicFields.map((field) {
                        return Container(
                          width: 200, // Установите максимальную ширину
                          child: _buildDynamicFilter(field),
                        );
                      }).toList(),
                    ),

                  SizedBox(height: 8.0),

                  // Кнопка сброса фильтров
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _resetFilters,
                      child: Text('Сбросить фильтры'),
                    ),
                  ),
                ],
              ),
            ),

          // Список продуктов
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _products.isEmpty
                    ? Center(child: Text('Нет продуктов.'))
                    : RefreshIndicator(
                        onRefresh: _fetchProducts,
                        child: ListView.builder(
                          itemCount: _products.length,
                          itemBuilder: (context, index) {
                            final product = _products[index];
                            return Card(
                              child: ListTile(
                                leading: product.imagePathsList.isNotEmpty
                                    ? Image.file(
                                        File(product.imagePathsList.first),
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                      )
                                    : Icon(Icons.image, size: 50),
                                title: Text(product.name),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Цена: \$${product.price.toStringAsFixed(2)}'),
                                    Text('Количество: ${product.quantity}'),
                                    Text('Категория: ${product.categoryName ?? 'Неизвестно'}'),
                                    // Добавьте другие детали, включая динамические поля
                                    if (product.dynamicFields != null)
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: product.dynamicFields!.entries.map((entry) {
                                          return Text('${entry.key}: ${entry.value}');
                                        }).toList(),
                                      ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed: () {
                                    // Реализуйте редактирование продукта, если необходимо
                                  },
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProductDetailsScreen(productId: product.id!),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddProductScreen()),
          );
          if (result == true) {
            _fetchProducts(); // Перезагрузить список продуктов после добавления
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}