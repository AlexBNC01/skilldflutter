// lib/screens/categories_management_screen.dart
import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/category.dart';

class CategoriesManagementScreen extends StatefulWidget {
  const CategoriesManagementScreen({Key? key}) : super(key: key);

  @override
  State<CategoriesManagementScreen> createState() => _CategoriesManagementScreenState();
}

class _CategoriesManagementScreenState extends State<CategoriesManagementScreen> {
  final DatabaseService _db = DatabaseService();
  List<Category> _categories = [];
  final TextEditingController _categoryNameController = TextEditingController();
  int? _selectedParentId;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final categories = await _db.getCategories();
    setState(() {
      _categories = categories;
    });
  }

  Future<void> _addCategory() async {
    final categoryName = _categoryNameController.text.trim();

    if (categoryName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, введите название категории.')),
      );
      return;
    }

    final newCategory = Category(
      name: categoryName,
      parentId: _selectedParentId,
    );

    try {
      await _db.insertCategory(newCategory);
      _categoryNameController.clear();
      _selectedParentId = null;
      await _loadCategories();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка добавления категории: $e')),
      );
    }
  }

  Future<void> _deleteCategory(int id) async {
    try {
      await _db.deleteCategory(id);
      await _loadCategories();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка удаления категории: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Управление категориями')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _categoryNameController,
                decoration: const InputDecoration(labelText: 'Название категории'),
              ),
              DropdownButtonFormField<int>(
                value: _selectedParentId,
                hint: const Text('Выберите родительскую категорию (необязательно)'),
                items: _categories.map((category) {
                  return DropdownMenuItem<int>(
                    value: category.id,
                    child: Text(category.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedParentId = value;
                  });
                },
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _addCategory,
                child: const Text('Добавить категорию'),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _categories.isEmpty
                    ? const Center(child: Text('Категории отсутствуют.'))
                    : ListView.builder(
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          return Card(
                            child: ListTile(
                              title: Text(category.name),
                              subtitle: Text('ID: ${category.id}${category.parentId != null ? ', Родитель ID: ${category.parentId}' : ''}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteCategory(category.id!),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ));
  }
}