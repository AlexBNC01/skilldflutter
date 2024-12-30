import 'dart:io';
import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/product.dart';
import '../models/category.dart';
import 'package:image_picker/image_picker.dart';

class EditProductScreen extends StatefulWidget {
  final int productId;

  const EditProductScreen({required this.productId, Key? key}) : super(key: key);

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final DatabaseService _db = DatabaseService();
  Product? _product;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();

  List<Category> _categories = [];
  Category? _selectedCategory;
  Category? _selectedSubcategory1;
  Category? _selectedSubcategory2;

  List<String> _imagePaths = []; 

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProductAndData();
  }

  Future<void> _loadProductAndData() async {
    final product = await _db.getProductById(widget.productId);
    final cats = await _db.getCategories();
    if (mounted && product != null) {
      nameController.text = product.name;
      priceController.text = product.price.toString();
      quantityController.text = product.quantity.toString();
      _imagePaths = product.imagePathsList;
      _categories = cats;

      _selectedCategory = _findCategoryById(product.categoryId);
      _selectedSubcategory1 = _findCategoryById(product.subcategoryId1);
      _selectedSubcategory2 = _findCategoryById(product.subcategoryId2);

      setState(() {
        _product = product;
        _isLoading = false;
      });
    }
  }

  Category? _findCategoryById(int? id) {
    if (id == null) return null;
    final found = _categories.where((c) => c.id == id);
    if (found.isEmpty) return null;
    return found.first;
  }

  List<Category> _getRootCategories() {
    return _categories.where((c) => c.parentId == null).toList();
  }

  List<Category> _getChildCategories(Category? parent) {
    if (parent == null) return [];
    return _categories.where((c) => c.parentId == parent.id).toList();
  }

  Future<void> _saveChanges() async {
    if (_product == null) return;

    final name = nameController.text.trim();
    final price = double.tryParse(priceController.text.trim());
    final quantity = int.tryParse(quantityController.text.trim());

    if (name.isEmpty || price == null || quantity == null || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заполните все обязательные поля и выберите категорию')),
      );
      return;
    }

    final updatedProduct = Product(
      id: _product!.id,
      name: name,
      price: price,
      quantity: quantity,
      containerId: _product!.containerId,
      imagePaths: _imagePaths.join(','),
      categoryId: _selectedCategory!.id,
      subcategoryId1: _selectedSubcategory1?.id,
      subcategoryId2: _selectedSubcategory2?.id,
      createdAt: _product!.createdAt,
      updatedAt: DateTime.now(),
    );

    await _db.updateProduct(updatedProduct);

    Navigator.pop(context);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imagePaths.add(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final subcategories1 = _getChildCategories(_selectedCategory);
    final subcategories2 = _getChildCategories(_selectedSubcategory1);

    return Scaffold(
      appBar: AppBar(title: const Text('Редактировать товар')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Название товара *'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: 'Цена *'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: quantityController,
              decoration: const InputDecoration(labelText: 'Количество *'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            const Text('Выберите категорию *'),
            DropdownButton<Category?>(
              value: _selectedCategory,
              hint: const Text('Выберите основную категорию'),
              items: _getRootCategories().map((cat) {
                return DropdownMenuItem<Category?>(
                  value: cat,
                  child: Text(cat.name),
                );
              }).toList(),
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
              Text('Выберите подкатегорию для: ${_selectedCategory?.name}'),
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
              Text('Выберите подкатегорию для: ${_selectedSubcategory1?.name}'),
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
            Text('Добавленные фото:', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Wrap(
              children: _imagePaths.map((path) {
                return Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Image.file(
                    File(path),
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
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
              onPressed: _saveChanges,
              child: const Text('Сохранить изменения'),
            ),
          ],
        ),
      ),
    );
  }
}